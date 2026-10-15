#!/bin/bash
source "$(dirname "$0")/common.sh"
# One-time: let Claude's bridge reach the phone over Wi-Fi with an SSH key.
# You type the phone password yourself (twice). Usage: bash phone-ssh-setup.sh <phone-wifi-ip>
set -e
IP="$1"; [ -n "$IP" ] || { echo "usage: $0 <phone-wifi-ip>"; exit 1; }
K=~/.ssh/beyondx_ed25519
# a reinstall gives the phone new host keys: forget the old fingerprint for this IP
[ -f ~/.ssh/known_hosts ] && ssh-keygen -f ~/.ssh/known_hosts -R "$IP" >/dev/null 2>&1
[ -f $K ] || ssh-keygen -q -t ed25519 -N "" -C "claude-bridge-beyondx" -f $K
echo ">> 1/2: authorize key for defaultuser (enter the phone password from Developer tools)"
ssh-copy-id -i $K.pub -o StrictHostKeyChecking=accept-new defaultuser@$IP
echo ">> 2/2: authorize key for root (enter the same password again at the devel-su prompt)"
ssh -t -i $K defaultuser@$IP "devel-su sh -c 'mkdir -p /root/.ssh && chmod 700 /root/.ssh && cat /home/defaultuser/.ssh/authorized_keys >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && mkdir -p /etc/ssh/sshd_config.d && echo PermitRootLogin prohibit-password > /etc/ssh/sshd_config.d/50-claude-key.conf && grep -q sshd_config.d /etc/ssh/sshd_config || sed -i \"1i Include /etc/ssh/sshd_config.d/*.conf\" /etc/ssh/sshd_config; systemctl reload sshd.socket 2>/dev/null; systemctl restart sshd 2>/dev/null; true'"
echo "$IP" > $SCAFFOLD/build/phone-ip.txt
ssh -i $K -o BatchMode=yes root@$IP 'echo ROOT-KEY-OK; uname -n' && echo "All set - tell Claude it's done."
