# droid-config spec for Samsung Galaxy S10 5G (beyondx)
# Macros documented in droid-configs-device/droid-configs.inc

%define device beyondx
%define vendor samsung

%define vendor_pretty Samsung
%define device_pretty Galaxy S10 5G

# Community HW adaptations need this
%define community_adaptation 1

# 6.7" 1440x3040 (~502 ppi). Jolla 1 = 245 ppi = 1.0 -> ~2.0
%define pixel_ratio 2.0

# Android 16 base (hybris-23.2) -> uses droid-configs-device/sparse-16
%define android_version_major 16

# droid-configs sparse-16 ships /etc/ofono/binder.conf -> replace the generic config packages
Provides: ofono-configs
Obsoletes: ofono-configs-mer
Obsoletes: ofono-configs-binder

# Android binaries/scripts bind-mounted over /system,/vendor: no RPM dependency scanning
%global __requires_exclude_from ^/usr/libexec/droid-hybris/overrides/.*$
%global __provides_exclude_from ^/usr/libexec/droid-hybris/overrides/.*$
%include droid-configs-device/droid-configs.inc
%include patterns/patterns-sailfish-device-adaptation-beyondx.inc
%include patterns/patterns-sailfish-device-configuration-beyondx.inc
