SUMMARY = "DEEPX V3 ISP Kernel Module Driver"
DESCRIPTION = "ISP kernel module driver for DEEPX V3 platform"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

COMPATIBLE_MACHINE = "^v3-.*"
inherit module

# Source repository
SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_isp_vsi_driver.git;protocol=ssh;branch=main"
SRC_URI:append = " file://bin"
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

# Package kernel modules and binaries
# Note: Even with usrmerge, kernel modules are installed to /lib/modules by default
FILES:${PN} += "${bindir}/*"
FILES:${PN} += "/lib/modules/${KERNEL_VERSION}/updates/*.ko"
FILES:${PN} += "${nonarch_base_libdir}/modules/${KERNEL_VERSION}/updates/*.ko"

# Include modprobe.d files only for systemd
FILES:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', \
                '${sysconfdir}/modprobe.d/*.conf', '', d)}"

# Skip usrmerge check for kernel modules (they are always in /lib/modules)
INSANE_SKIP:${PN} += "usrmerge"
INSANE_SKIP:${PN}-dbg += "usrmerge"

# Provide individual kernel module packages to satisfy dependencies
# This tells the packaging system that this package provides all the kernel modules
RPROVIDES:${PN} += "kernel-module-vsensor-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-i2c-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-isp-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-isp-subdev-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-mipi-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-vb-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-vi-${KERNEL_VERSION}"
RPROVIDES:${PN} += "kernel-module-vvcam-video-${KERNEL_VERSION}"

# ISP VSI build configuration
ISP_VSI_VERSION = "ISP8000L_V2407"
ISP_VSI_VI200_VERSION = "VI200_V2"
ISP_VSI_V4L2 = "1"
ISP_VSI_DEEPX_V3_VSENSOR = "1"

# Skip QA checks for proprietary drivers
INSANE_SKIP += "buildpaths"

# Use ${MAKE} directly to avoid unwanted build options from oe_runmake
do_compile() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
    cd ${S}
    ${MAKE} \
        ARCH=${ARCH} \
        CROSS_COMPILE=${TARGET_PREFIX} \
        KERNEL=${STAGING_KERNEL_BUILDDIR} \
        ISP_VERSION=${ISP_VSI_VERSION} \
        VI200_VERSION=${ISP_VSI_VI200_VERSION} \
        V4L2=${ISP_VSI_V4L2} \
        DEEPX_V3_VSENSOR=${ISP_VSI_DEEPX_V3_VSENSOR} \
        LOCALVERSION=${KERNEL_VERSION} \
        all
}

do_install() {
    cd ${S}
    ${MAKE} \
        KERNEL=${STAGING_KERNEL_BUILDDIR} \
        INSTALL_MOD_PATH=${D} \
        ISP_VERSION=${ISP_VSI_VERSION} \
        VI200_VERSION=${ISP_VSI_VI200_VERSION} \
        V4L2=${ISP_VSI_V4L2} \
        DEEPX_V3_VSENSOR=${ISP_VSI_DEEPX_V3_VSENSOR} \
        modules_install
}

do_install:append() {
    # Install ISP module management script (usrmerge: use ${bindir})
    install -d ${D}${bindir}
    if [ -d "${WORKDIR}/bin" ]; then
        install -m 0755 "${WORKDIR}/bin"/* ${D}${bindir}/
    fi

    # Update MODULE_DIR to use current kernel version (usrmerge: use ${nonarch_base_libdir})
    if [ -f "${D}${bindir}/isp_module.sh" ]; then
        sed -i "s|MODULE_DIR=\"/lib/modules/[^\"]*\"|MODULE_DIR=\"${nonarch_base_libdir}/modules/${KERNEL_VERSION}/updates\"|g" \
            "${D}${bindir}/isp_module.sh"
    fi
}

# Create modprobe.d configuration to blacklist all vvcam modules (systemd only)
do_install:append:class-target() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        bbnote "Creating modprobe.d blacklist for vvcam modules (systemd init manager)"
        install -d ${D}${sysconfdir}/modprobe.d
        for module in vsensor vvcam_i2c vvcam_isp vvcam_isp_subdev vvcam_mipi vvcam_vb vvcam_vi vvcam_video; do
            echo "blacklist ${module}" > ${D}${sysconfdir}/modprobe.d/${module}.conf
        done
    else
        bbnote "Skipping modprobe.d blacklist (non-systemd init manager)"
    fi
}
