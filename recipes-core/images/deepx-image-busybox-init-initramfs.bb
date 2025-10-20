# DEEPX Initramfs Image with BusyBox init system
#
# This image creates an initramfs (initial RAM filesystem) using BusyBox init,
# designed for early boot stages.
# Initramfs provides a minimal environment loaded into RAM before mounting root.
#
# IMPORTANT: This image REQUIRES busybox init manager
#   Set in build/conf/local.conf:
#   VIRTUAL-RUNTIME_init_manager = "busybox"
#
# Features:
#   - BusyBox init as init system (PID 1)
#   - Minimal RAM-based filesystem
#   - Fast boot and early userspace initialization
#   - No persistent storage required
#
# Build:
#   bitbake deepx-image-busybox-init-initramfs

SUMMARY = "DEEPX-V3 initramfs with busybox init system."
DESCRIPTION = "A minimal DEEPX initramfs using busybox init as the init process"
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
inherit deepx-image-cpio

# Install deepx tools
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

# The base name of image output files.
export IMAGE_BASENAME = "deepx-busybox-initramfs"
IMAGE_LINGUAS = ""

IMAGE_FSTYPES = " cpio"
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE ?= "0"
