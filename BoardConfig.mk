#
# SPDX-FileCopyrightText: MiraCLO
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/marble

# Xiaomi's stock images, fetched by fetch-stock.sh (not kept in git)
MARBLE_STOCK := $(DEVICE_PATH)/stock

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

# Platform
TARGET_BOARD_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := taro
TARGET_NO_BOOTLOADER := true

# boot.img: Google's GKI boot image from the stock firmware (the android12-5.10
# kernel with Google's generic ramdisk), header v4, no init_boot.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_PREBUILT_BOOTIMAGE := $(MARBLE_STOCK)/boot.img
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592

# Recovery: MiraCLO's own recovery comes in a later step; until then the
# recovery partition is left as it is.
TARGET_NO_RECOVERY := true

# Stock images used as they are
BOARD_PREBUILT_VENDORIMAGE := $(MARBLE_STOCK)/vendor.img
BOARD_PREBUILT_ODMIMAGE := $(MARBLE_STOCK)/odm.img
BOARD_PREBUILT_VENDOR_DLKMIMAGE := $(MARBLE_STOCK)/vendor_dlkm.img

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product

BOARD_USES_VENDORIMAGE := true
BOARD_USES_ODMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

# MiraCLO's own partitions
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USES_METADATA_PARTITION := true
BOARD_FLASH_BLOCK_SIZE := 262144

# Super: 9 GiB on the device; one 8 GiB group (virtual A/B keeps one slot in super)
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 8589934592
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system system_ext product vendor odm vendor_dlkm

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    odm \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# Verified boot: vbmeta covers boot, dtbo, vendor_boot and the stock vendor
# images; vbmeta_system covers MiraCLO's system partitions (the stock fstab
# mounts them with avb=vbmeta_system). The stock images keep Xiaomi's and
# Google's signatures, so verification is turned off in vbmeta (flags 3); the
# device runs with an unlocked bootloader.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += \
    --include_descriptors_from_image $(MARBLE_STOCK)/vendor_boot.img \
    --include_descriptors_from_image $(MARBLE_STOCK)/dtbo.img \
    --flags 3

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

# VINTF: the framework also accepts the Qualcomm vendor HALs the stock vendor
# declares (the same matrix CLO's QSSI uses).
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \
    vendor/qcom/opensource/core-utils/vendor_framework_compatibility_matrix.xml

# Bluetooth: Qualcomm's stack (the stock vendor runs the QTI Bluetooth HALs)
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true

# SELinux: Qualcomm's system_ext and product policy, as in CLO's QSSI. It labels
# the Qualcomm system services the stock vendor talks to (telephony, perf, ...).
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += device/qcom/sepolicy/generic/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += device/qcom/sepolicy/generic/private
PRODUCT_PUBLIC_SEPOLICY_DIRS += device/qcom/sepolicy/generic/product/public
PRODUCT_PRIVATE_SEPOLICY_DIRS += device/qcom/sepolicy/generic/product/private
BOARD_SYSTEM_EXT_SEPOLICY_PREBUILT_DIRS := device/qcom/sepolicy/generic
BOARD_PRODUCT_SEPOLICY_PREBUILT_DIRS := device/qcom/sepolicy/generic/product
