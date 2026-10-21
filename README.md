# Android TV Debloat & Speed-Up

A beginner-friendly guide to making a slow Android TV usable again. You don't need root or any special skills, just a computer on the same Wi-Fi.

- **Remove bloatware** the TV maker pre-installed
- **Replace the heavy home screen** with a light one
- **Remap remote buttons** that stopped working or that you never use
- **Free up memory and storage**, the main cause of lag on 1–2 GB TVs
- **Undo anything**, any time: nothing is permanently deleted, and a factory reset puts the TV back exactly as it came

Works on any Android TV (Sony, Xiaomi, TCL, Philips, Hisense, OnePlus, set-top boxes…). Brand-specific fixes and tested app lists are in [`devices/`](devices).

### Tested devices

| Brand / model | Android | Guide | Result |
|---|---|---|---|
| Xiaomi Mi TV 4A (`MiTV-AXSO0`) | Android TV 9 | [devices/xiaomi-mi-tv.md](devices/xiaomi-mi-tv.md) | Free RAM ~250 → ~460 MB, storage 84% → 61% used |

Got it working on another TV? [Add your device](#add-your-device).

---

## Contents

1. [Turn on debugging on the TV](#1-turn-on-debugging-on-the-tv)
2. [Install ADB on your computer](#2-install-adb-on-your-computer)
3. [Connect to the TV](#3-connect-to-the-tv)
4. [Install a lighter launcher (before removing anything)](#4-install-a-lighter-launcher)
5. [Remove bloatware](#5-remove-bloatware)
6. [Remap a remote button](#6-remap-a-remote-button)
7. [Settings to change on the TV](#7-settings-to-change-on-the-tv)
8. [Optional: pre-compile apps](#8-optional-pre-compile-apps)
9. [Undo everything / troubleshooting](#9-undo-everything--troubleshooting)

Every step has a **copy-paste command** that works on Mac, Windows and Linux. Mac and Linux users can also use the helper script [`scripts/tvtune.sh`](scripts/tvtune.sh), which does the same thing with safety checks.

**Before you start:** check whether your TV has a page in [`devices/`](devices). It lists which apps are safe to remove and any fixes specific to that brand.

---

## 1. Turn on debugging on the TV

1. **Settings → Device Preferences → About** (on some TVs: **Settings → System → About**). Select **Build** 7 times until it says "You are now a developer".
2. Open **Developer options** (now under Device Preferences or System) and turn on **USB debugging** (and **Network debugging** / **ADB over network** if you see it).
3. Note the TV's IP address: **Settings → Network & Internet → (your Wi-Fi)**. It looks like `192.168.1.50`.

## 2. Install ADB on your computer

ADB is Google's official tool for talking to Android devices.

**Mac**

```bash
brew install android-platform-tools
```

No Homebrew? Download [platform-tools for Mac](https://dl.google.com/android/repository/platform-tools-latest-darwin.zip), unzip it, and run commands from inside the `platform-tools` folder as `./adb`.

**Windows**

Download [platform-tools for Windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) and unzip it. Open the folder, type `cmd` in the address bar and press Enter, then run the commands below in that window.

**Linux**

```bash
sudo apt install adb
```

## 3. Connect to the TV

Replace `192.168.1.50` with your TV's IP address:

```bash
adb connect 192.168.1.50:5555
```

The TV shows **"Allow USB debugging?"**. Tick **Always allow from this computer** and select **Allow**. Then check:

```bash
adb devices
```

You should see your TV's IP followed by `device` (`unauthorized` means you need to select Allow on the TV).

**Script shortcut (Mac/Linux):** download this repository, open a terminal in its folder, and run:

```bash
TV=192.168.1.50 ./scripts/tvtune.sh check
```

This shows your TV's model, free memory, free storage and current home screen. Run it again at the end to compare.

## 4. Install a lighter launcher

**Do this first.** If you remove your TV maker's home screen before another one is ready, the TV may have no home screen.

[Projectivy Launcher](https://play.google.com/store/apps/details?id=com.spocky.projengmenu) is free, fast and ad-free.

1. Open its Play Store page on the TV (or search "Projectivy" in the Play Store):

   ```bash
   adb shell am start -a android.intent.action.VIEW -d "market://details?id=com.spocky.projengmenu"
   ```

2. Select **Install** on the TV.
3. Make it the home screen and turn off Google's launchers, which otherwise keep running in the background:

   ```bash
   adb shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity
   adb shell pm disable-user --user 0 com.google.android.tvlauncher
   adb shell pm disable-user --user 0 com.google.android.tvrecommendations
   adb shell pm disable-user --user 0 com.google.android.leanbacklauncher
   adb shell pm disable-user --user 0 com.google.android.leanbacklauncher.recommendations
   ```

4. Press **Home** on the remote. Projectivy should open; finish its welcome steps on the TV.

**Script shortcut:** `TV=192.168.1.50 ./scripts/tvtune.sh launcher`

> "Package … not found" just means that app isn't on your TV. That's fine.
>
> **Google TV models** (the newer interface, Android 10+) use a different launcher (`com.google.android.apps.tv.launcherx`). **Don't disable it.** Instead, turn on Projectivy's own **"Override"** option in its settings.

## 5. Remove bloatware

App lists live in [`lists/`](lists), one app per line. **Open and read a list before using it.**

| List | For | What's in it |
|---|---|---|
| [`lists/common/google-extras.txt`](lists/common/google-extras.txt) | Any Android TV | Discontinued Google apps (Play Music, Play Movies, Play Games), feedback/bug-report services, Chinese/Japanese keyboards |
| [`lists/xiaomi/`](lists/xiaomi) | Xiaomi Mi TV | See [devices/xiaomi-mi-tv.md](devices/xiaomi-mi-tv.md) |

Your brand isn't listed? See [Find bloatware on your own TV](#find-bloatware-on-your-own-tv) below.

To remove one app:

```bash
adb shell pm uninstall -k --user 0 com.google.android.music
```

Repeat this for each line in a list. The app is removed for your user only; Android keeps a hidden copy, which is what makes undo possible.

**Script shortcut** (shows exactly what it will remove and asks before doing anything):

```bash
TV=192.168.1.50 ./scripts/tvtune.sh debloat lists/common/google-extras.txt
```

It saves a `removed-<date>.txt` file you can pass to `restore` to undo.

### Never remove

These keep the TV working. Removing them can break the Play Store, the picture, HDMI inputs or the remote:

- Google Play Services (`com.google.android.gms`) and Play Store (`com.android.vending`)
- System UI and Settings (`com.android.systemui`, `com.android.tv.settings`, `com.android.providers.*`)
- Live TV / inputs (`com.android.tv`): needed for HDMI on many TVs
- Bluetooth (`com.android.bluetooth`) and the remote service (`com.google.android.tv.remote.service`)
- Your TV's chip-maker packages (`com.droidlogic.*`, `com.mediatek.*`, `com.realtek.*`, `com.amlogic.*`)
- Anything your [device page](devices) marks as "keep"

If you just don't want to *see* an app, hide it in Projectivy instead: highlight the icon, hold **OK**, then choose **Hide**.

### Find bloatware on your own TV

```bash
TV=192.168.1.50 ./scripts/tvtune.sh apps
```

Or, without the script:

```bash
adb shell pm list packages -s
```

This lists every pre-installed app. Search the web for any package name you don't recognise before removing it, and remove things **one at a time**, checking that the TV still works after each. If you find a good set for your model, please [share it](#add-your-device).

## 6. Remap a remote button

Many remotes have a brand button (Mi, Sony's "Netflix"-style shortcuts, TCL's app keys…) that becomes useless after removing bloatware. **[Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton)** (free) can make it open any app.

1. Install it on the TV:

   ```bash
   adb shell am start -a android.intent.action.VIEW -d "market://details?id=flar2.homebutton"
   ```

2. Open it and turn on its **accessibility service** when asked (or **Settings → Device Preferences → Accessibility → Button Mapper → On**).
3. Select **Add buttons** (the **+**) and press the button on your remote. It appears with a technical name such as `BUTTON_2`.
4. Select it → turn on **Customize** → **Single tap** → **Applications** → pick an app (for example YouTube).

Test it with the real remote. Simulated presses from ADB (`adb shell input keyevent …`) skip Button Mapper, so they can't be used to test this.

> Projectivy also has button mapping, but on some TVs a maker's system app grabs brand buttons first. Button Mapper catches them earlier, so it works where Projectivy doesn't.

## 7. Settings to change on the TV

These need no computer and make a real difference on 1–2 GB TVs:

- **Turn off Play Store auto-updates:** Play Store → profile → Settings → **Auto-update apps → Don't auto-update apps**. Background updates trigger heavy app optimisation that can freeze a low-end TV for minutes. Update by hand every few weeks instead, when you're not watching.
- **Screensaver:** Settings → Device Preferences → Screen saver → **Turn screen off**. Google's default "Backdrop" screensaver downloads photos and uses memory.
- **Projectivy:** in its settings, turn off video previews and animated wallpaper.
- **Restart weekly:** Power on the remote usually only puts the TV in standby, so memory slowly fills up. Once a week use Settings → Device Preferences → About → **Restart**.
- **When you're done:** turn **USB debugging** off in Developer options. Turn it back on whenever you need ADB again.

## 8. Optional: pre-compile apps

Android normally compiles only the parts of an app you actually use ("speed-profile"). You can force a full compile, which in theory makes apps open faster:

```bash
adb shell cmd package compile -m speed -f com.google.android.youtube.tv
```

**Honest result from a 1 GB test TV: it wasn't worth it.**

| App | Before | After full compile (3 runs) |
|---|---|---|
| YouTube | 1.2 s | 1.1 / 1.3 / 1.5 s |
| Hotstar | 2.4 s | 2.7 / 3.4 / 2.3 s |

- There was no measurable launch improvement; the variation between runs was bigger than any gain.
- It used about **400 MB** of storage for 7 apps.
- While compiling, the TV was nearly unusable. One app took **7 minutes**, and the job used up to 230 MB of RAM.

It may help more on TVs with a faster processor. If you try it, compile **one app at a time**, don't use the TV meanwhile, and keep at least 1 GB of storage free. To undo (`--reset` needs root, so use this instead):

```bash
adb shell cmd package compile -m quicken -f com.google.android.youtube.tv
```

**Script shortcuts:** `./scripts/tvtune.sh compile <package>...` and `./scripts/tvtune.sh compile-undo <package>...`

## 9. Undo everything / troubleshooting

| To undo | Command |
|---|---|
| One removed app | `adb shell cmd package install-existing <package>` |
| A whole list (script) | `TV=... ./scripts/tvtune.sh restore <list-file>` |
| Launcher change | `TV=... ./scripts/tvtune.sh launcher-undo`, or `adb shell pm enable com.google.android.tvlauncher` (and the other three packages from step 4) |
| Button remap | Uninstall Button Mapper |
| Everything | Factory reset: Settings → Device Preferences → Reset |

**`adb connect` fails.** Check that the TV is on (not in standby), on the same Wi-Fi, and that USB debugging is still on. The TV's IP address can change after a router restart.

**The TV is very slow right after a change.** Android may be optimising apps in the background. Give it 5 minutes.

**The Home button shows a "Complete action using" picker.** Pick Projectivy and choose **Always**.

**The remote won't wake the TV.** Don't send sleep commands over ADB (`input keyevent KEYCODE_SLEEP`): some TVs drop into deep standby and ignore the remote. Use the TV's physical power button, or unplug it for 30 seconds.

---

## Add your device

Tried this on another TV? Please share what worked, even if it's only a note.

1. Copy [`devices/_template.md`](devices/_template.md) to `devices/<brand>-<model>.md` and fill it in.
2. If you removed brand-specific apps, add them as `lists/<brand>/bloat.txt` (one package per line, with `#` comments).
3. Add a row to the [Tested devices](#tested-devices) table and open a pull request.

No time for a pull request? Open an issue with your TV model and the output of `./scripts/tvtune.sh apps`.

## Files

```
README.md                    this guide (works for any Android TV)
scripts/tvtune.sh            optional helper for Mac/Linux
lists/common/                app lists safe on any Android TV
lists/<brand>/               app lists for one brand
devices/<brand>-<model>.md   tested notes and brand-specific fixes
devices/_template.md         template for adding a new device
```

## Disclaimer

Use at your own risk. These are standard Android developer commands that don't modify the system partition or need root, and everything can be undone. You're still responsible for your TV. Not affiliated with Google, any TV maker, Projectivy or Button Mapper.

## License

[MIT](LICENSE)
