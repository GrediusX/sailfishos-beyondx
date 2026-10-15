#!/bin/sh
# Make wlan0 show its real MAC before connman starts.
# bcmdhd registers wlan0 with a random 00:90:4c:xx address and only switches to
# the real (OTP/EFS) MAC once its firmware is loaded on the first "up". connman
# keys saved networks by the MAC it sees at startup, so without this every boot
# "forgets" Wi-Fi. The driver refuses address changes before firmware load, so
# bring the interface up once (loads firmware), wait for the real MAC, then down.
log() { echo "wifi-mac: $*"; }
i=0; while [ ! -e /sys/class/net/wlan0 ] && [ $i -lt 100 ]; do sleep 0.1; i=$((i+1)); done
[ -e /sys/class/net/wlan0 ] || { log "wlan0 not found"; exit 0; }
israndom() { case "$(cat /sys/class/net/wlan0/address)" in 00:90:4c:*|02:90:4c:*) return 0;; esac; return 1; }
if israndom; then
  log "boot address $(cat /sys/class/net/wlan0/address), loading firmware"
  ip link set wlan0 up
  i=0; while israndom && [ $i -lt 200 ]; do sleep 0.1; i=$((i+1)); done
  ip link set wlan0 down
fi
if israndom; then
  F=/mnt/vendor/efs/wifi/.mac.info
  [ -r $F ] && ip link set wlan0 address "$(tr -d ' \n\r' < $F)"
fi
log "wlan0 address now $(cat /sys/class/net/wlan0/address)"
exit 0
