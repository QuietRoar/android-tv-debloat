# OnePlus TV U1S (Android TV 11)

Brand-specific notes to use **alongside the [main guide](../README.md)**.

| | |
|---|---|
| **Tested model** | OnePlus 65U1S, model `C00` (`./scripts/tvtune.sh check` shows `OnePlus C00`) |
| **Android** | Android TV 11 (updated from 10). Classic Android TV, **not** Google TV |
| **Hardware** | About 1.8 GB RAM, 9 GB usable storage, MediaTek chip |
| **Likely also applies to** | Other OnePlus TV U1S / Y1S / Y1S Pro models on Android TV 10–11. Please [report](../README.md#add-your-device) if yours differs |

OnePlus TV software is built on **HeyTap**, the platform from OnePlus's sister company Oppo, so many system packages are named `com.heytap.*`.

## Results

| | Before | After |
|---|---|---|
| Home screen memory | Google launcher **~182 MB** | Projectivy **~58–74 MB** |
| Apps removed | — | 13 built-in extras + 8 optional + 7 streaming apps |
| OnePlus/HeyTap background services | OLink (~42 MB), push messages, account, diagnostics | Gone |
| Free storage | 4.7 GB | **5.5 GB** |
| Boot time | — | ~40 s |

Cold app launch after the changes: YouTube **0.8–1.4 s**, Netflix **0.9–1.0 s**, Hotstar **1.9–2.6 s**.

## Order of steps

1. Main guide steps 1–4: debugging (turn on **both** USB debugging and **Network debugging**), ADB, connect, **install Projectivy first**.
2. Remove [`lists/oneplus/bloat.txt`](../lists/oneplus/bloat.txt), then anything you don't use from the optional lists below.
3. **Restart the TV** (Settings → Device Preferences → About → Restart). Some OnePlus services are "always-on" and keep running until a restart.
4. To use Projectivy's or Button Mapper's button features, [turn on accessibility over ADB](#accessibility-services-are-hidden).

## App lists

| List | What's in it |
|---|---|
| [`lists/oneplus/bloat.txt`](../lists/oneplus/bloat.txt) | OxygenPlay content hub, User Guide, Weather, Relax, Support app, HeyTap push messages and remote diagnostics, Camera (there's no camera), Google extras |
| [`lists/oneplus/optional.txt`](../lists/oneplus/optional.txt) | **Only if you don't use them:** OnePlus Connect phone app services (OLink, Smart Home, OnePlus account), Bluetooth speaker mode, File browser, OnePlus screensaver, Google Duo/Meet, YouTube Music |
| [`lists/oneplus/india-preloads-optional.txt`](../lists/oneplus/india-preloads-optional.txt) | Preloaded Indian streaming apps (Eros Now, Hungama, JioCinema, JioTV+, JioGames, JioPages, Lionsgate Play, FanCode, Sun NXT, Spotify). **Delete lines for apps you use first** |

```bash
TV=YOUR_TV_IP ./scripts/tvtune.sh debloat lists/oneplus/bloat.txt
```

**Before removing the OnePlus screensaver,** switch to Android's built-in one, or the TV is left without a screensaver:

```bash
adb shell settings put secure screensaver_components com.android.dreams.basic/com.android.dreams.basic.Colors
```

To undo: `adb shell settings put secure screensaver_components com.oneplus.tv.screensaver/com.oneplus.tv.screensaver.service.DaydreamService`

### Keep these on OnePlus

| Package | Why |
|---|---|
| `com.oneplus.tv.remote` | The remote control service |
| `com.heytap.tv.livetv` | Live TV and HDMI inputs |
| `com.heytap.rom.service`, `com.heytap.tvapiservice` | Core OnePlus system services |
| `com.heytap.tv.assistant.oneplus` ("Smart Manager") | Runs as a core system app. **It reinstalls itself on every boot**, so removing it does nothing. Leave it |
| `com.heytap.ars.sink`, `com.heytap.optvmiracastservice` | Casting and screen mirroring |
| `com.oneplus.tv.systemupgrade`, `com.heytap.oprcupgradeservice` | TV and remote firmware updates |
| `com.oneplus.oobe.tv`, `com.oneplus.tv.factory`, `com.heytap.optvfactory`, `mediatek.factorymenu.ui` | Setup and factory tools. They don't run, so they cost nothing |
| `com.mediatek.*`, `com.mstar.*` | Chip drivers, TV tuner and inputs |
| `com.oneplus.skin` | System theme |

## Accessibility services are hidden

**Symptom:** Projectivy or Button Mapper asks you to turn on its accessibility service, but it isn't listed in **Settings → Device Preferences → Accessibility**.

**Cause:** OnePlus's Settings screen only shows Google's own accessibility services. Android itself has no restriction: the services are installed and allowed, just not shown.

**Fix:** turn them on over ADB. This gives the app permission to see what's on screen and read button presses, so **only do this for apps you trust**, and run the commands yourself.

Projectivy only:

```bash
adb shell settings put secure enabled_accessibility_services com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

Projectivy **and** Button Mapper (names separated by `:`):

```bash
adb shell settings put secure enabled_accessibility_services com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService:flar2.homebutton/a.i
adb shell settings put secure accessibility_enabled 1
```

Turn them all off: `adb shell settings put secure enabled_accessibility_services null`

**Check it worked:**

```bash
adb shell dumpsys accessibility | grep -E "Enabled services|Crashed services"
```

**If a service shows up under "Crashed services"** (for example after force-stopping the app), re-running the same command won't fix it, because Android only reacts when the value changes. **Restart the TV** to reconnect it.

## Known issues

- **Network debugging:** turning on USB debugging alone isn't enough. Also turn on **Network debugging** in Developer options, or `adb connect` is refused.
- **"Always-on" services keep running after removal** until you restart the TV.
- **Free memory figures are wrong on this TV.** The kernel reports a nonsense "cached" value (hundreds of GB), so tools that show total free RAM are unreliable. Compare per-app memory instead (`adb shell dumpsys meminfo`).
- **Privacy:** OnePlus's core service logs which apps you open, with the TV's serial number, for analytics. It can't be removed safely. Turn off any "user experience" or diagnostics options in Settings, and Google's **Usage & diagnostics**.
