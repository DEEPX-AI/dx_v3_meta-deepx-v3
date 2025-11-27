# BitBake class for boot image signing functionality (consumer side)
#
# This class provides infrastructure for signing boot images (U-Boot, TF-A, TF-M, etc.)
# using the signing tool from sign-image-native recipe.

inherit python3native
require sign-image-common.inc

DEPENDS += "sign-image-native"

SSTATETASKS += "do_sign_image"

sign_image_native_do_sign_image() {
    # No-op by default - recipes must implement their own signing logic
    :
}

# Task runs after installation but before deployment to avoid packaging contamination
addtask sign_image after do_install before do_deploy
EXPORT_FUNCTIONS do_sign_image

# sstate setscene function for cache restore
python do_sign_image_setscene () {
    sstate_setscene(d)
}
addtask do_sign_image_setscene

sign_image() {
    local sign_tool="${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_INSTALL_DIR}/sign_image.py"

    # Execute signing with proper error handling
    bbnote "Executing signing tool: ${PYTHON} $sign_tool $*"
    if ! "${PYTHON}" "$sign_tool" "$@"; then
        bbfatal "Signing operation failed with exit code $?"
        return 1
    fi

    bbnote "Signing completed successfully"
    return 0
}
