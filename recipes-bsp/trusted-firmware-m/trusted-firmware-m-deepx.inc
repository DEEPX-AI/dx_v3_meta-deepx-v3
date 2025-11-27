# SPDX-License-Identifier: MIT
#
# Copyright (c) 2025 deepx.ai
#
# Base configuration for Trusted Firmware-M (TF-M)
# This file contains common configuration shared across all TF-M recipes.
# It sets up basic metadata, compatibility, build environment, and dependencies
# but does not include version-specific or signing-related functionality.

SUMMARY = "Trusted Firmware for Cortex-M"
DESCRIPTION = "Trusted Firmware-M"
HOMEPAGE = "https://git.trustedfirmware.org/trusted-firmware-m.git"
LICENSE = "BSD-2-Clause & BSD-3-Clause & Apache-2.0"
PROVIDES = "tfm"

# Compatible only with DEEPX V3 machines
COMPATIBLE_MACHINE = "^v3-.*"
PACKAGE_ARCH = "${MACHINE_ARCH}"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

# Upstream version checking pattern
UPSTREAM_CHECK_GITTAGREGEX = "^TF-Mv(?P<pver>\d+(\.\d+)+)$"

# Note to future readers of this recipe: until the CMakeLists don't abuse
# installation (see do_install) there is no point in trying to inherit
# cmake here. You can easily short-circuit the toolchain but the install
# is so convoluted there's no gain.
inherit python3native deploy

# Baremetal firmware - inhibit default toolchain dependencies
INHIBIT_DEFAULT_DEPS = "1"

DEPENDS += "cmake-native \
            ninja-native \
            python3-jinja2-native \
			python3-pyyaml-native"

# Prevent host toolchain variables from interfering with cross-compilation
AS[unexport] = "1"
CC[unexport] = "1"
LD[unexport] = "1"

# CVE tracking product identifier
CVE_PRODUCT = "arm:trusted_firmware-m"
