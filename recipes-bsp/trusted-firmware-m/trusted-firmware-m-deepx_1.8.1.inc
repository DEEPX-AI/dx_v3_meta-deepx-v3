# DEEPX V3 Trusted Firmware-M Version 1.8.1 Configuration
#
# This file contains version-specific configuration for TF-M 1.8.1,
# including build parameters, signing configuration, and CMake options
# specific to the DEEPX V3 platform implementation.

require trusted-firmware-m-deepx.inc
inherit sign_image_native

DEPENDS += "gcc-arm-none-eabi-v3-native"

# Debug build configuration (set TFM_DEBUG to 1 to activate)
TFM_DEBUG ?= "0"

# Build targets for TF-M components
# bl2: Boot Loader stage 2 (MCUboot)
# tfm_s: TF-M Secure world firmware
# ddrfw: DDR firmware for memory initialization
TFM_BUILD_TARGET ?= "bl2_binaries bl2_image_bin bl2_signed_bin \
               ddrfw_image_bin ddrfw_signed_bin \
               tfm_s_binaries tfm_s_image_bin tfm_s_signed_bin"

# Logging level configuration
# TFM_BL2_LOG_LEVEL: Boot loader log levels
#   OFF(0), ERROR(1), WARNING(2), INFO(3), VERBOSE(4), DEBUG(5)
# TFM_SECURE_LOG_LEVEL: Secure partition log levels
#   SILENCE(0), ERR(1), INFO(2), DEBUG(3)
TFM_BL2_LOG_LEVEL ?= "4"
TFM_SECURE_LOG_LEVEL ?= "2"

# DDR Memory Timing Set configuration
# Available options: 6400, 3700 (MT/s - Mega Transfers per second)
TFM_DDR_MTS ?= "6400"

# Enhanced cryptographic key management for secure boot, Default development key paths
TFM_SIGN_BOOT_KEY_PATH = "${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_BOOT_KEY_DIR}"
TFM_SIGN_USER_KEY_PATH = "${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_USER_KEY_DIR}"

# Production key paths (set in machine configuration for better security)
TFM_PRODUCTION_BOOT_KEY_PATH ??= ""
TFM_PRODUCTION_USER_KEY_PATH ??= ""

# Use production keys if specified, otherwise fall back to development keys
TFM_EFFECTIVE_BOOT_KEY_PATH = "${@d.getVar('TFM_PRODUCTION_BOOT_KEY_PATH') or d.getVar('TFM_SIGN_BOOT_KEY_PATH')}"
TFM_EFFECTIVE_USER_KEY_PATH = "${@d.getVar('TFM_PRODUCTION_USER_KEY_PATH') or d.getVar('TFM_SIGN_USER_KEY_PATH')}"

# Platform validation - must be set by machine configuration
TFM_PLATFORM ?= ""
python() {
    # Ensure TFM_PLATFORM is defined, otherwise skip this recipe
    if not d.getVar("TFM_PLATFORM"):
        raise bb.parse.SkipRecipe("TFM_PLATFORM needs to be set")
}

# Package configuration options
PACKAGECONFIG ??= ""

# Test suite integration options
PACKAGECONFIG[test-secure] = "-DTEST_S=ON,-DTEST_S=OFF"
PACKAGECONFIG[test-nonsecure] = "-DTEST_NS=ON,-DTEST_NS=OFF"

# Toolchain configuration - use ARM GNU toolchain
# Currently we only support using the Arm binary GCC
EXTRA_OECMAKE += "-DTFM_TOOLCHAIN_FILE=${S}/toolchain_GNUARM.cmake"

# Prevent FetchContent from downloading additional sources during configuration
# Don't let FetchContent download more sources during do_configure
EXTRA_OECMAKE += "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"

# Platform-specific CMake parameter
EXTRA_OECMAKE += "-DTFM_PLATFORM=${TFM_PLATFORM}"

# Debug/Release build type based on TFM_DEBUG setting
EXTRA_OECMAKE += "${@bb.utils.contains('TFM_DEBUG', '1', '-DCMAKE_BUILD_TYPE=Debug', '-DCMAKE_BUILD_TYPE=Release', d)}"

# Enable verbose build output for debugging
EXTRA_OECMAKE += "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"

# Logging configuration for different components
EXTRA_OECMAKE += "-DMCUBOOT_LOG_LEVEL=OFF -DPLAT_LOG_LEVEL=${TFM_BL2_LOG_LEVEL} -DTFM_PARTITION_LOG_LEVEL=${TFM_SECURE_LOG_LEVEL}"

# DEEPX V3 specific DDR memory configuration
EXTRA_OECMAKE += "-DV3_DDR_TARGET_MTS=${TFM_DDR_MTS}"

# Path to external signing and image processing tools
EXTRA_OECMAKE += "-DPLATFORM_IMAGE_TOOL_PATH=${RECIPE_SYSROOT_NATIVE}${SIGN_BOOT_IMAGE_INSTALL_DIR}"

# Cryptographic key paths for secure boot chain
# Use effective paths that consider production vs development keys
EXTRA_OECMAKE += "-DPLATFORM_BOOT_KEYS_PATH=${TFM_EFFECTIVE_BOOT_KEY_PATH}"
EXTRA_OECMAKE += "-DPLATFORM_USER_KEYS_PATH=${TFM_EFFECTIVE_USER_KEY_PATH}"

# Enable parallel build processing
export CMAKE_BUILD_PARALLEL_LEVEL = "${@oe.utils.parallel_make(d, False)}"

# Temporary workaround for older GCC compatibility
# remove once arm-none-eabi-gcc updates to 13 or newer like poky
DEBUG_PREFIX_MAP:remove = "-fcanon-prefix-map"

# Configuration task - clean build directory and run CMake
do_configure[cleandirs] = "${B}"
do_configure() {
    cmake -GNinja -S ${S} -B ${B} ${EXTRA_OECMAKE} ${PACKAGECONFIG_CONFARGS}
}

do_compile() {
	# Skip compilation if no build targets are specified
	if [ -z "${TFM_BUILD_TARGET}" ]; then
        return
    fi
    cmake --build ${B} -t ${TFM_BUILD_TARGET}
}
# Progress indicator for build process
do_compile[progress] = "outof:^\[(\d+)/(\d+)\]\s+"

# Installation task - install firmware binaries to target image
fakeroot do_install() {
    bootfw_dir="${S}/platform/ext/target/${TFM_PLATFORM}/fw/ddr_${TFM_DDR_MTS}"

    if ! install -d -m 755 "${D}/firmware"; then
        bbfatal "Firmware directory not found: ${D}/firmware"
    fi

    install -m 0644 ${B}/bin/* ${D}/firmware/
    if [ -z "$(ls -A "${D}/firmware" 2>/dev/null)" ]; then
        bbwarn "Firmware directory is empty: ${D}/firmware"
    fi

    # install ddr firmware
    if ! install -m 0644 ${bootfw_dir}/* ${D}/firmware/; then
        bbfatal "Failed to install DDR firmware files from ${bootfw_dir}"
    fi
}

# Package file specifications
FILES:${PN} = "/firmware"
SYSROOT_DIRS += "/firmware"
FILES:${PN}-dbg = "/firmware/*.elf"

do_deploy() {
    bbnote "Starting TF-M firmware deployment process"

    # Use install command instead of cp for better control
    find "${D}/firmware" -type f | while read -r file; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            if install -m 0644 "$file" "${DEPLOYDIR}/$basename_file"; then
                bbnote "Deployed firmware file: $basename_file"
            else
                bbwarn "Failed to deploy firmware file: $basename_file"
            fi
        fi
    done

    bbnote "TF-M firmware deployment process completed"
}
# Deployment task - copy firmware to deployment directory
addtask deploy after do_install

# QA check skip configurations for embedded firmware
# Build paths are currently embedded because it's impossible to pass -fdebug-prefix-map
INSANE_SKIP:${PN} += "buildpaths"
INSANE_SKIP:${PN}-dbg += "buildpaths"
# Target binaries will be 32-bit Arm (different from host architecture)
INSANE_SKIP:${PN} += "arch"
INSANE_SKIP:${PN}-dbg += "arch"
