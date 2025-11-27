# Copyright (C) 2020 Texas Instruments Inc.
# Released under the MIT license (see COPYING.MIT for the terms)

require arm-binary-toolchain.inc

COMPATIBLE_HOST = "(x86_64).*-linux"

SUMMARY = "Arm GNU Toolchain - AArch64 bare-metal target (aarch64-none-elf)"
HOMEPAGE = "https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
LICENSE = "GPL-3.0-with-GCC-exception & GPL-3.0-only"

LIC_FILES_CHKSUM = "file://share/doc/gcc/Copying.html;md5=2a62a4d37ddad55da732679acd9edf03"

HOST_ARCH = "$(uname -m)"
SRC_URI = "git://git@github.com/DEEPX-AI/dx_toolchains;protocol=ssh;branch=arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
