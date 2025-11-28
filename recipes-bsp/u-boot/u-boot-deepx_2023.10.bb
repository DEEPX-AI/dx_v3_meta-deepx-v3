# u-boot configuration and dts specific information

require u-boot-deepx.inc

# locense QA checksum, to skip INSANE_SKIP:${PN} += "license-checksum"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_u-boot.git;protocol=ssh;branch=main"
SRCREV = "${AUTOREV}"
