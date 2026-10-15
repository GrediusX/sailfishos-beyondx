# Installing the Sailfish OS community port on the Galaxy S10 5G

This is an **unofficial community port** of Sailfish OS 5.1 to the Samsung Galaxy S10 5G
(**SM-G977B**, codename **beyondx**, Exynos 9820). It runs on top of the LineageOS 23.2
(Android 16) hardware layer. It is not made or supported by Jolla or by LineageOS.

> **Read [KNOWN-ISSUES.md](KNOWN-ISSUES.md) first.** Camera, fingerprint and phone calls do
> not work yet. Installing **erases everything** on the phone.

## What you need

- A Galaxy S10 5G **SM-G977B** (Exynos). Other S10 models (beyond0/1/2) and the Snapdragon
  S10 5G (SM-G977N/U) are **not** supported.
- An **unlocked bootloader**.
- **LineageOS 23.2 installed and booted once.** Sailfish OS reuses its Android 16
  system/vendor partitions and firmware. Follow the official LineageOS install guide for
  `beyondx` if you are coming from Samsung firmware.
- A Windows PC with **Odin** (Linux: Heimdall) and **adb** (Android platform-tools).
- A USB data cable.
- The two release files:
  - `sailfishos-recovery-beyondx-odin.tar` — the Sailfish OS recovery
  - `sailfishos-beyondx-release-5.1.0.11-hybris23-recovery.zip` — the Sailfish OS image

## Step 1 — Flash the Sailfish OS recovery

The Sailfish OS recovery is the official LineageOS recovery with two changes: **Format data**
creates the unencrypted ext4 partition Sailfish OS needs, and the logo says *Sailfish OS*.
See [PATCHES.md](PATCHES.md#recovery).

1. Power off the phone. Hold **Volume Down + Bixby** and plug in the USB cable to enter
   **Download mode**, then press Volume Up to continue.
2. In Odin, put `sailfishos-recovery-beyondx-odin.tar` in the **AP** slot.
   Under *Options*, **untick Auto Reboot**. Click **Start**.
3. When Odin says PASS, hold **Volume Down + Power** for ~7 s to leave Download mode, and
   as soon as the screen goes black switch to **Volume Up + Bixby + Power** until the
   recovery appears. You should see the **SAILFISH OS / RECOVERY** logo.

If the phone boots into LineageOS instead, the stock recovery may have been restored — repeat
step 1.

## Step 2 — Format data

In recovery: **Factory reset → Format data/factory reset** → confirm.

This removes Android's encryption and creates the ext4 partition Sailfish OS is installed on.
**It erases all your data.**

## Step 3 — Install Sailfish OS

1. In recovery: **Apply update → Apply from ADB**.
2. On the PC:
   ```
   adb sideload sailfishos-beyondx-release-5.1.0.11-hybris23-recovery.zip
   ```
3. The recovery will report **"Signature verification failed"** and ask whether to install
   anyway — choose **Yes**. (The package is not signed with LineageOS's keys.)
4. Wait for **Done!**. Unpacking takes a few minutes. The PC may show
   `adb: failed to read command: Success` at the end — that is normal.
5. Choose **Reboot system now**.

The first boot takes **3–5 minutes**, with the Samsung logo and then the Sailfish OS logo.
The setup wizard then guides you through language, Wi-Fi and the Jolla account.

## After installing

- **Developer mode / SSH:** *Settings → Developer tools* lets you set a password and enable
  *Remote connection* (SSH over Wi-Fi).
- **USB networking:** in *Developer mode* the phone appears as a USB network adapter at
  `192.168.2.15`. Currently this only works on the PC's **USB-A** ports — see
  [KNOWN-ISSUES.md](KNOWN-ISSUES.md).
- **Updates:** there are no over-the-air updates for this port. Install a newer release by
  repeating steps 2–3 (this erases data).

## Going back to Android

1. Flash the **official LineageOS recovery** with Odin (AP slot), boot into it.
2. **Factory reset → Format data/factory reset** (this recreates Android's f2fs data partition).
3. **Apply update → Apply from ADB** and sideload the LineageOS zip.

## If something goes wrong

- **Stuck on the Samsung logo after install:** boot into recovery and pull the install log
  *before rebooting again*: `adb pull /tmp/recovery.log` (or `/cache/recovery/last_log` after
  a reboot). Please attach it to an issue.
- **Boot loops after it worked before:** boot into recovery and run
  `adb shell cat /proc/last_kmsg > last_kmsg.txt` right after the failed boot.
