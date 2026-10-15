#!/bin/bash
# Generate the beyondx block for hybris/hybris-boot/fixup-mountpoints.
# Usage: boot the phone into TWRP (or LineageOS with adb root), connect USB, run:
#   ./gen-fixup-mountpoints.sh > beyondx-fixup.txt
# Then paste the output into hybris/hybris-boot/fixup-mountpoints right after
#   case "$DEVICE" in
set -e
BYNAME=/dev/block/platform/13d60000.ufs/by-name
adb wait-for-device
echo '    "beyondx")'
echo '        sed -i \'
adb shell "ls -l $BYNAME/" | tr -d '\r' | awk '/->/ {
    name=$(NF-2); target=$NF; sub(".*/", "", target);
    printf "            -e '\''s block/platform/13d60000.ufs/by-name/%s %s '\'' \\\n", name, target;
    printf "            -e '\''s block/by-name/%s %s '\'' \\\n", name, target;
}'
echo '            "$@"'
echo '        ;;'
