#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)
$(call inherit-product, device/radxa/dragon/device.mk)

PRODUCT_NAME := lineage_dragon
PRODUCT_DEVICE := dragon
PRODUCT_BRAND := Radxa
PRODUCT_MANUFACTURER := Radxa
PRODUCT_MODEL := Generic Radxa Dragon
