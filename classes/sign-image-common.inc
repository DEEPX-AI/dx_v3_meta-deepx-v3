# Common configuration for boot image signing infrastructure
#
# This file defines shared variables used across all boot image signing
# recipes and classes in the DEEPX V3 platform.

# Directory where the signing tool is installed
SIGN_BOOT_IMAGE_INSTALL_DIR = "${libexecdir}/sign-image"

# Default key management paths
SIGN_BOOT_IMAGE_KEY_DIR ??= "${SIGN_BOOT_IMAGE_INSTALL_DIR}/sample_keys"
SIGN_BOOT_IMAGE_BOOT_KEY_DIR ??= "${SIGN_BOOT_IMAGE_KEY_DIR}"
SIGN_BOOT_IMAGE_USER_KEY_DIR ??= "${SIGN_BOOT_IMAGE_KEY_DIR}"
