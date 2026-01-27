# Kernel configuration and dts specific information

require linux-deepx.inc

# locense QA checksum, to skip INSANE_SKIP:${PN} += "license-checksum"
LIC_FILES_CHKSUM = "file://${S}/COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

# Skip buildpaths QA check for debug source files
INSANE_SKIP:${PN}-src += "buildpaths"

# Disable debug package creation to avoid buildpath issues
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# Skip Version sanity
# KERNEL_VERSION_SANITY_SKIP = "1"

SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_linux-kernel;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

KERNEL_EXTRA_ARGS += "CONFIG_INITRAMFS_COMPRESSION_NONE=y"
KERNEL_EXTRA_FEATURES = ""
KERNEL_FEATURES = ""
