<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/MIRACLO-Project/MIRACLO/main/assets/header_light.png">
  <img alt="MIRACLO: Pure Android 17. Expressive where it counts." src="https://raw.githubusercontent.com/MIRACLO-Project/MIRACLO/main/assets/header_dark.png">
</picture>

# MIRACLO for the POCO F5 (marble)

Device configuration for the POCO F5 / Redmi Note 12 Turbo (marble),
Qualcomm SM7475.

MIRACLO builds system, system_ext and product. The phone keeps Xiaomi's stock
vendor, odm, vendor_dlkm, vendor_boot and dtbo images, Google's GKI boot image
and a few Qualcomm system components (see `Android.bp`) from the same
firmware. They are downloaded from Xiaomi by `fetch-stock.sh` and are not
stored here.

## Build

```
source build/envsetup.sh
m ota_extractor fsck.erofs aapt2 simg2img
device/xiaomi/marble/fetch-stock.sh
vendor/miraclo/gapps/extract-gapps.sh <Pixel factory image>   # skip for WITH_GMS=false
lunch miraclo_marble-cp2a-userdebug
m
```

The vanilla build (no Google apps): `WITH_GMS=false m`.

MIRACLO's recovery is built separately, after the ROM:
`MIRACLO_RECOVERY=true m recoveryimage`.

## Stock firmware

Based on HyperOS OS3.0.4.0.VMRMIXM (Global, Android 15). The phone's firmware
(bootloader, modem and the other firmware partitions) must be from the same
HyperOS version, OS3.0.4.0, for your region; older firmware does not boot.
