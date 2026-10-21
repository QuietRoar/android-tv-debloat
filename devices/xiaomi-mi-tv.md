# Xiaomi Mi TV (Android TV 9, PatchWall)

Brand-specific notes to use **alongside the [main guide](../README.md)**.

| | |
|---|---|
| **Tested model** | Mi TV 4A, `MiTV-AXSO0` |
| **Android** | Android TV 9 (API 28), Xiaomi PatchWall firmware |
| **Hardware** | 1 GB RAM, 4.4 GB usable storage, Amlogic chip |
| **Likely also applies to** | Other Mi TV 4A / 4X / 4C / 4S models on Android TV 9 with PatchWall. Please [report](../README.md#add-your-device) if yours differs |

## Results

| | Before | After |
|---|---|---|
| Free RAM | ~250 MB | **~460 MB** |
| Free storage | 746 MB (84% used) | **1.7 GB (61% used)** |
| Home screen | Google launcher + PatchWall | Projectivy Launcher |
| Mi button | Opened PatchWall | **Opens YouTube** |
| Power on | Jumped to the last HDMI input | **Opens the home screen** |

## Order of steps

1. Main guide steps 1–4: debugging, ADB, connect, **install Projectivy first**.
2. Remove the Xiaomi lists below (main guide step 5).
3. [Stop the TV opening HDMI on power-on](#stop-the-tv-opening-hdmi-on-power-on).
4. [Make the Mi button open YouTube](#make-the-mi-button-open-youtube).
5. Main guide step 7 (TV settings).

## App lists

| List | What's in it |
|---|---|
| [`lists/xiaomi/bloat.txt`](../lists/xiaomi/bloat.txt) | Xiaomi tracking (`com.miui.tv.analytics`, `com.xiaomi.statistic`), PatchWall, Mi TV+, Mi Music/Gallery/Video Player/Media Explorer, Handbook, Legal, screensaver, leftover Camera/Gallery/Print apps |
| [`lists/xiaomi/india-preloads-optional.txt`](../lists/xiaomi/india-preloads-optional.txt) | Preloaded Indian streaming apps: Voot, aha, Sun NXT, ShemarooMe, Hungama, DD, a duplicate SonyLIV, Sensara. **Delete lines for apps you use first** |
| [`lists/common/google-extras.txt`](../lists/common/google-extras.txt) | Google extras (any brand) |

```bash
TV=YOUR_TV_IP ./scripts/tvtune.sh debloat lists/xiaomi/bloat.txt lists/common/google-extras.txt
```

### Keep these on Mi TV

| Package | Why |
|---|---|
| `com.xiaomi.android.tvsetup.partnercustomizer` | Runs the **Netflix and Prime Video** remote buttons (and grabs the Mi button) |
| `com.xiaomi.mitv.tvmanager` | Contains a system service the TV relies on. Hide its icon in Projectivy instead |
| `com.android.tv` (Live TV) | Needed to switch to HDMI inputs. Hide its icon instead |
| `mitv.service`, `com.xiaomi.mitv.res`, `com.xiaomi.android.TV.audio` | Core TV, picture and sound services |
| `com.xiaomi.mitv.smartshare`, `com.xiaomi.wfdsinkhelperservice`, `com.mitv.milinkservice` | Screen mirroring from phones. Remove only if you never use it |
| `com.droidlogic.*` | Amlogic chip drivers, HDMI and inputs |
| `com.xiaomi.mitv.updateservice` | Firmware updates. Removing it frees about 30 MB of RAM but stops updates; your choice |

## Stop the TV opening HDMI on power-on

**Symptom:** every time you switch the TV on, it opens Live TV showing the last-used HDMI input, instead of the home screen.

**Cause:** Xiaomi's system code runs a check on every wake-up. A hidden setting, `set_auto_play`, is set to `1`, which tells it to open Live TV.

**Fix:**

```bash
adb shell settings put global set_auto_play 0
```

Turn the TV off and on to check: it now wakes to the home screen. **Undo:** `adb shell settings put global set_auto_play 1`

<details>
<summary>How this was found</summary>

The TV's log showed `PhoneWindowManager.wakeUp → openNeedActivity → startLiveTV` on every power-on. Disassembling `openNeedActivity` in the TV's `/system/framework/oat/arm/services.vdex` (with `dexdump` from Google's build-tools) showed it checks, in order:

1. The TV was woken by the Netflix button → open Netflix
2. `sys.power_suspend_specialapp` is true → open nothing
3. `Settings.Global set_auto_play == 1` → **open Live TV**
4. `Settings.Global set_patchwall_default == 1` → open PatchWall
5. `Settings.Global tv_on_state == 1` → also open the parental lock

With `set_auto_play` set to `0` (and `set_patchwall_default` already `0`), nothing is launched, so the TV shows the current home screen.
</details>

## Make the Mi button open YouTube

After PatchWall is removed, the Mi button does nothing. Xiaomi routes it through a system "global key" (`KEYCODE_BUTTON_2`, code 189) handled by `partnercustomizer`. That app tries to open PatchWall, which is now gone.

- **Projectivy's button mapping does not work** for the Mi button on this TV.
- **Button Mapper works.** Follow [main guide step 6](../README.md#6-remap-a-remote-button). The Mi button shows up as **`BUTTON_2` (189)**.

**Other buttons on this remote:**

| Button | Key | Default action |
|---|---|---|
| Mi | `BUTTON_2` (189) | PatchWall (remap with Button Mapper) |
| Netflix | `BUTTON_3` | Netflix |
| Prime Video | `BUTTON_4` | Prime Video |
| Assistant | `ASSIST` | Google Assistant |
| Home | `HOME` | Your launcher |

There's no Menu button on this remote.

## Known issues

- **Remote won't wake the TV after `adb shell input keyevent KEYCODE_SLEEP`.** The TV enters deep standby (suspend-to-RAM) within a few seconds and drops off Wi-Fi. Use the physical button under the Mi logo, or unplug for 30 seconds. Avoid sending sleep commands over ADB.
- **"Allow USB debugging?" may pop up again after waking from standby.** Select Allow.
- **App installs and updates make the TV crawl for a few minutes** while Android optimises the app (`dex2oat`, up to about 230 MB of RAM). This is why turning off Play Store auto-updates helps so much on this model.
- **Wi-Fi is 2.4 GHz only** on the tested model. A strong signal still gave 150 Mbps, which is plenty for HD.
