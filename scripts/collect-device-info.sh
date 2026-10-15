#!/bin/bash
# Collect information from the phone that the port needs (run with phone in TWRP).
# Output goes to ./device-info/
set -e
mkdir -p device-info && cd device-info
adb wait-for-device
adb shell ls -l /dev/block/platform/13d60000.ufs/by-name/ > by-name.txt
adb shell cat /proc/partitions                          > partitions.txt
adb shell getprop                                       > getprop.txt 2>/dev/null || true
adb shell cat /proc/cmdline                             > cmdline.txt
adb shell uname -a                                      > uname.txt
adb shell ls -l /dev/block/                             > dev-block.txt
echo "Done. Send the device-info folder back to continue the port."
