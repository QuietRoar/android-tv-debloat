#!/usr/bin/env bash
# tvtune.sh - speed up a slow Android TV over ADB. Every change can be undone.
#
# Usage:  TV=192.168.1.50 ./scripts/tvtune.sh <command> [args]
#
# Commands:
#   check                     Connect and show model, free RAM, storage, home screen
#   apps                      List every app on the TV (to build a list for your model)
#   debloat <list>...         Remove the apps in one or more list files (asks first)
#   restore <list>...         Put back the apps in one or more list files
#   launcher                  Make Projectivy the home screen, turn off Google's launchers
#   launcher-undo             Switch back to Google's launcher
#   compile <package>...      OPTIONAL: fully pre-compile apps (slow, uses storage)
#   compile-undo <package>... Return apps to Android's normal lightweight compile

set -euo pipefail

ADB="${ADB:-adb}"
PORT="${PORT:-5555}"
LAUNCHER_PKG="com.spocky.projengmenu"
LAUNCHER_HOME="com.spocky.projengmenu/.ui.home.MainActivity"
GOOGLE_LAUNCHERS="com.google.android.tvlauncher com.google.android.tvrecommendations com.google.android.leanbacklauncher com.google.android.leanbacklauncher.recommendations"

die() { echo "Error: $*" >&2; exit 1; }

[ -n "${TV:-}" ] || die "set the TV's IP address first, e.g.  TV=192.168.1.50 $0 check"
command -v "$ADB" >/dev/null 2>&1 || die "adb not found. Install Android platform-tools (see README) or set ADB=/path/to/adb"
TARGET="$TV:$PORT"

connect() {
  "$ADB" connect "$TARGET" >/dev/null 2>&1 || true
  local state
  state=$("$ADB" -s "$TARGET" get-state 2>&1 || true)
  case "$state" in
    device) ;;
    *unauthorized*) die "the TV is asking for permission. Select 'Allow' on the TV (tick 'Always allow'), then run again." ;;
    *) die "cannot reach $TARGET. Check the TV is on, on the same Wi-Fi, and USB debugging is enabled." ;;
  esac
}

sh_tv() { "$ADB" -s "$TARGET" shell "$@" </dev/null | tr -d '\r'; }

# Print package names from list files, skipping comments and blank lines.
read_lists() {
  local f
  for f in "$@"; do
    [ -f "$f" ] || die "list file not found: $f"
    sed -e 's/#.*//' -e 's/[[:space:]]//g' "$f" | grep -v '^$' || true
  done
}

is_installed() { sh_tv pm list packages "$1" | grep -qx "package:$1"; }

current_home() {
  sh_tv cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1
}

cmd_check() {
  connect
  echo "Model:    $(sh_tv getprop ro.product.manufacturer) $(sh_tv getprop ro.product.model) (Android $(sh_tv getprop ro.build.version.release))"
  echo "Free RAM: $(sh_tv grep MemAvailable /proc/meminfo | awk '{printf "%d MB", $2/1024}')"
  echo "Storage:  $(sh_tv df -h /data | tail -1 | awk '{print $4 " free (" $5 " used)"}')"
  echo "Home:     $(current_home)"
}

cmd_apps() {
  connect
  echo "# Pre-installed (system) apps on $(sh_tv getprop ro.product.manufacturer) $(sh_tv getprop ro.product.model)"
  sh_tv pm list packages -s | sed 's/^package://' | sort
  echo
  echo "# Apps you or the maker installed from the Play Store"
  sh_tv pm list packages -3 | sed 's/^package://' | sort
}

cmd_debloat() {
  [ $# -gt 0 ] || die "give at least one list file, e.g.  debloat lists/common/google-extras.txt"
  connect
  local home pkgs p found=0
  home=$(current_home)
  pkgs=$(read_lists "$@")
  echo "Apps that will be removed (only the ones installed on this TV):"
  for p in $pkgs; do
    if is_installed "$p"; then
      case "$home" in "$p"/*)
        echo "  SKIP $p - it is your current home screen. Run 'launcher' first." ; continue ;;
      esac
      echo "  $p"
      found=1
    fi
  done
  if [ "$found" = 0 ]; then
    echo "  (none - everything on these lists is already removed or not on this TV)"
    exit 0
  fi
  printf "Continue? [y/N] "; read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "Cancelled. Nothing changed."; exit 0; }
  local log="removed-$(date +%Y%m%d-%H%M%S).txt"
  for p in $pkgs; do
    is_installed "$p" || continue
    case "$home" in "$p"/*) continue ;; esac
    printf "%-48s " "$p"
    sh_tv pm uninstall -k --user 0 "$p"
    echo "$p" >> "$log"
  done
  if [ -f "$log" ]; then
    echo "Saved the list of removed apps to $log (use it with 'restore' to undo)."
  fi
}

cmd_restore() {
  [ $# -gt 0 ] || die "give at least one list file, e.g.  restore lists/common/google-extras.txt"
  connect
  local p
  for p in $(read_lists "$@"); do
    printf "%-48s " "$p"
    sh_tv cmd package install-existing "$p" | head -1
  done
}

cmd_launcher() {
  connect
  if ! is_installed "$LAUNCHER_PKG"; then
    sh_tv am start -a android.intent.action.VIEW -d "market://details?id=$LAUNCHER_PKG" >/dev/null
    die "Projectivy Launcher is not installed. The Play Store page is now open on the TV: select Install, then run this again."
  fi
  sh_tv cmd package set-home-activity "$LAUNCHER_HOME"
  local p
  for p in $GOOGLE_LAUNCHERS; do
    is_installed "$p" && sh_tv pm disable-user --user 0 "$p"
  done
  sh_tv input keyevent KEYCODE_HOME
  echo "Home screen is now: $(current_home)"
}

cmd_launcher_undo() {
  connect
  local p
  for p in $GOOGLE_LAUNCHERS; do sh_tv pm enable "$p" >/dev/null 2>&1 || true; done
  sh_tv cmd package set-home-activity com.google.android.tvlauncher/.MainActivity
  sh_tv input keyevent KEYCODE_HOME
  echo "Home screen is now: $(current_home)"
}

cmd_compile() {
  [ $# -gt 0 ] || die "give package names, e.g.  compile com.google.android.youtube.tv"
  connect
  echo "Compiling one app at a time. The TV will be slow until this finishes - don't use it meanwhile."
  local p t
  for p in "$@"; do
    t=$(date +%s)
    printf "%-40s " "$p"
    printf "%s (%ss)\n" "$(sh_tv cmd package compile -m speed -f "$p" | head -1)" "$(( $(date +%s) - t ))"
  done
  echo "Storage now: $(sh_tv df -h /data | tail -1 | awk '{print $4 " free"}')"
}

cmd_compile_undo() {
  [ $# -gt 0 ] || die "give package names, e.g.  compile-undo com.google.android.youtube.tv"
  connect
  local p
  for p in "$@"; do
    printf "%-40s " "$p"
    sh_tv cmd package compile -m quicken -f "$p" | head -1
  done
  echo "Storage now: $(sh_tv df -h /data | tail -1 | awk '{print $4 " free"}')"
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  check) cmd_check ;;
  apps) cmd_apps ;;
  debloat) cmd_debloat "$@" ;;
  restore) cmd_restore "$@" ;;
  launcher) cmd_launcher ;;
  launcher-undo) cmd_launcher_undo ;;
  compile) cmd_compile "$@" ;;
  compile-undo) cmd_compile_undo "$@" ;;
  *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
