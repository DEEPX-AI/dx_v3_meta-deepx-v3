# DEEPX V3 Trusted Firmware-M Recipe - Version 1.8.1
#
# This is the main recipe file that pulls source code and delegates
# configuration to the .inc file. It provides source repository information
# for the DEEPX V3 specific TF-M implementation.

require trusted-firmware-m-deepx_${PV}.inc

LIC_FILES_CHKSUM = "file://license.rst;md5=07f368487da347f3c7bd0fc3085f3afa"

DEPENDS = "gcc-arm-none-eabi-native ninja-native python3-jinja2-native python3-pyyaml-native sign-image-native"

SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_trusted-firmware-m;protocol=ssh;branch=main"
SRCREV = "${AUTOREV}"
