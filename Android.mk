#
# SPDX-FileCopyrightText: MiraCLO
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),marble)

# The stock vendor_boot and dtbo go into the update byte for byte, as firmware
# images (the build would otherwise rewrite their verified-boot footers).
$(call add-radio-file,stock/vendor_boot.img)
$(call add-radio-file,stock/dtbo.img)

# The stock firmware (bootloader, modem, DSP, TrustZone...), so updates carry it too.
$(foreach f,$(wildcard $(LOCAL_PATH)/stock/firmware/*.img),\
    $(call add-radio-file,stock/firmware/$(notdir $(f))))

endif
