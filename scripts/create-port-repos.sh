#!/bin/bash
# Turn this scaffold into the three Sailfish packaging git repos inside $ANDROID_ROOT
# (HADK chapter "Packaging Droid HAL" / "Creating Configs").
# Run inside the HABUILD or Platform SDK shell AFTER `repo sync`:
#   source ~/.hadk.env; ./create-port-repos.sh /path/to/sailfishos-beyondx
set -e
SCAFFOLD=$(realpath "${1:?usage: $0 <scaffold dir>}")
: "${ANDROID_ROOT:?source ~/.hadk.env first}"
cd "$ANDROID_ROOT"

# 1) droid-hal  ->  $ANDROID_ROOT/rpm
mkdir -p rpm && cd rpm
[ -d .git ] || git init -q
[ -d dhd ] || git submodule add https://github.com/mer-hybris/droid-hal-device dhd
cp "$SCAFFOLD/droid-hal-samsung-beyondx/droid-hal-beyondx.spec" .
cd "$ANDROID_ROOT"

# 2) droid-config  ->  $ANDROID_ROOT/hybris/droid-configs
mkdir -p hybris/droid-configs && cd hybris/droid-configs
[ -d .git ] || git init -q
[ -d droid-configs-device ] || git submodule add https://github.com/mer-hybris/droid-hal-configs droid-configs-device
cp -r "$SCAFFOLD/droid-config-samsung-beyondx/." .
W=sparse/usr/lib/systemd/system/local-fs.target.wants
mkdir -p $W
for u in dynparts.service system_root.mount system.mount system_ext.mount vendor.mount product.mount odm.mount; do
    ln -sf ../$u $W/$u
done
printf 'tmp/\ndocumentation.list\n' > .gitignore
cd "$ANDROID_ROOT"

# 3) droid-hal-version  ->  $ANDROID_ROOT/hybris/droid-hal-version-beyondx
mkdir -p hybris/droid-hal-version-beyondx && cd hybris/droid-hal-version-beyondx
[ -d .git ] || git init -q
[ -d droid-hal-version ] || git submodule add https://github.com/mer-hybris/droid-hal-version
cp -r "$SCAFFOLD/droid-hal-version-samsung-beyondx/." .
cd "$ANDROID_ROOT"

# 4) Kernel fragment + BoardConfig patch
cp "$SCAFFOLD/kernel/sailfishos.config" kernel/samsung/exynos9820/arch/arm64/configs/
git -C device/samsung/beyondx apply "$SCAFFOLD/kernel/0001-beyondx-sailfishos-boardconfig.patch" -p4 \
  || echo "NOTE: BoardConfig patch did not apply cleanly (already applied?)"

echo "Done. Commit each repo and push to your GitHub, then fill in fixup-mountpoints."
