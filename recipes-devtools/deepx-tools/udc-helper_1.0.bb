SUMMARY = "UDC function helper script for Android ADB or Ethernet gadget"
DESCRIPTION = "Helper script for USB Device Controller (UDC) configuration with Android ADB or Ethernet gadget"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://udc_func.sh"

S = "${WORKDIR}"

RDEPENDS:${PN} = "android-tools-adbd"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/udc_func.sh ${D}${bindir}/
}

FILES:${PN} = "${bindir}/udc_func.sh"
