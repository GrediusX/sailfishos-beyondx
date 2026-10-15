#!/bin/bash
# Idempotent source fixes applied on top of the synced tree. Run from $ANDROID_ROOT.
set -e
# 1) droidmedia vs Android 16 QPR2 (BP4A): Camera::getCameraInfo/connect take
#    content::res::CameraCompatibilityInfo instead of bool overrideToPortrait.
python3 - <<'PY'
import re
p='external/droidmedia/droidmediacamera.cpp'
s=open(p).read()
if 'HYBRIS_A16_COMPAT' not in s:
    s=s.replace('''                                       false/*overrideToPortrait*/,''','''#if ANDROID_MAJOR >= 16 /* HYBRIS_A16_COMPAT */
                                       android::content::res::CameraCompatibilityInfo(),
#else
                                       false/*overrideToPortrait*/,
#endif''',1)
    old='''					     , __ANDROID_API_FUTURE__
					     , false
					     , false'''
    new='''					     , __ANDROID_API_FUTURE__
#if ANDROID_MAJOR >= 16 /* HYBRIS_A16_COMPAT */
					     , android::content::res::CameraCompatibilityInfo()
#else
					     , false
#endif
					     , false'''
    assert old in s, "droidmedia connect() pattern not found"
    s=s.replace(old,new,1)
    open(p,'w').write(s)
    print("patched", p)
else:
    print("already patched", p)
PY

# 2) dhd builds simg2img/img2simg with -std=gnu++14; Android 16 libbase needs C++17.
#    dhd picks up per-device overrides from rpm/helpers/*.mk
mkdir -p rpm/helpers
for t in simg2img img2simg; do
  sed 's/-std=gnu++14/-std=gnu++17/' rpm/dhd/helpers/$t.mk > rpm/helpers/$t.mk
done
grep -H 'std=' rpm/helpers/*.mk

# 3) servicemanager / vndservicemanager: Sailfish runs without SELinux (no selinuxfs),
#    Android 16 CHECKs selinux_status_open()/getcon() and aborts -> droid-hal-init powers off.
python3 - <<'PY'
p='frameworks/native/cmds/servicemanager/Access.cpp'
s=open(p).read()
old='''    CHECK(selinux_status_open(true /*fallback*/) >= 0);

    CHECK(getcon(&mThisProcessContext) == 0);'''
new='''    // HYBRIS: Sailfish OS runs Android services without SELinux
    if (is_selinux_enabled() > 0) {
        CHECK(selinux_status_open(true /*fallback*/) >= 0);
        CHECK(getcon(&mThisProcessContext) == 0);
    } else {
        mThisProcessContext = nullptr;
    }'''
if 'HYBRIS: Sailfish OS runs Android services without SELinux' not in s:
    assert old in s, "servicemanager Access.cpp pattern not found"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY
# 4) logd: cgroups/task profiles are owned by systemd on Sailfish -> don't abort
python3 - <<'PY'
p='system/logging/logd/main.cpp'
s=open(p).read()
old='''        PLOG(FATAL) << "failed to set background scheduling policy";'''
new='''        PLOG(WARNING) << "failed to set background scheduling policy"; // HYBRIS: non-fatal'''
if 'HYBRIS: non-fatal' not in s:
    assert old in s, "logd main.cpp pattern not found"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 5) apexd: decompressed CAPEXes are rejected as "wrong SELinux context unlabeled" when
#    SELinux is off -> ART/sdkext not activated -> odsign fails -> init stalls in post-fs-data.
python3 - <<'PY'
p='system/apex/apexd/apexd.cpp'
s=open(p).read()
old='''  if (!StartsWith(*ctx, gConfig->active_apex_selinux_ctx)) {
    return Error() << apex_path << " has wrong SELinux context " << *ctx;'''
new='''  // HYBRIS: no SELinux labels on Sailfish OS (is_selinux_enabled() is unreliable here)
  if (getenv("HYBRIS_APEX_SELINUX_CHECK") != nullptr && !StartsWith(*ctx, gConfig->active_apex_selinux_ctx)) {
    return Error() << apex_path << " has wrong SELinux context " << *ctx;'''
if 'HYBRIS: no SELinux labels on Sailfish OS' not in s:
    assert old in s, "apexd pattern not found"
    s=s.replace(old,new)
    if '#include <selinux/selinux.h>' not in s:
        s=s.replace('#include <selinux/android.h>','#include <selinux/android.h>\n#include <selinux/selinux.h>',1)
    open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 6) libhybris q linker: dlclose() of a library that got a *static* TLS slot aborts with
#    "unregister_tls_module CHECK 'mod.static_offset == SIZE_MAX' failed" (pulseaudio, getprop).
#    Static TLS space can't be reclaimed -> keep the slot reserved instead of aborting.
python3 - <<'PY'
p='hybris/mw/libhybris/libhybris/hybris/common/q/linker_tls.cpp'
s=open(p).read()
old='''  CHECK(mod.static_offset == SIZE_MAX);
  CHECK(mod.soinfo_ptr == si);
  mod = {};
  si_tls->module_id = kTlsUninitializedModuleId;'''
new='''  // HYBRIS: libraries dlopen()ed via libhybris may get a static TLS slot; that space
  // can't be reclaimed, so keep the slot reserved instead of aborting on dlclose().
  if (mod.soinfo_ptr != si) {
    // mismatch: leave the module table entry alone
  } else if (mod.static_offset != SIZE_MAX) {
    mod.soinfo_ptr = reinterpret_cast<void*>(1);
  } else {
    mod = {};
  }
  si_tls->module_id = kTlsUninitializedModuleId;'''
if 'HYBRIS: libraries dlopen()ed via libhybris may get a static TLS slot' not in s:
    assert old in s, "linker_tls.cpp pattern not found"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 7) kernel sec_battery: the "wireless" power_supply reports PRESENT=1 whenever the
#    device supports wireless charging, so Sailfish's mce thinks a wireless charger
#    is always attached. Report PRESENT like ONLINE (pad actually attached).
python3 - <<'PY'
p='kernel/samsung/exynos9820/drivers/battery_v2/sec_battery.c'
s=open(p).read()
old='''	case POWER_SUPPLY_PROP_PRESENT:
		val->intval = (battery->pdata->wireless_charger_name) ?
			1 : 0;
		break;'''
new='''	case POWER_SUPPLY_PROP_PRESENT:
		/* HYBRIS: report an attached pad, not mere wireless support (mce) */
		val->intval = (battery->pdata->wireless_charger_name &&
			is_wireless_type(battery->cable_type)) ? 1 : 0;
		break;'''
if 'HYBRIS: report an attached pad' not in s:
    assert s.count(old)==1, "sec_battery wireless PRESENT pattern not found/unique"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 8) kernel ALSA: Samsung's audio HAL (normally a 32-bit service on Android) passes
#    stop_threshold = (unsigned int)-1 meaning "never stop". Under Sailfish OS the 64-bit
#    HAL is loaded into pulseaudio; there 0xffffffff is below the 64-bit boundary, so
#    starting playback before writing data fails with -EPIPE. Treat it like the boundary.
python3 - <<'PY'
p='kernel/samsung/exynos9820/sound/core/pcm_native.c'
s=open(p).read()
old='''	err = 0;
	snd_pcm_stream_lock_irq(substream);
	runtime->tstamp_mode = params->tstamp_mode;'''
new='''	/* HYBRIS: 32-bit-era HALs use (unsigned int)-1 for "never stop"; on 64-bit that
	 * is below the boundary -> -EPIPE on start. Treat it like the 32-bit compat path. */
	if (params->stop_threshold == UINT_MAX)
		params->stop_threshold = runtime->boundary;
	err = 0;
	snd_pcm_stream_lock_irq(substream);
	runtime->tstamp_mode = params->tstamp_mode;'''
if 'HYBRIS: 32-bit-era HALs use' not in s:
    assert s.count(old)==1, "pcm_native sw_params pattern not found/unique"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 9) kernel bcm43xx BT rfkill: connman switches Bluetooth off with RFKILL_OP_CHANGE_ALL,
#    which also cuts power to the BCM4375 under the Android BT HAL (it never recovers,
#    the toggle just spins). Keep the chip powered; on/off is handled via bluebinder's
#    vhci hci0 / bluez instead.
python3 - <<'PY'
p='kernel/samsung/exynos9820/drivers/bluetooth/bcm43xx.c'
s=open(p).read()
old='''	} else {
		pr_info("[BT] Bluetooth Power Off.\\n");
'''
new='''	} else {
		/* HYBRIS: keep the chip powered under the Android BT HAL (bluebinder);
		 * connman blocks all bluetooth rfkills when Bluetooth is switched off. */
		if (gpio_get_value(bt_gpio.bt_en)) {
			pr_info("[BT] Bluetooth Power Off request ignored (hybris)\\n");
			return 0;
		}
		pr_info("[BT] Bluetooth Power Off.\\n");
'''
if 'Power Off request ignored (hybris)' not in s:
    assert s.count(old)==1, "bcm43xx power-off pattern not found/unique"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY

# 10) hybris-boot updater-unpack.sh: LineageOS recovery's toybox tar has no bzip2 helper
#     ("tar: exec bzip2: No such file or directory") -> fall back to toybox bzcat.
python3 - <<'PY'
p='hybris/hybris-boot/updater-unpack.sh'
s=open(p).read()
old='tar --numeric-owner -xvjf $FS_ARC -C $FS_DST\nEXIT=$?'
new='''# HYBRIS: LineageOS recovery has no bzip2 binary; toybox provides bzcat
if command -v bzip2 >/dev/null 2>&1; then
    tar --numeric-owner -xvjf $FS_ARC -C $FS_DST
    EXIT=$?
else
    toybox bzcat $FS_ARC | tar --numeric-owner -xf - -C $FS_DST
    EXIT=$?
    [ -x $FS_DST/sbin/init ] || [ -L $FS_DST/sbin/init ] || EXIT=1
fi'''
if 'HYBRIS: LineageOS recovery has no bzip2' not in s:
    assert old in s, "updater-unpack pattern not found"
    s=s.replace(old,new); open(p,'w').write(s); print("patched",p)
else: print("already patched",p)
PY
