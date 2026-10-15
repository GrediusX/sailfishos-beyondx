# Sailfish OS community port — Samsung Galaxy S10 5G (beyondx)

I always wanted to try SailfishOS but never had a compatible device. With the help of Claude and my beginner skills. I decided to take upon this journey. For fun and curiosity but above those, to learn and improve my knowledge on building ROMs. It's something that I always dreamed and tried many years before but failed to accomplish. With Claude by my side showing me and teaching me what to do when stuff were going south really helped me. And I wanted to share the results here. If you have an S10 5G lying around and some spare time, might try this fun project to explore other OS beside Android! :D

Unofficial community port of **Sailfish OS 5.1.0.11** to the Samsung Galaxy S10 5G
(**SM-G977B**, Exynos 9820), built on the **LineageOS 23.2 / Android 16** hardware adaptation
(mer-hybris `hybris-23.2`).

- **Install:** [INSTALL.md](INSTALL.md)
- **What works / what doesn't:** [KNOWN-ISSUES.md](KNOWN-ISSUES.md)
- **Every change and why:** [PATCHES.md](PATCHES.md) · raw diffs in [`patches/`](patches/)

> Sailfish OS is a trademark of Jolla Ltd. This is an independent community project, not
> affiliated with or endorsed by Jolla or LineageOS. Flashing it erases your data; use at your
> own risk.

## Status

Boots to the UI with GPU acceleration; Wi-Fi, Bluetooth (incl. audio), audio, battery and
charging (incl. wireless) work. Camera, fingerprint and telephony are not working or untested
yet — see [KNOWN-ISSUES.md](KNOWN-ISSUES.md).

## Repository layout

| Path | Contents |
|---|---|
| `local_manifests/beyondx.xml` | repo manifest: LineageOS device/kernel trees and vendor blobs |
| `kernel/` | Sailfish OS kernel config fragment + BoardConfig patch, mer-kernel-check reports |
| `droid-hal-samsung-beyondx/` | droid-hal packaging (`$ANDROID_ROOT/rpm`) |
| `droid-config-samsung-beyondx/` | device configuration, patterns, kickstart, sparse files (`hybris/droid-configs`) |
| `droid-hal-version-samsung-beyondx/` | version package |
| `hybris-boot/` | partition map snippet for `fixup-mountpoints` |
| `mw/` | extra middleware: `parse-android-dynparts` spec, TLS padding library source |
| `patches/` | source patches as applied to the Android/kernel tree |
| `build/` | build scripts (WSL2/Ubuntu + Sailfish Platform SDK) and `fixes/apply-local-fixes.sh` |
| `tools/recovery/` | builds the Sailfish OS recovery from the official LineageOS recovery |

## Building

Requirements: Linux x86_64 (Ubuntu 22.04 or WSL2), ~300 GB free disk, 32 GB RAM (+ swap), the
Sailfish OS Platform SDK with an `aarch64` target for 5.1.0.11. Follow the HADK for the SDK
setup, then:

```bash
export SCAFFOLD=/path/to/this/repo
bash build/00-setup-host.sh     # host packages, repo, ccache
bash build/01-sync.sh           # repo init hybris-23.2 + local manifest, sync, apply patches
bash build/full-rebuild.sh      # hybris-hal, droid-hal, configs, middleware, image (+ recovery zip)
```

Outputs land in `out/`: the normal Sailfish OS zip and a `-recovery.zip` installable from the
LineageOS-based recovery. Build the recovery with:

```bash
python3 tools/recovery/make_sailfishos_recovery.py lineage-23.2-recovery-beyondx.img \
        recovery.img --logo tools/recovery/logo_image_xxxhdpi.png
tar -H ustar -cf sailfishos-recovery-beyondx-odin.tar recovery.img
```

`mw/tls-padding/libhybris-tls-padding.so` is built from `tls-padding.c` with
`clang --target=aarch64-linux-gnu -O2 -fPIC -shared -nostdlib -fuse-ld=lld -Wl,-soname,libhybris-tls-padding.so`.

## Credits

- [mer-hybris](https://github.com/mer-hybris) / Jolla — HADK, libhybris, droid-hal tooling
- [LineageOS](https://lineageos.org) — device tree, kernel and recovery for beyondx
- [TheMuppets](https://github.com/TheMuppets) — vendor blobs
- [libhybris](https://github.com/libhybris/libhybris), [parse-android-dynparts](https://github.com/tchebb/parse-android-dynparts)

## Licences

Kernel patches: GPL-2.0 (as the kernel). Android/libhybris patches: under the licence of the
file they modify (Apache-2.0 / LGPL). Port configuration and scripts in this repository:
BSD-3-Clause, see [LICENSE](LICENSE).
