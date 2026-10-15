#!/bin/bash
# Full rebuild with all fixes: local source patches -> hybris-hal (kernel, hybris-boot,
# patched Android bits) -> copy patched system/vendor binaries into the config overrides
# -> packages (droid-hal, configs, middleware incl. patched libhybris, version) -> image.
set -o pipefail
source "$(dirname "$0")/common.sh"; W=$SCAFFOLD/build
S=$SCAFFOLD
L=$S/logs/full-rebuild.log
exec >> $L 2>&1
echo "=== full rebuild start $(date)"
cd ~/hadk23
cp $S/kernel/sailfishos.config kernel/samsung/exynos9820/arch/arm64/configs/sailfishos.config
bash $W/fixes/apply-local-fixes.sh || { echo "FAILED: local fixes"; exit 1; }
bash $W/02-build-hal.sh || { echo "FAILED: 02-build-hal"; exit 1; }
OUT=~/hadk23/out/target/product/beyondx
O=$S/droid-config-samsung-beyondx/sparse/usr/libexec/droid-hybris/overrides
mkdir -p $O/system/bin $O/vendor/bin
cp $OUT/system/bin/servicemanager $OUT/system/bin/logd $O/system/bin/ || { echo "FAILED: copy system overrides"; exit 1; }
cp $OUT/vendor/bin/vndservicemanager $O/vendor/bin/ || { echo "FAILED: copy vendor overrides"; exit 1; }
strings $O/system/bin/servicemanager | grep -q . && echo "overrides copied: $(ls $O/system/bin $O/vendor/bin | tr '\n' ' ')"
RECREATE_TARGET=0 bash $W/03-package.sh || { echo "FAILED: 03-package"; exit 1; }
echo "=== full rebuild DONE $(date)"
ls -la $S/out/*.zip
