# Copyright (C) 2019 Garmin Ltd. or its subsidiaries
# Released under the MIT license (see COPYING.MIT for the terms)

require arm-binary-toolchain.inc

COMPATIBLE_HOST = "(x86_64).*-linux"

SUMMARY = "Arm GNU Toolchain - AArch32 bare-metal target (arm-none-eabi)"
HOMEPAGE = "https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
LICENSE = "GPL-3.0-with-GCC-exception & GPL-3.0-only"

LIC_FILES_CHKSUM = "file://share/doc/gcc/Copying.html;md5=1f07179249795891179bb3798bac7887"

PROVIDES = "virtual/arm-none-eabi-gcc"

HOST_ARCH = "$(uname -m)"
SRC_URI = "git://git@gh.deepx.ai/deepx/dx_v3_toolchains;protocol=ssh;branch=gcc-arm-11.2-2022.02-x86_64-arm-none-eabi"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
