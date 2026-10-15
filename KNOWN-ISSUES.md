# Known issues — Sailfish OS 5.1.0.11 on Galaxy S10 5G (beyondx)

Status of the first community build. "Tested" means checked on one SM-G977B by hand;
"untested" means nobody has tried it yet — reports welcome.

## Working

| Area | Notes |
|---|---|
| Boot, UI, setup wizard | Hardware-accelerated graphics (Mali-G76 via libhybris). |
| Display cutout & rounded corners | Status bar and pages keep clear of the camera pill. |
| Touchscreen | |
| Wi-Fi | Saved networks survive reboots. |
| Bluetooth | Pairing, file transfer, audio streaming (tested with a PC and AirPods). |
| Audio | Loudspeaker and headphone playback. |
| Battery & charging | Level/status, USB charging, wireless charging indicator. |
| Reboot / shutdown | |
| SSH over Wi-Fi | Settings → Developer tools → Remote connection. |
| Installation | Via the Sailfish OS recovery + `adb sideload`. |

## Not working

| Area | Status |
|---|---|
| **Camera** | Not available. `droidmedia` (the Android camera/video bridge) does not build yet against the Android 16 QPR2 base. |
| **Hardware video decoding** | Same cause as the camera; videos fall back to software decoding where possible. |
| **Fingerprint reader** | Not working. The ultrasonic Qualcomm sensor needs the Samsung HAL to be bridged to Sailfish's fingerprint daemon. |
| **USB networking on USB-C PC ports** | When the PC port negotiates USB Power Delivery, the phone reports a "fast charger" and usb-moded does not enable Developer mode. **Workaround:** use a USB-A port on the PC. |

## Untested / unknown

- **Calls, SMS, mobile data, 5G** (modem / RIL) — needs a SIM test.
- **GPS**
- **NFC**
- **Sensors** — the orientation sensor service failed to start in early logs; auto-rotation
  may not work. Proximity/light sensors untested.
- **Microphone** (recording, calls)
- **Vibration**
- **MTP file transfer**
- **Battery life** — not tuned (see below).

## Limitations and trade-offs in this build

- **Bluetooth chip stays powered.** Turning Bluetooth off in the UI turns the radio off via
  bluez, but the BCM4375 chip itself stays powered. Cutting its power breaks the Android
  Bluetooth HAL. Small standby cost.
- **Qt Quick uses the basic (single-threaded) render loop** for stability during bring-up
  (`QSG_RENDER_LOOP=basic`). Animations may be slightly less smooth than on official devices.
- **No "deep-buffer" audio output** (power-saving playback path): PulseAudio cannot open it
  with this audio HAL, so music uses the normal output.
- **Encryption:** the data partition is unencrypted ext4. Sailfish OS home encryption has not
  been tested.
- **No OTA updates.** New releases are installed by reflashing (erases data).
- The recovery's "Signature verification failed" prompt during installation is expected.

## Reporting problems

Please open an issue with:
- what you did and what happened,
- `journalctl -b` output (Settings → Developer tools → terminal, or SSH: `devel-su journalctl -b > log.txt`),
- for install or boot problems, the recovery log or `last_kmsg` as described in
  [INSTALL.md](INSTALL.md#if-something-goes-wrong).
