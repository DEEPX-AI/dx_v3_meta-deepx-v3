# Common configure definitions for trusted-firmware-a

require trusted-firmware-a-deepx.inc
inherit sign_image_native

# What to build
# By default we only build bl1, do_deploy will copy
# everything listed in this variable (by default bl1.bin)
TFA_BUILD_TARGET ?= "bl31"

# Platform must be set for each machine
TFA_PLATFORM ?= "v3"

# Some platforms can have multiple board configurations
# Leave empty for default behavior
TFA_BOARD ?= ""

# Build for debug (set TFA_DEBUG to 1 to activate)
TFA_DEBUG ?= "0"

# debug log level (NONE(0), ERROR(10), NOTICE(20), WARNING(30), INFO(40), VERBOSE(50))
TFA_LOG_LEVEL ?= "40"

# What to install
# do_install and do_deploy will install everything listed in this
# variable. It is set by default to TFA_BUILD_TARGET
TFA_INSTALL_TARGET ?= "${TFA_BUILD_TARGET}"

# Image load address and secure keys path
TFA_BL31_LOAD_ADDRESS ?= "0x80200000"
TFA_BOOT_KEY_PATH ??= "${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_BOOT_KEY_DIR}"
TFA_USER_KEY_PATH ??= "${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_USER_KEY_DIR}"

# No configure
do_configure[noexec] = "1"

# Baremetal, just need a compiler
DEPENDS:remove = "virtual/${TARGET_PREFIX}compilerlibs virtual/libc"

# CC and LD introduce arguments which conflict with those otherwise provided by
# this recipe. The heads of these variables excluding those arguments
# are therefore used instead.
def remove_options_tail (in_string):
    from itertools import takewhile
    return ' '.join(takewhile(lambda x: not x.startswith('-'), in_string.split(' ')))

EXTRA_OEMAKE += "LD=${@remove_options_tail(d.getVar('LD'))}"

EXTRA_OEMAKE += "CC=${@remove_options_tail(d.getVar('CC'))}"

# Verbose builds, no -Werror
EXTRA_OEMAKE += "V=1 E=0"

# Add platform parameter
EXTRA_OEMAKE += "BUILD_BASE=${B} PLAT=${TFA_PLATFORM}"

# Handle TFA_BOARD parameter
EXTRA_OEMAKE += "${@'TARGET_PLATFORM=${TFA_BOARD}' if d.getVar('TFA_BOARD') else ''}"

# Handle TFA_DEBUG parameter
EXTRA_OEMAKE += "${@bb.utils.contains('TFA_DEBUG', '1', 'DEBUG=${TFA_DEBUG}', '', d)}"

# Handle TFA_LOG_LEVEL parameter
EXTRA_OEMAKE += "LOG_LEVEL=${TFA_LOG_LEVEL}"

# Use the correct native compiler
EXTRA_OEMAKE += "HOSTCC='${BUILD_CC}'"

# Runtime variables
EXTRA_OEMAKE += "RUNTIME_SYSROOT=${STAGING_DIR_HOST}"

BUILD_DIR = "${B}/${TFA_PLATFORM}"
BUILD_DIR .= "${@'/${TFA_BOARD}' if d.getVar('TFA_BOARD') else ''}"
BUILD_DIR .= "/${@'debug' if d.getVar("TFA_DEBUG") == '1' else 'release'}"

do_compile() {
    # This is still needed to have the native tools executing properly by
    # setting the RPATH
    sed -i '/^LDLIBS/ s,$, \$\{BUILD_LDFLAGS},' ${S}/tools/fiptool/Makefile
    sed -i '/^INCLUDE_PATHS/ s,$, \$\{BUILD_CFLAGS},' ${S}/tools/fiptool/Makefile
    sed -i '/^LIB/ s,$, \$\{BUILD_LDFLAGS},' ${S}/tools/cert_create/Makefile

    # Currently there are races if you build all the targets at once in parallel
    for T in ${TFA_BUILD_TARGET}; do
        oe_runmake -C ${S} $T
    done
}
do_compile[cleandirs] = "${B}"

do_install() {
    install -d -m 755 ${D}/firmware
    for bin in ${TFA_INSTALL_TARGET}; do
        processed="0"
        if [ "$bin" = "all" ]; then
            # Target all is not handled by default
            bberror "all as TFA_INSTALL_TARGET is not handled by do_install"
            bberror "Please specify valid targets in TFA_INSTALL_TARGET or"
            bberror "rewrite or turn off do_install"
            exit 1
        fi

        if [ -f ${BUILD_DIR}/$bin.bin ]; then
            echo "Install $bin.bin"
            install ${BUILD_DIR}/$bin.bin ${D}/firmware/$bin.bin
            processed="1"
        fi
        if [ -f ${BUILD_DIR}/$bin/$bin.elf ]; then
            echo "Install $bin.elf"
            install ${BUILD_DIR}/$bin/$bin.elf ${D}/firmware/$bin.elf
            processed="1"
        fi
        if [ -f ${BUILD_DIR}/$bin ]; then
            echo "Install $bin"
            install ${BUILD_DIR}/$bin ${D}/firmware/$bin
            processed="1"
        fi
        if [ -f ${BUILD_DIR}/fdts/$bin.dtb ]; then
            echo "Install $bin.dtb"
            install "${BUILD_DIR}/fdts/$bin.dtb" "${D}/firmware/$bin.dtb"
            processed="1"
        elif [ "$bin" = "dtbs" ]; then
            echo "dtbs install, skipped: set dtbs in TFA_INSTALL_TARGET"
        elif [ -f ${B}/tools/$bin/$bin ]; then
            echo "Tools $bin install, skipped"
        elif [ "$processed" = "0" ]; then
            bberror "Unsupported TFA_INSTALL_TARGET target $bin"
            exit 1
        fi
    done
}

FILES:${PN} = "/firmware"
SYSROOT_DIRS += "/firmware"

FILES:${PN}-dbg = "/firmware/*.elf"
# Skip QA check for relocations in .text of elf binaries
INSANE_SKIP:${PN}-dbg += "textrel"
# Build paths are currently embedded
INSANE_SKIP:${PN} += "buildpaths"
INSANE_SKIP:${PN}-dbg += "buildpaths"

do_deploy() {
    cp -rf ${D}/firmware/* ${DEPLOYDIR}/
}
addtask deploy after do_sign_image

fakeroot do_sign_image() {
    dstdir="${D}/firmware"
    for bin in ${TFA_INSTALL_TARGET}; do
        case $bin in
            'bl31')
            image_type="4" # BL31=4, BL31_1=5 (BL32=6)
            load_addr=${TFA_BL31_LOAD_ADDRESS}
            input_image="$dstdir/$bin.bin"

            echo "Generate image for ${bin} with boot header"
            if ! sign_image \
                    "--input_file" "$input_image" \
                    "--output_dir" "$dstdir" \
                    "--image_type" "$image_type" \
                    "--load_address" "$load_addr"; then
                bbfatal "Failed to generate $bin image"
            fi

            echo "Generate signed image  with cryptographic signature for ${bin}"
            if ! sign_image \
                    "--signing" "content" \
                    "--input_file" "$input_image" \
                    "--output_dir" "$dstdir" \
                    "--image_type" "$image_type" \
                    "--load_address" "$load_addr" \
                    "--crc_disable" \
                    "--content_pem" "${TFA_BOOT_KEY_PATH}/user_key.pem" \
                    "--content_pub" "${TFA_BOOT_KEY_PATH}/user_key.pub" \
                    "--content_pwd" "${TFA_BOOT_KEY_PATH}/user_key.pwd"; then
                bbfatal "Failed to generate signed $bin image"
            fi
            ;;
        *);;
        esac
    done
}
