# What this port changes, and why

Everything here is applied automatically by `build/fixes/apply-local-fixes.sh` (source tree
patches) or shipped as files in `droid-config-samsung-beyondx/sparse/` (runtime
configuration). The diffs as applied are in [`patches/`](patches/).

## Kernel (`kernel/samsung/exynos9820`, LineageOS lineage-23.2)

| Change | Why |
|---|---|
| `kernel/sailfishos.config` fragment | Options Sailfish OS needs (mer-kernel-check: 0 errors), Bluetooth RFCOMM/BNEP/HIDP, and the kernel command line (the Samsung bootloader ignores the boot image cmdline). |
| `sound/core/pcm_native.c` | Samsung's audio HAL (a 32-bit service on Android) passes `stop_threshold = (unsigned int)-1` meaning "never stop". In the 64-bit HAL that PulseAudio loads, that value is below the boundary, so starting playback failed with `-EPIPE`. Treated like the 32-bit compat path. |
| `drivers/battery_v2/sec_battery.c` | The `wireless` power supply reported `PRESENT=1` whenever wireless charging is *supported*; mce took that as "charger connected". Now reports a pad actually attached. |
| `drivers/bluetooth/bcm43xx.c` | connman switches Bluetooth off by blocking *all* Bluetooth rfkill switches, which cut power to the chip under the Android Bluetooth HAL (it never recovers). The chip now stays powered once on; on/off is handled by bluez on the vhci adapter. |

## Android side (hybris-23.2 tree)

| Change | Why |
|---|---|
| `frameworks/native/cmds/servicemanager/Access.cpp` | Sailfish OS runs Android services without SELinux; servicemanager aborted on `selinux_status_open`. |
| `system/logging/logd/main.cpp` | logd aborted when it could not set the background scheduling policy; made non-fatal. |
| `system/apex/apexd/apexd.cpp` | Decompressed APEXes were rejected for "wrong SELinux context" (no labels on Sailfish OS), so ART/conscrypt never activated and boot stalled. |
| `hybris/mw/libhybris` (`common/q/linker_tls.cpp`) | `dlclose()` of a library that got a static TLS slot aborted (`unregister_tls_module CHECK`) — crashed PulseAudio and `getprop`. The slot is now kept reserved. |
| `hybris/hybris-boot` | Partition map (`fixup-mountpoints`) for beyondx; installer unpack script. |
| `external/droidmedia` | Build fix for Android 16 (droidmedia itself is not built yet). |

Patched `servicemanager`, `logd` and `vndservicemanager` are bind-mounted over the copies on
the LineageOS system/vendor partitions at boot (`/usr/bin/droid/beyondx-overrides.sh`); an
`odsign` stub lets Android init finish without on-device signing.

## Runtime configuration (`droid-config-samsung-beyondx/sparse/`)

| File | Why |
|---|---|
| `etc/ld.so.preload` + `usr/lib64/libhybris-tls-padding.so` ([source](mw/tls-padding/tls-padding.c)) | Android's graphics libraries write fixed TLS slots that overlap glibc's static TLS — this corrupted Qt's per-thread data ("Cannot make QOpenGLContext current in a different thread"). A preloaded padding library occupies that area. Loaded system-wide because `LD_PRELOAD` is ignored for capability-enabled binaries like lipstick. |
| `usr/bin/droid/beyondx-abox-init.sh` + service | Samsung's ABOX audio DSP driver deadlocks if its first successful power-up is triggered by a mixer read (PulseAudio). The DSP is powered up once at boot, before the user session. |
| `etc/pulse/arm_droid_card_custom.pa` | The audio HAL is API 2.0 (no `create_audio_patch`): use legacy `set_parameters` routing. |
| `usr/bin/droid/beyondx-wifi-mac.sh` + service | bcmdhd shows a random MAC until its firmware loads; connman keyed saved networks by it, so every boot "forgot" Wi-Fi. The firmware is loaded (real MAC) before connman starts. |
| `etc/connman/main.conf.d/50-beyondx.conf` | Ignore bcmdhd's secondary `wlan1` interface (duplicate saved networks). |
| `etc/mce/60-beyondx-battery.ini` | Ignore Samsung helper power supplies that aren't chargers. |
| `usr/share/csd/settings.d/10-hw-settings.ini` | Hardware feature list; without it Sailfish hides the battery indicator, battery settings, etc. |
| `etc/dconf/db/vendor.d/silica-beyondx-cutout.txt` | Camera cutout (from LineageOS `config_mainBuiltInDisplayCutout`) and rounded corners. |
| `usr/lib/systemd/system/bluebinder.service.d/` | Retry the Bluetooth HAL faster when its first start stalls. |
| `usr/lib/systemd/system/*.mount`, `dynparts.service` | Map LineageOS's retrofit dynamic partitions (super metadata on `system`) and mount them. |
| `var/lib/environment/{compositor,nemo}/99-beyondx.conf` | `QSG_RENDER_LOOP=basic`, `QT_OPENGL_NO_BGRA=1`. |

## Recovery

`tools/recovery/make_sailfishos_recovery.py` takes the **official LineageOS 23.2 recovery**
for beyondx and changes two things in its ramdisk — nothing else (kernel, dtbo and header are
untouched):

1. `/data` in `recovery.fstab`: `f2fs` with file-based + metadata encryption →
   plain `ext4` without encryption, so **Format data** prepares the partition Sailfish OS uses.
2. The logo images (`make_recovery_logo.py`).

The flashable zip's rootfs archive is repacked as `.tar.gz` (`build/repack-zip-gz.sh`) because
the LineageOS recovery's toybox has gzip but no bzip2.
