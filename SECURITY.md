# Security and integrity

## Use the original

Anyone can copy (fork) this project and change their copy. Forks are not checked or reviewed, and a modified copy could contain harmful commands.

**Only follow this guide from the original repository:**

**https://github.com/vyshakv94/android-tv-debloat**

If someone sends you a version from a different address, a video description or a file attachment, compare it with the original before running anything.

## How this repository is protected

- **Every change is reviewed.** Changes to `main` go through a pull request and need the maintainer's approval ([CODEOWNERS](.github/CODEOWNERS)).
- **Automatic safety check.** [`tools/safety-check.sh`](tools/safety-check.sh) blocks protected system packages, binaries, dangerous commands and unofficial download links ([what it checks](CONTRIBUTING.md#what-gets-checked-automatically)).
- **History can't be rewritten.** Force-pushes and deleting `main` are blocked.
- **Releases are tagged.** Use a [release](../../releases) if you want a version that won't change underneath you.

## Before you run anything

- Every command in this guide starts with `adb shell pm uninstall -k --user 0`, `pm disable-user`, `cmd package …`, `settings put` or `am start`. If you see something else, especially `rm`, `pm clear`, `fastboot`, `su`, `curl … | sh` or `adb install`, **stop**.
- Nothing in this guide asks for a password, account details or payment.
- ADB comes only from `dl.google.com`, and apps only from the Google Play Store.

## Reporting a problem

Found something dangerous or wrong, here or in a copy claiming to be this project? Please report it privately: **Security → Report a vulnerability** on the original repository. Don't open a public issue for it.
