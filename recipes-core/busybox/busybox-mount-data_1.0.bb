SUMMARY = "Busybox init data partition mount service"
DESCRIPTION = "Provides SysV init script for automatic data partition \
               detection, formatting, and mounting at /data directory."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Setup file search paths for busybox 1.36.x versions
FILESEXTRAPATHS:prepend := "${THISDIR}/1.36:${THISDIR}:"

# Data partition configuration
IMAGE_DATA_PART_DEVICE_NODE ??= "/dev/mmcblk2p3"
IMAGE_DATA_PART_WAIT_TIME ??= "2"
IMAGE_DATA_PART_MOUNT_OPTIONS ??= "noatime,nosuid,nodev"

# Source files
SRC_URI = "${@'file://1.36/S03mount.data' \
            if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
            else ''}"

S = "${WORKDIR}"

do_install() {
    # Install init script for busybox init manager
    if [ -n "${IMAGE_DATA_PART_DEVICE_NODE}" ]; then
        install -d ${D}${sysconfdir}/rc5.d

        # Install and configure S03mount.data script
        install -m 0755 ${WORKDIR}/1.36/S03mount.data \
            ${D}${sysconfdir}/rc5.d/S03mount.data

        # Update device node, wait time, mount options, and tool paths
        sed -i \
            -e 's|MOUNT_DEVICE="[^"]*"|MOUNT_DEVICE="${IMAGE_DATA_PART_DEVICE_NODE}"|g' \
            -e 's|WAIT_TIME=[0-9]*|WAIT_TIME=${IMAGE_DATA_PART_WAIT_TIME}|g' \
            -e 's|MOUNT_OPTION="[^"]*"|MOUNT_OPTION="${IMAGE_DATA_PART_MOUNT_OPTIONS}"|g' \
            ${D}${sysconfdir}/rc5.d/S03mount.data
    fi
}

# Package files conditionally
FILES:${PN} = "${@'${sysconfdir}/rc5.d/S03mount.data' \
                if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
                else ''}"

# This package is machine-specific due to device node configuration
PACKAGE_ARCH = "${MACHINE_ARCH}"

# Dependencies (e2fsprogs-mke2fs and util-linux-blkid for formatting/detection)
RDEPENDS:${PN} = "e2fsprogs-mke2fs e2fsprogs-resize2fs util-linux-blkid"

# Allow empty package if data partition is not configured
ALLOW_EMPTY:${PN} = "1"
