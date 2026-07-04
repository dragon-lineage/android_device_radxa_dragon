#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

TARGET_DEVICE_PATH := device/radxa/dragon

$(call inherit-product, device/mainline/generic/Generic_arm64/device.mk)

PRODUCT_COPY_FILES += \
    device/mainline/generic/configs/audio/audio.generic.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio.dragon.xml

PRODUCT_SOONG_NAMESPACES += \
    $(TARGET_DEVICE_PATH)

DEVICE_PACKAGE_OVERLAYS += \
    $(TARGET_DEVICE_PATH)/overlays/overlay

PRODUCT_VENDOR_PROPERTIES += \
    vendor.hwc.drm.ctm=DRM_OR_IGNORE \
    vendor.hwc.drm.force_sdr=true
