# Common src definitions for trusted-firmware-a

require trusted-firmware-a-deepx_${PV}.inc

SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_trusted-firmware-a;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

LIC_FILES_CHKSUM += "file://docs/license.rst;md5=b2c740efedc159745b9b31f88ff03dde"
