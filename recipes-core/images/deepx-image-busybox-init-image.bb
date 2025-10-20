# DEEPX Image with BusyBox init system
#
# This image uses BusyBox init as the init process, providing a lightweight
# and minimal init system suitable for embedded systems.
# BusyBox init offers simplicity, small footprint, and fast boot times.
#
# IMPORTANT: This image REQUIRES busybox init manager
#   Set in build/conf/local.conf:
#   VIRTUAL-RUNTIME_init_manager = "busybox"
#
# Features:
#   - BusyBox init as init system (PID 1)
#   - Minimal footprint and dependencies
#   - Fast boot time
#   - Simple inittab-based configuration
#   - Suitable for resource-constrained embedded systems
#
# Build:
#   bitbake deepx-image-busybox-init-image

SUMMARY = "DEEPX-V3 Image with busybox init system"
DESCRIPTION = "A minimal DEEPX image using busybox init as the init process"
LICENSE = "MIT"

# Validate init manager configuration - skip if wrong init manager
REQUIRED_INIT_MANAGER = "busybox"

python () {
    init_manager = d.getVar('VIRTUAL-RUNTIME_init_manager')
    required = d.getVar('REQUIRED_INIT_MANAGER')
    pn = d.getVar('PN')

    if init_manager != required:
        raise bb.parse.SkipRecipe("Image '%s' requires VIRTUAL-RUNTIME_init_manager='%s' but '%s' is configured. Skipping." % (pn, required, init_manager))
}

inherit core-image
inherit deepx-image-skeleton
inherit deepx-image-wic

# Dependencies
DEPENDS += "deepx-tools-native"

# For initramfs, we want busybox init directly, not virtual runtime
PACKAGE_INSTALL = "busybox ${IMAGE_INSTALL}"

# tiny image
IMAGE_INSTALL:remove = " packagegroup-core-boot packagegroup-base-extended"
IMAGE_INSTALL:append = " busybox-mount-data"

# Don't allow the initramfs to contain a kernel
PACKAGE_EXCLUDE = "kernel-image-*"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

DISTRO_FEATURES_BACKFILL  = ""
MACHINE_FEATURES_BACKFILL = ""

BAD_RECOMMENDATIONS += "busybox-syslog"

# Image configuration
export IMAGE_BASENAME = "deepx-busybox-image"
IMAGE_LINGUAS = ""

IMAGE_FSTYPES = "wic wic.bmap"

# WIC configuration
WKS_FILE = "deepx-v3-mmc.wks"

IMAGE_BOOTFS_WIC_DISK ?= "mmcblk2"
IMAGE_BOOTFS_WIC_SIZE ?= "64M"

IMAGE_ROOTFS_WIC_DISK ?= "mmcblk2"
IMAGE_ROOTFS_WIC_SIZE ?= "512M"
IMAGE_ROOTFS_EXTRA_SPACE ?= "0"

# Boot partition files
IMAGE_BOOT_FILES ?= "${KERNEL_IMAGETYPE} linux.dtb"
