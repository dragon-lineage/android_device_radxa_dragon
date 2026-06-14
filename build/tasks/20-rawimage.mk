#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(TARGET_DEVICE),dragon)

INSTALLED_RAWIMAGE_TARGET := $(PRODUCT_OUT)/$(BOOTMGR_ARTIFACT_FILENAME_PREFIX)-disk.img
RAWIMAGE_WORK_DIR := $(TARGET_OUT_INTERMEDIATES)/RAWIMAGE_OBJ
RAWIMAGE_FIRMWARE_DIR := $(TARGET_OUT_INTERMEDIATES)/RAWIMAGE_FIRMWARE
RAWIMAGE_FIRMWARE_STAMP := $(RAWIMAGE_FIRMWARE_DIR)/.timestamp

RAWIMAGE_ESP_SIZE_MIB ?= 256
RAWIMAGE_METADATA_SIZE_MIB ?= 64
RAWIMAGE_USERDATA_SIZE_MIB ?= 12288
RAWIMAGE_PART_EXTRA_MIB ?= 16

RAWIMAGE_GRUB_CONFIG := device/radxa/dragon/configs/bootmgr/grub-disk.cfg
RAWIMAGE_GRUB_LOAD_CONFIG := device/radxa/dragon/configs/bootmgr/grub-load.cfg
RAWIMAGE_GRUB_TOOL_DIR := prebuilts/bootmgr/grub/$(TARGET_GRUB_HOST_PREBUILT_TAG)/$(TARGET_GRUB_TOOLS_ARCH)
RAWIMAGE_GRUB_MODULE_DIR := prebuilts/bootmgr/grub/$(TARGET_GRUB_MODULES_HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)/lib/grub/$(TARGET_GRUB_ARCH)
RAWIMAGE_GRUB_FONT := prebuilts/bootmgr/grub/$(TARGET_GRUB_MODULES_HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)/share/grub/unicode.pf2
RAWIMAGE_MTOOLS_DIR ?= /usr/bin
RAWIMAGE_SGDISK ?= /usr/sbin/sgdisk

RAWIMAGE_INCLUDE_FILES := \
    $(INSTALLED_RAMDISK_ALL_COMBINED_TARGET) \
    $(PRODUCT_OUT)/kernel \
    $(TARGET_LIVEISO_DTB) \
    $(PRODUCT_OUT)/system.img \
    $(PRODUCT_OUT)/system_dlkm.img \
    $(PRODUCT_OUT)/vendor.img \
    $(PRODUCT_OUT)/vendor_dlkm.img

$(RAWIMAGE_FIRMWARE_STAMP): $(TARGET_LINUX_FIRMWARE_REPO)/WHENCE $(TARGET_LINUX_FIRMWARE_REPO)/copy-firmware.sh
	rm -rf $(RAWIMAGE_FIRMWARE_DIR)
	mkdir -p $(RAWIMAGE_FIRMWARE_DIR)
	cd $(TARGET_LINUX_FIRMWARE_REPO) && PATH=/usr/bin:/bin ./copy-firmware.sh $(abspath $(RAWIMAGE_FIRMWARE_DIR))
	touch $@

INSTALLED_RAWIMAGE_TARGET_DEPS := \
    $(RAWIMAGE_INCLUDE_FILES) \
    $(RAWIMAGE_FIRMWARE_STAMP) \
    $(RAWIMAGE_GRUB_CONFIG) \
    $(RAWIMAGE_GRUB_LOAD_CONFIG) \
    $(RAWIMAGE_GRUB_FONT) \
    $(RAWIMAGE_GRUB_TOOL_DIR)/bin/grub-mkstandalone

define make-rawimage-target
	test -x $(RAWIMAGE_MTOOLS_DIR)/mcopy || { echo "Missing host tool: $(RAWIMAGE_MTOOLS_DIR)/mcopy (install mtools)" >&2; exit 1; }
	test -x $(RAWIMAGE_MTOOLS_DIR)/mformat || { echo "Missing host tool: $(RAWIMAGE_MTOOLS_DIR)/mformat (install mtools)" >&2; exit 1; }
	test -x $(RAWIMAGE_MTOOLS_DIR)/mmd || { echo "Missing host tool: $(RAWIMAGE_MTOOLS_DIR)/mmd (install mtools)" >&2; exit 1; }
	test -x $(RAWIMAGE_SGDISK) || { echo "Missing host tool: $(RAWIMAGE_SGDISK) (install gdisk)" >&2; exit 1; }
	rm -rf $(RAWIMAGE_WORK_DIR)
	mkdir -p \
		$(RAWIMAGE_WORK_DIR)/boot-root/$(BOOTMGR_ANDROID_DIR_NAME) \
		$(RAWIMAGE_WORK_DIR)/boot-root/boot/grub/fonts \
		$(RAWIMAGE_WORK_DIR)/empty
	cp $(PRODUCT_OUT)/kernel $(RAWIMAGE_WORK_DIR)/boot-root/$(BOOTMGR_ANDROID_DIR_NAME)/kernel
	cp $(INSTALLED_RAMDISK_ALL_COMBINED_TARGET) $(RAWIMAGE_WORK_DIR)/boot-root/$(BOOTMGR_ANDROID_DIR_NAME)/ramdisk-all-combined.img
	cp $(TARGET_LIVEISO_DTB) $(RAWIMAGE_WORK_DIR)/boot-root/$(BOOTMGR_ANDROID_DIR_NAME)/$(TARGET_LIVEISO_DTB_NAME)
	cp -a $(RAWIMAGE_FIRMWARE_DIR) $(RAWIMAGE_WORK_DIR)/boot-root/firmware
	cp $(RAWIMAGE_GRUB_FONT) $(RAWIMAGE_WORK_DIR)/boot-root/boot/grub/fonts/unicode.pf2
	cp $(RAWIMAGE_GRUB_CONFIG) $(RAWIMAGE_WORK_DIR)/boot-root/boot/grub/grub.cfg
	$(call process-bootmgr-cfg-common,$(RAWIMAGE_WORK_DIR)/boot-root/boot/grub/grub.cfg)
	$(BOOTMGR_PATH_OVERRIDE) $(BOOTMGR_TOOLS_64_EXEC_ENV) $(RAWIMAGE_GRUB_TOOL_DIR)/bin/grub-mkstandalone \
		-O $(TARGET_GRUB_ARCH) \
		-d $(RAWIMAGE_GRUB_MODULE_DIR) \
		--locales="" \
		--modules="part_gpt fat ext2 normal linux fdt search search_label configfile echo all_video efi_gop gfxterm font reboot halt" \
		-o $(RAWIMAGE_WORK_DIR)/BOOTAA64.EFI \
		boot/grub/grub.cfg=$(RAWIMAGE_GRUB_LOAD_CONFIG)
	truncate -s $(RAWIMAGE_ESP_SIZE_MIB)M $(RAWIMAGE_WORK_DIR)/esp.img
	$(RAWIMAGE_MTOOLS_DIR)/mformat -i $(RAWIMAGE_WORK_DIR)/esp.img -F -v EFI ::
	$(RAWIMAGE_MTOOLS_DIR)/mmd -i $(RAWIMAGE_WORK_DIR)/esp.img ::/EFI ::/EFI/BOOT
	$(RAWIMAGE_MTOOLS_DIR)/mcopy -i $(RAWIMAGE_WORK_DIR)/esp.img $(RAWIMAGE_WORK_DIR)/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
	set -e; \
		boot_used_mib=$$(du -sm $(RAWIMAGE_WORK_DIR)/boot-root | awk '{print $$1}'); \
		boot_size_mib=$$((boot_used_mib + 256)); \
		PATH=$(HOST_OUT_EXECUTABLES):$$PATH $(MKEXTUSERIMG) --label BOOT --inode_size 256 --journal_size 0 --reserved_percent 0 \
			$(RAWIMAGE_WORK_DIR)/boot-root $(RAWIMAGE_WORK_DIR)/boot.img ext4 / $$((boot_size_mib * 1024 * 1024)); \
		PATH=$(HOST_OUT_EXECUTABLES):$$PATH $(MKEXTUSERIMG) --label metadata --inode_size 256 --journal_size 0 --reserved_percent 0 \
			$(RAWIMAGE_WORK_DIR)/empty $(RAWIMAGE_WORK_DIR)/metadata.img ext4 /metadata $$(( $(RAWIMAGE_METADATA_SIZE_MIB) * 1024 * 1024 )); \
		PATH=$(HOST_OUT_EXECUTABLES):$$PATH $(MKEXTUSERIMG) --label userdata --inode_size 256 --journal_size 0 --reserved_percent 0 \
			$(RAWIMAGE_WORK_DIR)/empty $(RAWIMAGE_WORK_DIR)/userdata.img ext4 /data $$(( $(RAWIMAGE_USERDATA_SIZE_MIB) * 1024 * 1024 )); \
		ceil_mib() { echo $$((($$1 + 1048575) / 1048576)); }; \
		next_sector=2048; \
		sgdisk_args=(); \
		dd_args=(); \
		add_part() { \
			local idx="$$1" name="$$2" type="$$3" image="$$4" size_mib="$$5"; \
			local sectors=$$((size_mib * 2048)); \
			local end=$$((next_sector + sectors - 1)); \
			sgdisk_args+=("--new=$${idx}:$${next_sector}:$${end}" "--typecode=$${idx}:$${type}" "--change-name=$${idx}:$${name}"); \
			dd_args+=("$${image}:$${next_sector}"); \
			next_sector=$$((end + 1)); \
		}; \
		add_part 1 EFI EF00 $(RAWIMAGE_WORK_DIR)/esp.img $(RAWIMAGE_ESP_SIZE_MIB); \
		add_part 2 BOOT 8300 $(RAWIMAGE_WORK_DIR)/boot.img $$boot_size_mib; \
		add_part 3 system 8300 $(PRODUCT_OUT)/system.img $$(( $$(ceil_mib $$(stat -c %s $(PRODUCT_OUT)/system.img)) + $(RAWIMAGE_PART_EXTRA_MIB) )); \
		add_part 4 vendor 8300 $(PRODUCT_OUT)/vendor.img $$(( $$(ceil_mib $$(stat -c %s $(PRODUCT_OUT)/vendor.img)) + $(RAWIMAGE_PART_EXTRA_MIB) )); \
		add_part 5 system_dlkm 8300 $(PRODUCT_OUT)/system_dlkm.img $$(( $$(ceil_mib $$(stat -c %s $(PRODUCT_OUT)/system_dlkm.img)) + $(RAWIMAGE_PART_EXTRA_MIB) )); \
		add_part 6 vendor_dlkm 8300 $(PRODUCT_OUT)/vendor_dlkm.img $$(( $$(ceil_mib $$(stat -c %s $(PRODUCT_OUT)/vendor_dlkm.img)) + $(RAWIMAGE_PART_EXTRA_MIB) )); \
		add_part 7 metadata 8300 $(RAWIMAGE_WORK_DIR)/metadata.img $(RAWIMAGE_METADATA_SIZE_MIB); \
		add_part 8 userdata 8300 $(RAWIMAGE_WORK_DIR)/userdata.img $(RAWIMAGE_USERDATA_SIZE_MIB); \
		rm -f $(1) $(1).sha256; \
		truncate -s $$(((next_sector + 2048) * 512)) $(1); \
		$(RAWIMAGE_SGDISK) --clear --set-alignment=2048 "$${sgdisk_args[@]}" $(1); \
		for item in "$${dd_args[@]}"; do \
			image="$${item%:*}"; \
			start="$${item##*:}"; \
			/usr/bin/dd if="$$image" of=$(1) bs=512 seek="$$start" conv=notrunc,sparse status=none; \
		done; \
		$(RAWIMAGE_SGDISK) --verify $(1); \
		$(RAWIMAGE_SGDISK) --print $(1); \
		sha256sum $(1) > $(1).sha256
endef

$(INSTALLED_RAWIMAGE_TARGET): $(INSTALLED_RAWIMAGE_TARGET_DEPS)
	$(call pretty,"Target Raw image: $@")
	$(call make-rawimage-target,$@)

.PHONY: rawimage
rawimage: $(INSTALLED_RAWIMAGE_TARGET)

.PHONY: rawimage-nodeps
rawimage-nodeps:
	@echo "make $(INSTALLED_RAWIMAGE_TARGET): ignoring dependencies"
	$(call make-rawimage-target,$(INSTALLED_RAWIMAGE_TARGET))

endif # TARGET_DEVICE == dragon
