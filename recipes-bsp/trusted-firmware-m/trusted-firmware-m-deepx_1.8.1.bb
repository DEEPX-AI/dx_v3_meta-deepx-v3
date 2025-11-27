# DEEPX V3 Trusted Firmware-M Recipe - Version 1.8.1
#
# This is the main recipe file that pulls source code and delegates
# configuration to the .inc file. It provides source repository information
# for the DEEPX V3 specific TF-M implementation.

require trusted-firmware-m-deepx_${PV}.inc

LIC_FILES_CHKSUM = "file://license.rst;md5=07f368487da347f3c7bd0fc3085f3afa"

SRC_URI = "git://git@gh.deepx.ai/deepx/rt_v3_trusted-firmware-m;protocol=ssh;branch=main"
SRCREV = "${AUTOREV}"
