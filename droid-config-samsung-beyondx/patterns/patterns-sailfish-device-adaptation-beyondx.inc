%package -n patterns-sailfish-device-adaptation-beyondx
Summary: Jolla HW Adaptation beyondx
Requires: droid-hal-beyondx
Requires: droid-hal-beyondx-img-boot
# also selects the TWRP-zip (mic fs) image mode in build_packages.sh
Requires: droid-hal-beyondx-kernel-modules
Requires: droid-config-beyondx-sailfish
Requires: droid-config-beyondx-pulseaudio-settings
Requires: droid-config-beyondx-policy-settings
Requires: droid-config-beyondx-preinit-plugin
Requires: droid-config-beyondx-flashing
Requires: droid-config-beyondx-bluez5
Requires: droid-hal-version-beyondx

# Dynamic (retrofit) partitions: maps system/vendor/product/odm/system_ext from super metadata on 'system'
Requires: parse-android-dynparts

# Binder-based HALs (Android 8+ base)
Requires: bluebinder
Requires: ofono-binder-plugin
Requires: dummy_netd
Requires: libgbinder-tools

# Splash screen
Requires: yamuisplash

# Hybris packages
Requires: libhybris-libEGL
Requires: libhybris-libGLESv2
Requires: libhybris-libwayland-egl

# Sensors
Requires: hybris-libsensorfw-qt5

# Vibra
Requires: ngfd-plugin-native-vibrator
Requires: libngf-qt5-qtfeedback

# Needed for /dev/touchscreen symlink
Requires: qt5-plugin-generic-evdev

Requires: pulseaudio-modules-droid
Requires: pulseaudio-modules-droid-hidl

# The -dummy-af is needed for newer devices that run the main
# audiosystem-passthrough in qti mode (e.g. >=Android 9 Qualcomm),
# to fix non-responding Camera app and/or voice during a phone call:
#Requires: audiosystem-passthrough-dummy-af

# for audio recording to work:
Requires: qt5-qtmultimedia-plugin-mediaservice-gstmediacapture

# These need to be per-device due to differing backends (fbdev, eglfs, hwc, ..?)
Requires: qt5-qtwayland-wayland_egl
Requires: qt5-qpa-hwcomposer-plugin
Requires: qtscenegraph-adaptation

# For hybris devices with droidmedia, see HADK pdf for more information
# TODO re-enable once droidmedia builds on LineageOS 23.2 QPR2
#Requires: gstreamer1.0-droid
Obsoletes: gmp-droid

# This is needed for notification LEDs
Requires: mce-plugin-libhybris

# USB mode controller
Requires: usb-moded

# hammerhead, grouper, and maguro use this in scripts, so include for all
Requires: rfkill

# enable device lock and allow to select untrusted software
Requires: sailfish-devicelock-fpd

# Enable home encryption
#Requires: sailfish-device-encryption

# For GPS
Requires: geoclue-provider-hybris

# For FM radio on some QCOM devices
#Requires: qt5-qtmultimedia-plugin-mediaservice-irisradio
#Requires: jolla-mediaplayer-radio

# NFC support
# 1. binder plugin requires Android 8 or a newer base
# 2. pn54x plugin talks directly to pn54x driver
# These plugins are mutually exclusive, you need to pick one:
Requires: nfcd-binder-plugin
#Requires: nfcd-pn54x-plugin

%description -n patterns-sailfish-device-adaptation-beyondx
Pattern with packages for beyondx HW Adaptation

%files -n patterns-sailfish-device-adaptation-beyondx
