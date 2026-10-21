#!/usr/bin/env bash
# safety-check.sh - refuse changes that could harm a TV or a reader's computer.
# Runs automatically on every pull request (.github/workflows/safety-check.yml).
# Run it yourself before opening one:  ./tools/safety-check.sh

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fail=0
problem() { echo "FAIL: $*"; fail=1; }

# 1. Packages that must never appear in a removal list: removing them breaks
#    the Play Store, picture, inputs, remote, settings or the system itself.
protected_exact="
android
com.android.systemui
com.android.settings
com.android.tv.settings
com.android.vending
com.android.shell
com.android.phone
com.android.bluetooth
com.android.inputdevices
com.android.packageinstaller
com.android.permissioncontroller
com.android.tv
com.android.externalstorage
com.google.android.gms
com.google.android.gsf
com.google.android.packageinstaller
com.google.android.webview
com.google.android.ext.services
com.google.android.ext.shared
com.google.android.tv.remote.service
com.google.android.inputmethod.latin
com.google.android.tungsten.setupwraith
com.google.android.apps.tv.launcherx
mitv.service
com.xiaomi.android.tvsetup.partnercustomizer
com.xiaomi.mitv.tvmanager
com.xiaomi.mitv.res
com.xiaomi.android.TV.audio
"
protected_prefixes="com.android.providers. com.droidlogic. com.mediatek. com.realtek. com.amlogic. com.android.server."

while IFS= read -r -d '' list; do
  n=0
  while IFS= read -r raw || [ -n "$raw" ]; do
    n=$((n + 1))
    pkg=$(printf '%s' "$raw" | sed -e 's/#.*//' -e 's/[[:space:]]//g')
    [ -z "$pkg" ] && continue
    if ! printf '%s' "$pkg" | grep -Eq '^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$'; then
      problem "$list:$n: '$raw' is not a package name (only one package per line, # for comments)"
      continue
    fi
    if printf '%s\n' "$protected_exact" | grep -qx "$pkg"; then
      problem "$list:$n: $pkg is a protected system package and must not be removed"
    fi
    for pre in $protected_prefixes; do
      case "$pkg" in "$pre"*) problem "$list:$n: $pkg is a protected system package ($pre*)";; esac
    done
  done < "$list"
done < <(find lists -type f -print0)

# 2. Only plain-text file types. No apps, binaries, archives or executables
#    other than the reviewed scripts.
while IFS= read -r -d '' f; do
  case "$f" in
    ./.git/*) ;;
    *.md|*.txt|*.yml|*.yaml|./LICENSE|./.gitignore|./.github/CODEOWNERS) ;;
    ./scripts/tvtune.sh|./tools/safety-check.sh) ;;
    *) problem "$f: unexpected file type. Only .md, .txt and reviewed scripts are allowed" ;;
  esac
done < <(find . -type f -not -path './.git/*' -print0)

# 3. Dangerous commands anywhere in the repository (scripts, docs, lists).
#    Each pattern would wipe data, brick a device, run code from the internet
#    or escalate privileges.
dangerous='rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r|pm[[:space:]]+clear|pm[[:space:]]+uninstall[[:space:]]+[^-]|wipe[[:space:]]+data|recovery[[:space:]]+--wipe|fastboot|reboot[[:space:]]+(bootloader|recovery|edl)|[[:space:]]dd[[:space:]]+if=|mkfs|(curl|wget)[^|]*\|[[:space:]]*(ba|z)?sh|adb[[:space:]]+(install|push|root|remount|disable-verity|sideload)|[[:space:]]su[[:space:]]+-c|chmod[[:space:]]+777|setenforce|settings[[:space:]]+put[[:space:]]+secure[[:space:]]+install_non_market|base64[[:space:]]+(-d|--decode)|eval[[:space:]]'
# CONTRIBUTING.md and SECURITY.md name these commands to warn readers about them;
# they are covered by CODEOWNERS review instead.
matches=$(grep -RInE "$dangerous" --exclude-dir=.git . \
  | grep -vE '^\./(CONTRIBUTING\.md|SECURITY\.md|tools/safety-check\.sh):' || true)
if [ -n "$matches" ]; then
  problem "dangerous command found:"
  printf '%s\n' "$matches" | sed 's/^/      /'
fi

# 4. Links that download files must point to official sources only.
downloads=$(grep -RhoE 'https?://[^ )>"]+\.(zip|apk|tar|gz|exe|dmg|pkg|sh)\b' --exclude-dir=.git . | sort -u || true)
for url in $downloads; do
  case "$url" in
    https://dl.google.com/android/repository/*) ;;
    *) problem "download link to an unofficial source: $url" ;;
  esac
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "Safety check failed. See CONTRIBUTING.md for the rules."
  exit 1
fi
echo "Safety check passed."
