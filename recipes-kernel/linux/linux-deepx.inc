# Kernel configuration and dts specific information

DESCRIPTION = "Linux Kernel"

COMPATIBLE_MACHINE = "^v3-.*"

require recipes-kernel/linux/linux-yocto.inc

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

ARCH = "arm64"
LINUX_VERSION ?= "${PV}"

KCONFIG_MODE = "--alldefconfig"

# Create symbolic link for device tree binary : linux.dtb -> DTB file
do_deploy:append() {
    bbnote "do_deploy_append: Creating symbolic link linux.dtb -> DTB"
    if [ -n "${KERNEL_DEVICETREE}" ]; then
        # Extract DTB filename from KERNEL_DEVICETREE (remove directory path)
        dtb=$(basename "${KERNEL_DEVICETREE}")

        # Check if the DTB file exists in the deploy directory
        if [ -f "${DEPLOYDIR}/${dtb}" ]; then
            # Remove existing linux.dtb if it exists
            rm -f "${DEPLOYDIR}/linux.dtb"

            # Create symbolic link from linux.dtb to DTB file
            if ! ln -s "${dtb}" "${DEPLOYDIR}/linux.dtb"; then
                bbfatal "Failed to create symbolic link linux.dtb -> ${dtb} in ${DEPLOYDIR}"
            fi
            bbnote "Created symbolic link linux.dtb -> ${dtb} in ${DEPLOYDIR}"
        else
            bbwarn "Device tree file ${dtb} not found in ${DEPLOYDIR}/"
        fi
    fi
}
