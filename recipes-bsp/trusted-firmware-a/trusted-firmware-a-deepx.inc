# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 deepx.ai
#

SUMMARY = "Trusted Firmware for Cortex-A"
DESCRIPTION = "Trusted Firmware-A"
HOMEPAGE = "https://github.com/TrustedFirmware-A/trusted-firmware-a"
LICENSE = "BSD-3-Clause & MIT"
PROVIDES = "tfa"

COMPATIBLE_MACHINE = "^v3-.*"
PACKAGE_ARCH = "${MACHINE_ARCH}"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

UPSTREAM_CHECK_GITTAGREGEX = "^v(?P<pver>\d+(\.\d+)+)$"

inherit deploy

# Requires CROSS_COMPILE set by hand as there is no configure script
export CROSS_COMPILE="${TARGET_PREFIX}"

# Let the Makefile handle setting up the CFLAGS and LDFLAGS as it is a standalone application
CFLAGS[unexport] = "1"
LDFLAGS[unexport] = "1"
AS[unexport] = "1"
LD[unexport] = "1"

# No configure
do_configure[noexec] = "1"

# Baremetal, just need a compiler
DEPENDS:remove = "virtual/${TARGET_PREFIX}compilerlibs virtual/libc"

# We need dtc for dtbs compilation
# We need openssl for fiptool
# DEPENDS = "dtc-native openssl-native"
# DEPENDS:append:toolchain-clang = " compiler-rt"

CVE_PRODUCT = "arm:trusted_firmware-a"
