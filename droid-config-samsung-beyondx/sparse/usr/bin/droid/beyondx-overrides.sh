#!/bin/sh
# Bind-mount hybris-patched Android binaries over the stock ones on the
# system/vendor partitions before droid-hal-init starts them.
#   /usr/libexec/droid-hybris/overrides/system/bin/X -> /system/bin/X
#   /usr/libexec/droid-hybris/overrides/vendor/bin/X -> /vendor/bin/X
O=/usr/libexec/droid-hybris/overrides
for part in system vendor; do
    [ -d "$O/$part" ] || continue
    find "$O/$part" -type f | while read -r src; do
        dst="/${src#$O/}"
        if [ -e "$dst" ] && ! grep -q " $dst " /proc/mounts; then
            mount -o bind "$src" "$dst" && echo "beyondx-overrides: $src -> $dst"
        fi
    done
done
exit 0
