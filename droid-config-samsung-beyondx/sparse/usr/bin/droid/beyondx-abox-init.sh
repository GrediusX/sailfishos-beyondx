#!/bin/sh
# Samsung ABOX (audio DSP) first-enable workaround for Sailfish OS.
# The abox driver registers extra mixer controls during its first *successful*
# runtime resume (firmware downloaded). If that resume is triggered by a mixer
# read (PulseAudio), snd_ctl_add() deadlocks against the reader holding
# controls_rwsem. Early-boot resumes fail because /vendor/firmware isn't mounted
# yet, so: after vendor.mount, cycle the DSP off -> on once, then back to auto.
D=/sys/devices/platform/18c50000.abox
S=$D/power/runtime_status
[ -e $D/power/control ] || exit 0
wait_for() { i=0; while [ $i -lt 100 ]; do [ "$(cat $S)" = "$1" ] && return 0; sleep 0.1; i=$((i+1)); done; return 1; }
for attempt in 1 2 3; do
  echo auto > $D/power/control
  wait_for suspended || echo "abox: did not suspend (status $(cat $S))"
  echo on > $D/power/control
  wait_for active || echo "abox: did not become active (status $(cat $S))"
  sleep 0.5
  if journalctl -k -b -o cat --no-pager 2>/dev/null | grep -q "abox_core_download_firmware: download calliope_sram.bin"; then
    echo "abox: firmware downloaded, controls registered (attempt $attempt)"
    break
  fi
  echo "abox: firmware not downloaded yet (attempt $attempt), retrying"
  sleep 1
done
sleep 1
echo auto > $D/power/control
exit 0
