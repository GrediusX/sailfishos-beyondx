#!/bin/bash
# Platform SDK stage: clean target, build droid-hal / configs / middleware / version RPMs, then the image.
set -o pipefail
source "$(dirname "$0")/common.sh"
exec > >(tee -a "$LOGDIR/03-package.log") 2>&1
SDK=/srv/sailfishos/sdks/sfossdk/sdk-chroot
T=$VENDOR-$DEVICE-$PORT_ARCH
in_sdk() { $SDK bash -c "source ~/.hadk.env; export RELEASE=$RELEASE EXTRA_NAME=-hybris23; cd \$ANDROID_ROOT; $*"; }
step() { status "03-package: $1"; shift; "$@" || { status "03-package: FAILED at: $*"; exit 1; }; }

status "03-package: start"
# sync updated scaffold files (patterns etc.) into the droid-configs repo
cp "$SCAFFOLD"/droid-hal-samsung-beyondx/droid-hal-beyondx.spec "$ANDROID_ROOT/rpm/"
cp "$SCAFFOLD"/droid-config-samsung-beyondx/rpm/droid-config-beyondx.spec "$ANDROID_ROOT/hybris/droid-configs/rpm/"
mkdir -p "$ANDROID_ROOT/hybris/droid-configs/kickstart/part" && cp "$SCAFFOLD"/droid-config-samsung-beyondx/kickstart/part/beyondx "$ANDROID_ROOT/hybris/droid-configs/kickstart/part/"
cp -r "$SCAFFOLD"/droid-config-samsung-beyondx/sparse/. "$ANDROID_ROOT/hybris/droid-configs/sparse/"
(cd "$ANDROID_ROOT/hybris/droid-configs/sparse/usr/lib/systemd/system" && mkdir -p local-fs.target.wants && for u in dynparts.service system_root.mount system.mount system_ext.mount vendor.mount product.mount odm.mount; do ln -sf ../$u local-fs.target.wants/$u; done; mkdir -p multi-user.target.wants && ln -sf ../beyondx-abox-init.service multi-user.target.wants/beyondx-abox-init.service && ln -sf ../beyondx-wifi-mac.service multi-user.target.wants/beyondx-wifi-mac.service)
cp "$SCAFFOLD"/droid-config-samsung-beyondx/patterns/*.inc "$ANDROID_ROOT/hybris/droid-configs/patterns/"

if [ "$RECREATE_TARGET" != 0 ] && [ ! -f "$ANDROID_ROOT/.target-recreated" ]; then
  step "removing old target" in_sdk "yes | sdk-assistant target remove $T"
  step "creating clean target" in_sdk "sdk-assistant -y target create $T file://$HOME/sdk_tarballs/Sailfish_OS-latest-Sailfish_SDK_Target-aarch64.tar.7z --tooling SailfishOS-latest || yes | sdk-assistant target create $T file://$HOME/sdk_tarballs/Sailfish_OS-latest-Sailfish_SDK_Target-aarch64.tar.7z --tooling SailfishOS-latest"
  touch "$ANDROID_ROOT/.target-recreated"
fi
# generic config packages in the target clash with droid-config's own files (HADK hot notes)
in_sdk "sb2 -t $T -m sdk-install -R zypper -n rm ofono-configs-binder ofono-configs-mer bluez5-configs-mer 2>&1 | tail -3 || true"
[ "$SKIP_DHD" = 1 ] || step "droid-hal"          in_sdk "rpm/dhd/helpers/build_packages.sh --droid-hal"
step "droid-configs"      in_sdk "rpm/dhd/helpers/build_packages.sh --configs"
[ "$SKIP_MW" = 1 ] || step "middleware"         in_sdk "BUILDMW_QUIET=1 rpm/dhd/helpers/build_packages.sh --mw"
# parse-android-dynparts (not in Jolla repos): needed to map retrofit dynamic partitions
PAD="$ANDROID_ROOT/hybris/mw/parse-android-dynparts"
if [ ! -d "$PAD/.git" ]; then git clone https://github.com/tchebb/parse-android-dynparts "$PAD"; fi
mkdir -p "$PAD/rpm" && cp "$SCAFFOLD/mw/parse-android-dynparts/rpm/parse-android-dynparts.spec" "$PAD/rpm/"
[ "$SKIP_PAD" = 1 ] || step "parse-android-dynparts" in_sdk "rpm/dhd/helpers/build_packages.sh --build=hybris/mw/parse-android-dynparts"
step "droid-hal-version"  in_sdk "rpm/dhd/helpers/build_packages.sh --version"
step "image (mic)"        in_sdk "rpm/dhd/helpers/build_packages.sh --mic"
ls -la "$ANDROID_ROOT"/sfe-* "$ANDROID_ROOT"/SailfishOS* 2>/dev/null
Z=$(ls -t "$ANDROID_ROOT"/*/sailfishos-*.zip 2>/dev/null | head -1)
[ -n "$Z" ] && mkdir -p "$SCAFFOLD/out" && cp "$Z" "$SCAFFOLD/out/" && status "03-package: done -> out/$(basename "$Z")"
# LineageOS recovery's toybox has gzip but no bzip2: ship a .tar.gz-based installer zip as well
if [ -n "$Z" ]; then
  bash "$SCAFFOLD/build/repack-zip-gz.sh" "$Z" "$SCAFFOLD/out/$(basename "${Z%.zip}")-recovery.zip" && status "03-package: recovery-compatible zip -> out/$(basename "${Z%.zip}")-recovery.zip"
fi
