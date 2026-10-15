#!/bin/bash
# Build kernel, hybris-boot/recovery, droid HAL and droidmedia.
set -o pipefail
source "$(dirname "$0")/common.sh"
exec > >(tee -a "$LOGDIR/02-build-hal.log") 2>&1
status "02-build-hal: start"
cd "$ANDROID_ROOT"
source build/envsetup.sh
breakfast $DEVICE || { status "02-build-hal: FAILED breakfast"; exit 1; }
J=${JOBS:-14}
# droidmedia (camera/video) doesn't build yet against LineageOS 23.2 QPR2 APIs;
# build it separately later with BUILD_DROIDMEDIA=1
TARGETS="hybris-hal"; [ "$BUILD_DROIDMEDIA" = 1 ] && TARGETS="$TARGETS droidmedia"
if make -j$J $TARGETS; then
  OUT=out/target/product/$DEVICE
  ls -la $OUT/hybris-boot.img $OUT/hybris-recovery.img
  hybris/mer-kernel-check/mer_verify_kernel_config $OUT/obj/KERNEL_OBJ/.config | tee "$LOGDIR/mer-kernel-check-build.txt" | grep -c ^ERROR || true
  mkdir -p "$SCAFFOLD/out" && cp $OUT/hybris-boot.img $OUT/hybris-recovery.img "$SCAFFOLD/out/"
  status "02-build-hal: done"
else
  grep -n -m20 -E 'error:|FAILED:' "$LOGDIR/02-build-hal.log" > "$LOGDIR/02-errors.txt"
  status "02-build-hal: FAILED (see 02-errors.txt)"; exit 1
fi
