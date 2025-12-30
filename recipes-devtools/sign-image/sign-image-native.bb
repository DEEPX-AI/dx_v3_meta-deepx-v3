# Recipe for DEEPX V3 boot image signing tool (native version)
#
# This recipe builds and installs the signing tool that will be used by
# other recipes (U-Boot, TF-A, TF-M) to sign their boot images.
# Copyright (C) 2025 deepx.ai. or its subsidiaries

SUMMARY = "DEEPX V3 signing image tool"
HOMEPAGE = "https://deepx.ai/"
LICENSE = "CLOSED"

PROVIDES = "sign-image"

SRC_URI = "git://git@gh.deepx.ai/deepx/dx_v3_linux_tool_sign_image;protocol=ssh;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

# Inherit the signing class and native class for host-side build
inherit native
require classes/sign-image-common.inc

# Add pseudo-native dependency for fakeroot support
DEPENDS = "pseudo-native"

fakeroot do_install() {
    # Create the installation directory for the signing tool
    install -d ${D}${SIGN_BOOT_IMAGE_INSTALL_DIR}

    # Copy all source files preserving directory structure
    # Use cp -r to maintain the original directory structure
    cp -r "${S}"/* "${D}${SIGN_BOOT_IMAGE_INSTALL_DIR}/"

    bbnote "Signing tool installation completed successfully"
}
