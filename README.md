# MiraCLO for the POCO F5 (marble)

Device configuration for the POCO F5 / Redmi Note 12 Turbo (marble),
Qualcomm SM7475.

MiraCLO builds system, system_ext and product. The phone keeps Xiaomi's stock
vendor, odm, vendor_dlkm, vendor_boot and dtbo images, Google's GKI boot image
and a few Qualcomm system components (see `Android.bp`) from the same
firmware. They are downloaded from Xiaomi by `fetch-stock.sh` and are not
stored here.

## Build

```
source build/envsetup.sh
m ota_extractor fsck.erofs
device/xiaomi/marble/fetch-stock.sh
lunch miraclo_marble-cp2a-userdebug
m
```

## Stock firmware

Based on HyperOS OS3.0.4.0.VMRMIXM (Global, Android 15). The phone's firmware
(bootloader, modem and the other firmware partitions) must be from the same
HyperOS version, OS3.0.4.0, for your region; older firmware does not boot.
