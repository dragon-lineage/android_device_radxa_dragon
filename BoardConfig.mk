#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

TARGET_DEVICE_PATH := device/radxa/dragon

# Inherit the generic arm64 platform first, then narrow it to Dragon Q6A.
include device/mainline/generic/Generic_arm64/BoardConfig.mk

BOARD_KERNEL_CMDLINE := $(filter-out androidboot.console=%,$(BOARD_KERNEL_CMDLINE))

# Boot manager
TARGET_GRUB_LIVE_CONFIGS := $(TARGET_DEVICE_PATH)/configs/bootmgr/grub.cfg
TARGET_GRUB_TOOLS_ARCH := x86_64-efi
TARGET_GRUB_MODULES_HOST_PREBUILT_TAG := linux-arm64
TARGET_LIVEISO_DTB := $(PRODUCT_OUT)/dtb.img
TARGET_LIVEISO_DTB_NAME := qcs6490-radxa-dragon-q6a.dtb
TARGET_BUILD_RAWIMAGE := true
TARGET_RAWIMAGE_GRUB_CONFIG := $(TARGET_DEVICE_PATH)/configs/bootmgr/grub-disk.cfg
TARGET_RAWIMAGE_GRUB_LOAD_CONFIG := $(TARGET_DEVICE_PATH)/configs/bootmgr/grub-load.cfg

# Boot parameters
BOARD_KERNEL_CMDLINE += \
    console=ttyMSM0,115200n8 \
    earlycon \
    initcall_blacklist=simpledrm_platform_driver_init \
    clk_ignore_unused

BOARD_KERNEL_CMDLINE_SERIAL_CONSOLE := \
    androidboot.console=ttyMSM0 \
    ignore_loglevel \
    loglevel=7

# Graphics (Mesa)
BOARD_MESA3D_GALLIUM_DRIVERS := freedreno
BOARD_MESA3D_VULKAN_DRIVERS := freedreno
$(call soong_config_set,minigbm_upstream,platform,msm)

# Kernel
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_DTB_LIST_WILDCARD := qcom/qcs6490-radxa-dragon-q6a
TARGET_KERNEL_CONFIG := radxa_qcom_7_0_defconfig
TARGET_KERNEL_CONFIG_EXT := \
    kernel/mainline/configs/fragments/android-base-pre/common.config \
    kernel/mainline/configs/fragments/android-base-pre/arm64.config \
    kernel/mainline/configs/fragments/android-base-conditional/CONFIG_ARM64-y.config \
    kernel/mainline/configs/fragments/android-base-conditional/CONFIG_EXT4_FS-y.config \
    kernel/mainline/configs/fragments/android-base-conditional/CONFIG_F2FS_FS-y.config \
    kernel/mainline/configs/fragments/common.config \
    $(TARGET_DEVICE_PATH)/configs/kernel/android.config \
    kernel/mainline/configs/fragments/y/fbcon.config \
    kernel/mainline/configs/fragments/n/disable-clang-hardening-features.config \
    kernel/mainline/configs/fragments/n/faster-build-time.config \
    device/mainline/generic/configs/kernel/customizations.config
TARGET_KERNEL_DTB := qcom/qcs6490-radxa-dragon-q6a.dtb
TARGET_KERNEL_SOURCE := kernel/radxa/dragon
TARGET_KERNEL_ADDITIONAL_FLAGS += CONFIG_USE_FW_REQUEST=y
TARGET_KERNEL_EXT_MODULE_ROOT := kernel/radxa/aic8800/src/USB/driver_fw/drivers
TARGET_KERNEL_EXT_MODULES := aic8800:kbuild

BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    aic_load_fw.ko \
    aic8800_fdrv.ko

# Firmware
TARGET_LINUX_FIRMWARE_REPO := external/linux-firmware-upstream
TARGET_LINUX_FIRMWARE_EXTRA_DIRS := kernel/radxa/aic8800/src/USB/driver_fw/fw/aic8800D80
