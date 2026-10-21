# Contributing

Thanks for helping other people rescue their slow TVs. Contributions are welcome, especially **device pages** and **app lists** for TVs we haven't tested.

People follow this guide without understanding every command, so **safety comes first**. Every change is checked automatically and reviewed by the maintainer before it's merged.

## The rules

1. **Everything must be undoable.** Use only:
   - `pm uninstall -k --user 0`, undone by `cmd package install-existing`
   - `pm disable-user --user 0`, undone by `pm enable`
   - `settings put`, where you show the original value and the undo command

   Write the undo next to every fix.
2. **No root, no wiping, no flashing.** Nothing that erases data, unlocks the bootloader, flashes firmware, or needs `su`.
3. **No downloads from unofficial sources.** Apps come from the Google Play Store. ADB comes from Google's official platform-tools link. No APK files, archives or binaries in the repository.
4. **Only test what you've tested.** Add a package to a list only if you removed it yourself and the TV still worked afterwards: Play Store, HDMI inputs, remote, Wi-Fi, picture and sound.
5. **Never remove protected packages.** The full list is in [`tools/safety-check.sh`](tools/safety-check.sh) (Play Services, Play Store, System UI, Settings, Live TV, Bluetooth, chip-maker drivers, …). If you think one should be removable, open an issue to discuss it first.
6. **No personal information.** Use `YOUR_TV_IP` instead of your real IP, and don't include serial numbers, account names or MAC addresses.

## How to add your TV

1. Fork this repository.
2. Copy [`devices/_template.md`](devices/_template.md) to `devices/<brand>-<model>.md` and fill it in.
3. If you removed brand-specific apps, add them to `lists/<brand>/bloat.txt`, one package per line with a `#` comment saying what it is.
4. Add a row to the **Tested devices** table in the README.
5. Run the safety check:

   ```bash
   ./tools/safety-check.sh
   ```

6. Open a pull request and fill in the checklist.

No time for all that? [Open an issue](../../issues/new) with your TV model and the output of `./scripts/tvtune.sh apps`.

## What gets checked automatically

On every pull request, [`tools/safety-check.sh`](tools/safety-check.sh) runs and **blocks the merge** if:

- a list contains a protected system package or something that isn't a package name
- a file isn't plain text (no `.apk`, `.zip`, binaries or new executables)
- any file contains a dangerous command: wiping data, `pm clear`, `fastboot`, `adb install`/`push`/`root`, `su`, `rm -rf`, piping a download into a shell, and similar
- a download link points anywhere other than Google's official servers

Passing the check doesn't mean a change is accepted. The maintainer still reviews every change by hand.
