# droid-hal spec for Samsung Galaxy S10 5G (beyondx, Exynos 9820)
# Base: LineageOS 23.2 / hybris-23.2 (Android 16)
# Macros are documented in rpm/dhd/droid-hal-device.inc

%define device beyondx
%define vendor samsung

%define vendor_pretty Samsung
%define device_pretty Galaxy S10 5G

%define installable_zip 1
%define droid_target_aarch64 1

# Exynos 9820 = Mali-G76: enable libhybris Mali quirks
%define android_config \
#define MALI_QUIRKS 1\
%{nil}

# Retrofit dynamic partitions (super metadata lives on the 'system' partition).
# These are 'logical' entries in fstab and get mounted by our own units in
# droid-config (sparse/usr/lib/systemd/system/*.mount), so skip them here.
%define makefstab_skip_entries / /system /system_ext /vendor /product /odm /metadata

%define straggler_files \
/adb_keys\
/bugreports\
/cache\
/d\
/sdcard\
/efs\
/linkerconfig\
/second_stage_resources\
/postinstall\
/data_mirror\
%{nil}


%include rpm/dhd/droid-hal-device.inc

# IMPORTANT if you want to comment out any macros in your .spec, delete the %
# sign, otherwise they will remain defined!
