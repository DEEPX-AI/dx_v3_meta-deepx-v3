# U-Boot configuration specific information for DEEPX V3

HOMEPAGE = "http://www.denx.de/wiki/U-Boot/WebHome"
DESCRIPTION = "Linux u-boot"
SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPL-2.0-or-later"

# This configuration is compatible with v3-* machine types
COMPATIBLE_MACHINE = "^v3-.*"

require recipes-bsp/u-boot/u-boot.inc
inherit sign_image_native

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

# Image load address and secure keys path configuration
UBOOT_LOAD_ADDRESS ?= "0x80400000"

# Key paths - can be overridden in machine configuration for better security
UBOOT_SIGN_KEY_PATH ??= "${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_USER_KEY_DIR}"

# Alternative key paths for production builds (set in machine conf or local.conf)
# Example: UBOOT_PRODUCTION_KEY_PATH = "/secure/keys/production"
UBOOT_PRODUCTION_KEY_PATH ??= ""

# Use production keys if specified, otherwise fall back to development keys
UBOOT_EFFECTIVE_KEY_PATH = "${@d.getVar('UBOOT_PRODUCTION_KEY_PATH') or d.getVar('UBOOT_SIGN_KEY_PATH')}"

# Custom defconfig task to set up U-Boot configuration
do_defconfig() {
    bbplain "Set defconfig '${UBOOT_MACHINE}' to:\n${B}"
    # UBOOT_MACHINE is the defconfig name
    oe_runmake -C ${B} ${UBOOT_MACHINE}
}

do_defconfig[nostamp] = "1"
addtask defconfig after do_configure

fakeroot do_sign_image() {
    local dstdir="${D}/boot"
    local input_image="${dstdir}/${UBOOT_IMAGE}"
    local image_type="7" # BL33=7 (Boot Loader Stage 3.3 for U-Boot)
    local load_addr="${UBOOT_LOAD_ADDRESS}"

    bbnote "Starting U-Boot image signing process"
    bbnote "Generating U-Boot image with boot header"
    if ! sign_image \
            "--input_file" "$input_image" \
            "--output_dir" "$dstdir" \
            "--image_type" "$image_type" \
            "--load_address" "$load_addr"; then
        bbfatal "Failed to generate U-Boot image"
    fi

    bbnote "Generating signed U-Boot image with cryptographic signature"
    if ! sign_image \
            "--signing" "content" \
            "--input_file" "$input_image" \
            "--output_dir" "$dstdir" \
            "--image_type" "$image_type" \
            "--load_address" "$load_addr" \
            "--crc_disable" \
            "--content_pem" "${UBOOT_EFFECTIVE_KEY_PATH}/user_key.pem" \
            "--content_pub" "${UBOOT_EFFECTIVE_KEY_PATH}/user_key.pub" \
            "--content_pwd" "${UBOOT_EFFECTIVE_KEY_PATH}/user_key.pwd"; then
        bbfatal "Failed to generate signed U-Boot image"
    fi

    bbnote "U-Boot image signing process completed"
}

# Extended installation to include ELF binary
do_install:append() {
    # Install u-boot ELF image for debugging purposes
    install -m 0644 "${B}/u-boot" "${D}/boot/u-boot-${MACHINE}-${PV}-${PR}.elf"
}

UBOOT_IMAGE_ELF_NAME = "u-boot"
UBOOT_IMAGE_NON_SIGNED_NAME = "u-boot.img"
UBOOT_IMAGE_SIGNED_NAME = "u-boot.sig"
UBOOT_IMAGE_ENV_NAME = "u-boot_env.bin"

do_deploy:append() {
    local dstdir="${D}/boot"
    local uboot="u-boot-${MACHINE}-${PV}-${PR}"
    local env="${UBOOT_INITIAL_ENV}-${MACHINE}-${PV}-${PR}"

    bbnote "Starting U-Boot deployment process"

    # Deploy ELF binary if available
    bbnote "Deploying ELF binary: ${uboot}.elf"
    install -m 0644 "${dstdir}/${uboot}.elf" "${DEPLOYDIR}/"

    rm -f "${DEPLOYDIR}/${UBOOT_IMAGE_ELF_NAME}"
    if ! ln -sf "${uboot}.elf" "${DEPLOYDIR}/${UBOOT_IMAGE_ELF_NAME}"; then
        bbfatal "Failed to create symbolic link for ELF binary"
    fi

    # Deploy and link image
    bbnote "Deploying image: ${uboot}.img"
    install -m 0644 "${dstdir}/${uboot}.img" "${DEPLOYDIR}/"

    rm -f "${DEPLOYDIR}/${UBOOT_IMAGE_NON_SIGNED_NAME}"
    if ! ln -sf "${uboot}.img" "${DEPLOYDIR}/${UBOOT_IMAGE_NON_SIGNED_NAME}"; then
        bbfatal "Failed to create symbolic link for image"
    fi

    # Deploy and link signature file
    bbnote "Deploying signature: ${uboot}.sig"
    install -m 0644 "${dstdir}/${uboot}.sig" "${DEPLOYDIR}/"

    rm -f "${DEPLOYDIR}/${UBOOT_IMAGE_SIGNED_NAME}"
    if ! ln -sf "${uboot}.sig" "${DEPLOYDIR}/${UBOOT_IMAGE_SIGNED_NAME}"; then
        bbwarn "Failed to create symbolic link for signature"
    fi

    # Deploy and link environment file
    bbnote "Deploying environment: ${env}"

    rm -f "${DEPLOYDIR}/${UBOOT_IMAGE_ENV_NAME}"
    if ! ln -sf "${env}" "${DEPLOYDIR}/${UBOOT_IMAGE_ENV_NAME}"; then
        bbwarn "Failed to create symbolic link for environment"
    fi

    bbnote "U-Boot deployment process completed"
}
