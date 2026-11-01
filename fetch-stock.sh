#!/bin/bash
#
# SPDX-FileCopyrightText: MiraCLO
# SPDX-License-Identifier: Apache-2.0
#
# Downloads Xiaomi's official HyperOS update for the POCO F5 and extracts what
# MiraCLO runs unchanged: the vendor, odm, vendor_dlkm, vendor_boot and dtbo
# images, Google's GKI boot image (and its kernel), and the Qualcomm system
# components listed in Android.bp. Xiaomi's files are never stored in git.
#
# Run from the top of the source tree after building the host tools once:
#   m ota_extractor fsck.erofs
#   device/xiaomi/marble/fetch-stock.sh

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

if [ -f "${OUT_DIR}/VERSION" ] && [ "$(cat "${OUT_DIR}/VERSION")" = "${STOCK_VERSION}" ]; then
    echo "Stock images for ${STOCK_VERSION} are already there."
    exit 0
fi

echo "Downloading ${STOCK_VERSION} from Xiaomi..."
wget -c -q --show-progress -O "${WORK_DIR}/${STOCK_ZIP}" "${STOCK_URL}"

echo "Extracting the update payload..."
unzip -o -q "${WORK_DIR}/${STOCK_ZIP}" payload.bin -d "${WORK_DIR}"
"${EXTRACTOR}" --payload "${WORK_DIR}/payload.bin" --output_dir "${OUT_DIR}" \
    --partitions boot,vendor_boot,dtbo,vendor,odm,vendor_dlkm
"${EXTRACTOR}" --payload "${WORK_DIR}/payload.bin" --output_dir "${WORK_DIR}" \
    --partitions system_ext

echo "Taking the kernel out of boot.img..."
python3 "${UNPACK_BOOTIMG}" --boot_img "${OUT_DIR}/boot.img" --out "${WORK_DIR}/boot" > /dev/null
cp "${WORK_DIR}/boot/kernel" "${OUT_DIR}/kernel"

echo "Taking the Qualcomm system components out of system_ext..."
"${FSCK_EROFS}" --extract="${WORK_DIR}/system_ext" "${WORK_DIR}/system_ext.img" > /dev/null
for f in \
    app/QtiTelephonyService/QtiTelephonyService.apk \
    lib64/vendor.qti.hardware.radio.am@1.0.so \
    lib/vendor.qti.hardware.radio.am@1.0.so; do
    install -D -m 0644 "${WORK_DIR}/system_ext/${f}" "${OUT_DIR}/system_ext/${f}"
done

echo "${STOCK_VERSION}" > "${OUT_DIR}/VERSION"
rm -rf "${WORK_DIR}"
echo "Done: stock images for ${STOCK_VERSION} are in device/xiaomi/marble/stock"
