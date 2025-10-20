SUMMARY = "systemd data partition mount service"
DESCRIPTION = "Provides systemd mount unit for automatic data partition detection, \
               formatting, and mounting at /data directory."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Data partition configuration
IMAGE_DATA_PART_DEVICE_NODE ??= ""
IMAGE_DATA_PART_WAIT_TIME ??= "120"
IMAGE_DATA_PART_MOUNT_OPTIONS ??= "defaults,noatime,nofail"

# Unit names
UNIT_DATA_PART_FORMAT = "data-partition-format.service"
UNIT_DATA_PART_MOUNT = "data.mount"

# Inherit systemd class for service management
inherit systemd

# Conditionally add mount and format unit sources
SRC_URI = "${@'file://${UNIT_DATA_PART_MOUNT}.in file://${UNIT_DATA_PART_FORMAT}.in' \
            if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
            else ''}"

S = "${WORKDIR}"

do_install() {
    # Install data partition mount units
    if [ -n "${IMAGE_DATA_PART_DEVICE_NODE}" ]; then
        install -d ${D}${systemd_system_unitdir}

        # Install format service
        sed -e 's|@IMAGE_DATA_PART_DEVICE_NODE@|${IMAGE_DATA_PART_DEVICE_NODE}|g' \
            -e 's|@IMAGE_DATA_PART_WAIT_TIME@|${IMAGE_DATA_PART_WAIT_TIME}|g' \
            ${WORKDIR}/${UNIT_DATA_PART_FORMAT}.in \
            > ${D}${systemd_system_unitdir}/${UNIT_DATA_PART_FORMAT}

        # Install mount unit with format service dependency
        sed -e 's|@IMAGE_DATA_PART_DEVICE_NODE@|${IMAGE_DATA_PART_DEVICE_NODE}|g' \
            -e 's|@IMAGE_DATA_PART_MOUNT_OPTIONS@|${IMAGE_DATA_PART_MOUNT_OPTIONS}|g' \
            -e 's|@PREPARE_DEPENDENCY@|After=${UNIT_DATA_PART_FORMAT}\nWants=${UNIT_DATA_PART_FORMAT}|g' \
            ${WORKDIR}/${UNIT_DATA_PART_MOUNT}.in \
            > ${D}${systemd_system_unitdir}/${UNIT_DATA_PART_MOUNT}
    fi
}

# Package files conditionally
FILES:${PN} = "${@'${systemd_system_unitdir}/${UNIT_DATA_PART_MOUNT} ${systemd_system_unitdir}/${UNIT_DATA_PART_FORMAT}' \
                if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
                else ''}"

# systemd service configuration
SYSTEMD_SERVICE:${PN} = "${@'${UNIT_DATA_PART_MOUNT} ${UNIT_DATA_PART_FORMAT}' \
                          if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
                          else ''}"

SYSTEMD_AUTO_ENABLE = "${@'enable' \
                        if d.getVar('IMAGE_DATA_PART_DEVICE_NODE') \
                        else 'disable'}"

# This package is machine-specific due to device node configuration
PACKAGE_ARCH = "${MACHINE_ARCH}"

# Dependencies (e2fsprogs-resize2fs added for partition resizing)
RDEPENDS:${PN} = "systemd e2fsprogs-mke2fs e2fsprogs-resize2fs util-linux-blkid"

# Allow empty package if data partition is not configured
ALLOW_EMPTY:${PN} = "1"
