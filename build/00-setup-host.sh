#!/bin/bash
# Installs host packages for building LineageOS 23.2 / hybris-23.2 inside WSL2 Ubuntu.
set -eo pipefail
source "$(dirname "$0")/common.sh"
exec > >(tee -a "$LOGDIR/00-setup-host.log") 2>&1
status "00-setup-host: start"
. /etc/os-release; echo "Distro: $PRETTY_NAME"; nproc; free -g; df -h $HOME
sudo apt-get update
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
  gnupg gperf imagemagick lib32z1-dev libelf-dev liblz4-tool lz4 libssl-dev libxml2 libxml2-utils lzop \
  pngcrush rsync schedtool squashfs-tools xsltproc zip unzip zlib1g-dev python3 python-is-python3 cpio \
  abootimg android-sdk-libsparse-utils 2>/dev/null || \
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
  gnupg gperf imagemagick lib32z1-dev libelf-dev liblz4-tool lz4 libssl-dev libxml2 libxml2-utils lzop \
  pngcrush rsync schedtool squashfs-tools xsltproc zip unzip zlib1g-dev python3 python-is-python3 cpio
mkdir -p ~/bin
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo && chmod a+x ~/bin/repo
git lfs install
git config --global user.name  >/dev/null || git config --global user.name  "Luca"
git config --global user.email >/dev/null || git config --global user.email "you@example.com"
git config --global color.ui false
ccache -M 50G
cp "$SCAFFOLD/scripts/hadk.env" ~/.hadk.env
sed -i "s#^export ANDROID_ROOT=.*#export ANDROID_ROOT=\"$ANDROID_ROOT\"#" ~/.hadk.env
status "00-setup-host: done"
