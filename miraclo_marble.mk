#
# SPDX-FileCopyrightText: MIRACLO
# SPDX-License-Identifier: Apache-2.0
#

# MIRACLO for the POCO F5 (marble)

MIRACLO_BUILD := marble

$(call inherit-product, device/xiaomi/marble/device.mk)
$(call inherit-product, vendor/miraclo/config/common.mk)

PRODUCT_NAME := miraclo_marble
PRODUCT_DEVICE := marble
PRODUCT_BRAND := POCO
PRODUCT_MODEL := POCO F5
PRODUCT_MANUFACTURER := Xiaomi
