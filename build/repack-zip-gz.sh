#!/bin/bash
# Make the flashable zip installable from LineageOS recovery (toybox: no bzip2/bzcat, but gzip):
# convert the rootfs archive to .tar.gz and use a gzip-based unpack script.
# usage: repack-zip-gz.sh <in.zip> <out.zip>
set -e
IN=$(readlink -f "$1"); OUT=$(readlink -f "$2")
W=$(mktemp -d); cd $W
unzip -q "$IN"
B=$(ls *.tar.bz2); G=${B%.tar.bz2}.tar.gz
echo "converting $B -> $G"
bunzip2 -c "$B" | gzip -6 > "$G"; rm "$B"
sed -i "s/$(echo $B | sed 's/\./\\./g')/$G/g; s#/data/sailfishos-rootfs.tar.bz2#/data/sailfishos-rootfs.tar.gz#g" META-INF/com/google/android/updater-script
cat > updater-unpack.sh <<'XX'
#! /sbin/sh
# Hybris installer unpack step (gzip archive: works with TWRP and LineageOS recovery toybox)
FS_ARC="/data/sailfishos-rootfs.tar.gz"
FS_DST="/data/.stowaways/sailfishos"
rm -rf $FS_DST
mkdir -p $FS_DST
gzip -dc $FS_ARC | tar --numeric-owner -xf - -C $FS_DST
EXIT=$?
[ -e $FS_DST/sbin/init ] || [ -L $FS_DST/sbin/init ] || EXIT=1
rm $FS_ARC
exit $EXIT
XX
chmod 755 updater-unpack.sh
grep -n "tar\.\|unpack" META-INF/com/google/android/updater-script
rm -f "$OUT"
zip -q -0 "$OUT" META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script updater-unpack.sh hybris-boot.img "$G"
ls -la "$OUT"; sha256sum "$OUT"
cd /; rm -rf $W
