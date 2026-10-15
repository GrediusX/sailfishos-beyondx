#!/bin/bash
# repo init + sync of mer-hybris hybris-23.2 with the beyondx local manifest, then hybris setup.
set -eo pipefail
source "$(dirname "$0")/common.sh"
exec > >(tee -a "$LOGDIR/01-sync.log") 2>&1
status "01-sync: start"
mkdir -p "$ANDROID_ROOT" && cd "$ANDROID_ROOT"
[ -d .repo ] || repo init -u https://github.com/mer-hybris/android.git -b hybris-23.2 --depth=1 --git-lfs --no-clone-bundle
mkdir -p .repo/local_manifests
echo "local_manifests before:"; ls -la .repo/local_manifests
# keep only our manifest (stray copies cause 'duplicate path' errors)
find .repo/local_manifests -maxdepth 1 -type f ! -name beyondx.xml -print -delete
cp "$SCAFFOLD/local_manifests/beyondx.xml" .repo/local_manifests/
# drop any project the base manifest already provides (avoids 'duplicate path')
python3 - <<'PY'
import re,glob
base=" ".join(open(f).read() for f in glob.glob('.repo/manifests/*.xml')+glob.glob('.repo/manifests/snippets/*.xml'))
p='.repo/local_manifests/beyondx.xml'; out=[]
for l in open(p):
    m=re.search(r'<project path="([^"]+)"',l)
    if m and ('path="%s"'%m.group(1)) in base:
        print("already in base manifest, skipping:",m.group(1)); continue
    out.append(l)
open(p,'w').writelines(out)
PY
echo "Projects also defined elsewhere:"
grep -rn 'samsung_slsi/sepolicy\|exynos9820' .repo/manifests/ .repo/local_manifests/ .repo/manifest.xml 2>/dev/null || true
for i in 1 2 3; do
  status "01-sync: repo sync attempt $i"
  repo sync -c -j16 --no-tags --no-clone-bundle --optimized-fetch --force-sync && break
  [ $i = 3 ] && { status "01-sync: FAILED repo sync"; exit 1; }
done
status "01-sync: repo sync done ($(du -sh . | cut -f1))"
# libhybris
mkdir -p hybris/mw; [ -d external/libhybris ] && mv external/libhybris hybris/mw/libhybris
[ -d hybris/mw/libhybris ] || git clone --recurse-submodules https://github.com/mer-hybris/libhybris.git hybris/mw/libhybris
# hybris patches
status "01-sync: applying hybris-patches"
hybris-patches/apply-patches.sh --mb
# Sailfish packaging repos + kernel fragment + BoardConfig patch
bash "$SCAFFOLD/scripts/create-port-repos.sh" "$SCAFFOLD"
# beyondx block in hybris-boot fixup-mountpoints
F=hybris/hybris-boot/fixup-mountpoints
if ! grep -q '"beyondx")' $F; then
  sed -i "/case \"\$DEVICE\" in/r $SCAFFOLD/hybris-boot/fixup-mountpoints-beyondx.snippet" $F
fi
grep -n -A3 '"beyondx")' $F
bash "$SCAFFOLD/build/fixes/apply-local-fixes.sh"
status "01-sync: done"
