#!/bin/bash
#
# SPDX-FileCopyrightText: MIRACLO
# SPDX-License-Identifier: Apache-2.0
#
# Downloads Xiaomi's official HyperOS update for the POCO F5 and extracts what
# MIRACLO runs unchanged: the vendor, odm, vendor_dlkm, vendor_boot and dtbo
# images, Google's GKI boot image (and its kernel), and the Qualcomm system
# components listed in Android.bp. Xiaomi's files are never stored in git.
#
# Run from the top of the source tree after building the host tools once:
#   m ota_extractor fsck.erofs
#   device/xiaomi/marble/fetch-stock.sh
# To use an update zip you already have: STOCK_LOCAL_ZIP=/path/to/zip ...

set -e

STOCK_VERSION="OS3.0.4.0.VMRMIXM"
STOCK_ZIP="marble_global-ota_full-OS3.0.4.0.VMRMIXM-user-15.0-38f732ce3d.zip"
STOCK_URL="https://cdnorg.d.miui.com/${STOCK_VERSION}/${STOCK_ZIP}"

TOP="$(pwd)"
DEVICE_DIR="${TOP}/device/xiaomi/marble"
OUT_DIR="${DEVICE_DIR}/stock"
WORK_DIR="${OUT_DIR}/.work"
EXTRACTOR="${TOP}/out/host/linux-x86/bin/ota_extractor"
FSCK_EROFS="${TOP}/out/host/linux-x86/bin/fsck.erofs"
UNPACK_BOOTIMG="${TOP}/system/tools/mkbootimg/unpack_bootimg.py"

if [ ! -x "${EXTRACTOR}" ] || [ ! -x "${FSCK_EROFS}" ]; then
    echo "Host tools missing; build them first: m ota_extractor fsck.erofs" >&2
    exit 1
fi

mkdir -p "${WORK_DIR}"

# Qualcomm system components taken from the stock system_ext (see Android.bp).
SYSTEM_EXT_FILES="
    app/QtiTelephonyService/QtiTelephonyService.apk
    lib64/vendor.qti.hardware.radio.am@1.0.so
    lib/vendor.qti.hardware.radio.am@1.0.so
    priv-app/QtiTelephony/QtiTelephony.apk
    priv-app/ims/ims.apk
    lib64/libcamera_algoup_jni.xiaomi.so
    lib64/libcamera_mianode_jni.xiaomi.so
    lib64/libcameraopt.so
    lib64/libcrop.so
    lib64/libbacktrace.so
    lib64/libimsmedia_jni.so
    lib64/libimscamera_jni.so
    framework/qcrilhook.jar
    etc/permissions/qcrilhook.xml
    etc/permissions/telephony_system-ext_privapp-permissions-qti.xml
    etc/sysconfig/qti_telephony_system_packages_config.xml
"

# The stock HyperOS camera, taken from the stock product partition (see Android.bp).
PRODUCT_FILES="
    priv-app/MiuiCamera/MiuiCamera.apk
"

# Qualcomm's performance libraries (touch and scroll boost), taken when the firmware has them.
SYSTEM_EXT_OPTIONAL="
    framework/QPerformance.jar
    framework/UxPerformance.jar
"

# Partitions MIRACLO builds itself, or that are not firmware; everything else in the stock
# update is firmware (bootloader, modem, DSP, TrustZone...) and ships in the release.
NOT_FIRMWARE="system system_ext product odm vendor vendor_dlkm system_dlkm mi_ext vbmeta vbmeta_system boot vendor_boot dtbo init_boot recovery"

have_all() {
    [ -f "${OUT_DIR}/VERSION" ] && [ "$(cat "${OUT_DIR}/VERSION")" = "${STOCK_VERSION}" ] || return 1
    [ -f "${OUT_DIR}/fstab.qcom" ] || return 1
    [ -f "${OUT_DIR}/firmware/.done" ] || return 1
    for f in ${SYSTEM_EXT_FILES}; do
        [ -f "${OUT_DIR}/system_ext/${f}" ] || return 1
    done
    for f in ${PRODUCT_FILES}; do
        [ -f "${OUT_DIR}/product/${f}" ] || return 1
    done
    return 0
}

if have_all; then
    echo "Stock images for ${STOCK_VERSION} are already there."
    exit 0
fi

if [ -n "${STOCK_LOCAL_ZIP}" ] && [ -f "${STOCK_LOCAL_ZIP}" ]; then
    echo "Using ${STOCK_LOCAL_ZIP}"
    ln -sf "$(realpath "${STOCK_LOCAL_ZIP}")" "${WORK_DIR}/${STOCK_ZIP}"
else
    echo "Downloading ${STOCK_VERSION} from Xiaomi..."
    wget -c -q --show-progress -O "${WORK_DIR}/${STOCK_ZIP}" "${STOCK_URL}"
fi

echo "Extracting the update payload..."
unzip -o -q "${WORK_DIR}/${STOCK_ZIP}" payload.bin -d "${WORK_DIR}"
"${EXTRACTOR}" --payload "${WORK_DIR}/payload.bin" --output_dir "${OUT_DIR}" \
    --partitions boot,vendor_boot,dtbo,vendor,odm,vendor_dlkm
"${EXTRACTOR}" --payload "${WORK_DIR}/payload.bin" --output_dir "${WORK_DIR}" \
    --partitions system_ext

echo "Taking the firmware (bootloader, modem, DSP...)..."
mkdir -p "${WORK_DIR}/all" "${OUT_DIR}/firmware"
rm -f "${OUT_DIR}/firmware/"*.img
"${EXTRACTOR}" --payload "${WORK_DIR}/payload.bin" --output_dir "${WORK_DIR}/all"
for img in "${WORK_DIR}/all/"*.img; do
    name="$(basename "${img}" .img)"
    case " ${NOT_FIRMWARE} " in *" ${name} "*) continue ;; esac
    mv "${img}" "${OUT_DIR}/firmware/${name}.img"
done
ls "${OUT_DIR}/firmware" | sed 's/^/   firmware: /'
touch "${OUT_DIR}/firmware/.done"

echo "Taking the kernel out of boot.img..."
python3 "${UNPACK_BOOTIMG}" --boot_img "${OUT_DIR}/boot.img" --out "${WORK_DIR}/boot" > /dev/null
cp "${WORK_DIR}/boot/kernel" "${OUT_DIR}/kernel"

echo "Taking the Qualcomm system components out of system_ext..."
"${FSCK_EROFS}" --extract="${WORK_DIR}/system_ext" "${WORK_DIR}/system_ext.img" > /dev/null
for f in ${SYSTEM_EXT_FILES}; do
    install -D -m 0644 "${WORK_DIR}/system_ext/${f}" "${OUT_DIR}/system_ext/${f}"
done
for f in ${SYSTEM_EXT_OPTIONAL}; do
    if [ -f "${WORK_DIR}/system_ext/${f}" ]; then
        install -D -m 0644 "${WORK_DIR}/system_ext/${f}" "${OUT_DIR}/system_ext/${f}"
        echo "   taken: ${f}"
    fi
done

echo "Taking the vendor fstab (used by the recovery)..."
"${FSCK_EROFS}" --extract="${WORK_DIR}/vendor" "${OUT_DIR}/vendor.img" > /dev/null
install -m 0644 "${WORK_DIR}/vendor/etc/fstab.qcom" "${OUT_DIR}/fstab.qcom"

echo "Taking the stock camera out of product..."
"${FSCK_EROFS}" --extract="${WORK_DIR}/product" "${WORK_DIR}/all/product.img" > /dev/null
for f in ${PRODUCT_FILES}; do
    install -D -m 0644 "${WORK_DIR}/product/${f}" "${OUT_DIR}/product/${f}"
done

echo "${STOCK_VERSION}" > "${OUT_DIR}/VERSION"
rm -rf "${WORK_DIR}"
echo "Done: stock images for ${STOCK_VERSION} are in device/xiaomi/marble/stock"
