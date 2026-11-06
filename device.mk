#
# SPDX-FileCopyrightText: MIRACLO
# SPDX-License-Identifier: Apache-2.0
#

# POCO F5 (marble), Qualcomm SM7475 (taro family)
#
# MIRACLO builds system, system_ext and product. The device runs Xiaomi's
# stock vendor, odm, vendor_dlkm, vendor_boot and dtbo images and Google's GKI
# boot image unchanged; fetch-stock.sh downloads them from Xiaomi before the
# first build, together with the Qualcomm system apps listed in Android.bp.

# 64-bit system with 32-bit support (the stock vendor ships 32-bit libraries)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Virtual A/B, as on stock
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# Internal storage is emulated on /data
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Kernel: Google's GKI kernel (android12-5.10) from the stock firmware.
# Xiaomi's drivers load as modules from the stock vendor_boot and vendor_dlkm.
PRODUCT_COPY_FILES += device/xiaomi/marble/stock/kernel:kernel

# The device launched with Android 13
PRODUCT_SHIPPING_API_LEVEL := 33

# The stock vendor is frozen at API 31/32 and links against VNDK 32
PRODUCT_EXTRA_VNDK_VERSIONS := 32

# Dynamic partitions (layout in BoardConfig.mk). Only super_empty.img is made
# by a normal build, for flashing with fastboot.
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

# vendor_boot: the stock image is shipped as a firmware image (see Android.mk),
# so the build does not make its own.
PRODUCT_BUILD_VENDOR_BOOT_IMAGE := false

# Screen: 1080 x 2400
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
PRODUCT_CHARACTERISTICS := nosdcard

# A/B updates
PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Qualcomm telephony libraries used by SystemUI, Settings and Phone
PRODUCT_PACKAGES += \
    extphonelib \
    extphonelib.xml \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-hidl-wrapper \
    qti_telephony_hidl_wrapper.xml \
    qti-telephony-utils \
    qti_telephony_utils.xml

# Call audio: Qualcomm's telephony service tells the audio HAL when a call is
# active (through the vendor's vendor.qti.hardware.radio.am HAL).
PRODUCT_PACKAGES += \
    QtiTelephonyService \
    vendor.qti.hardware.radio.am@1.0

# 5G (NSA and SA) and VoLTE / VoNR: Qualcomm's system telephony apps, the IMS
# service and the overlays that point the framework at it (see Android.bp).
PRODUCT_PACKAGES += \
    QtiTelephony \
    QtiIms \
    MarbleFrameworksOverlay \
    MarbleTelephonyOverlay

# Bluetooth profiles (the same set Qualcomm's QSSI turns on)
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.avrcp.controller.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true \
    bluetooth.profile.bas.client.enabled=true \
    bluetooth.profile.gatt.enabled=true \
    bluetooth.profile.hfp.ag.enabled=true \
    bluetooth.profile.hid.host.enabled=true \
    bluetooth.profile.map.server.enabled=true \
    bluetooth.profile.opp.enabled=true \
    bluetooth.profile.pan.nap.enabled=true \
    bluetooth.profile.pbap.server.enabled=true \
    bluetooth.profile.pbap.sim.enabled=true

# Apps
PRODUCT_PACKAGES += \
    Dialer \
    privapp_whitelist_com.android.dialer \
    jetpack-camera-app \
    messaging

# MIRACLO device fixes: NFC HAL on the NFC-less Indian model, qmipriod restart loop.
PRODUCT_COPY_FILES += \
    device/xiaomi/marble/init/init.marble.miraclo.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.marble.miraclo.rc

# Qualcomm performance libraries from the stock firmware (build-release.sh writes this).
-include device/xiaomi/marble/stock/perf.mk

# Mira performance: Android's boost framework talks to Qualcomm's perf service again
# (touch, scroll, app launch and animation boosts). setup-perf-libs.sh writes miraperf.mk.
-include device/xiaomi/marble/stock/miraperf/miraperf.mk
PRODUCT_PACKAGES += libmiraperf_jni
# Memory for 8 and 12 GB phones, and the system UI compiled ahead of time for speed.
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)
PRODUCT_DEXPREOPT_SPEED_APPS += SystemUI Launcher3QuickStep Settings

# Mira smoothness: the tuning file, and frame pacing, memory and app compiling the way phone
# makers set them (our own values).
PRODUCT_COPY_FILES += \
    vendor/miraclo/perf/init.miraclo.perf.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.miraclo.perf.rc
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    debug.sf.enable_adpf_cpu_hint=true \
    debug.hwui.use_hint_manager=true \
    debug.sf.frame_rate_multiple_threshold=120 \
    ro.lmk.use_minfree_levels=false \
    ro.lmk.psi_partial_stall_ms=70 \
    ro.lmk.psi_complete_stall_ms=700 \
    ro.lmk.thrashing_limit=30 \
    ro.lmk.thrashing_limit_decay=50 \
    ro.lmk.swap_util_max=90 \
    ro.lmk.kill_heaviest_task=true \
    dalvik.vm.boot-dex2oat-threads=8 \
    dalvik.vm.dex2oat-threads=6 \
    dalvik.vm.image-dex2oat-threads=8 \
    dalvik.vm.dex2oat-cpu-set=0,1,2,3,4,5,6,7 \
    dalvik.vm.boot-dex2oat-cpu-set=0,1,2,3,4,5,6,7 \
    pm.dexopt.first-boot=verify \
    pm.dexopt.boot-after-ota=verify \
    pm.dexopt.bg-dexopt=speed-profile \
    persist.sys.fflag.override.settings_enable_monitor_phantom_procs=false

# fix6: IMS JNI libraries, the AOSP WebView, Google Clock allowlist
PRODUCT_PACKAGES += \
    libimsmedia_jni \
    libimscamera_jni \
    privapp-permissions-miraclo-gapps \
    webview

# Test builds: Android's crash protection must never offer a factory reset
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_SYSTEM_PROPERTIES += persist.sys.disable_rescue=true
endif

# cam1: the stock HyperOS camera
PRODUCT_PACKAGES += \
    MiuiCamera
# Lets the camera app load its engine libraries from system_ext.
PRODUCT_COPY_FILES += \
    device/xiaomi/marble/configs/public.libraries-xiaomi.txt:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/public.libraries-xiaomi.txt

# fx3: no NFC on the Indian model (product/etc/permissions/sku_marblein)
PRODUCT_PACKAGES += \
    miraclo-no-nfc-marblein
