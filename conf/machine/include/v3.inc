require conf/machine/include/arm/armv8a/tune-cortexa53.inc

MACHINEOVERRIDES =. "v3:"

#
# TF-M
#
TFM_PLATFORM = "deepx/v3"
TFM_DEBUG ?= "0"

# refer to trusted-firmware-m-v3_1.8.1.inc
TFM_BUILD_TARGET ?= "bl2_binaries bl2_image_bin bl2_signed_bin \
               ddrfw_image_bin ddrfw_signed_bin \
               tfm_s_binaries tfm_s_image_bin tfm_s_signed_bin"

# 6400, 3700
TFM_DDR_MTS ?= "6400"

# BL2 LOG: OFF(0), ERROR(1), WARNING(2), INFO(3), VERBOSE(4), DEBUG(5)
# TFM_S LOG: SILENCE(0), ERR(1), INFO(2), DEBUG(3)
TFM_BL2_LOG_LEVEL ?= "4"
TFM_SECURE_LOG_LEVEL ?= "2"

EXTRA_IMAGEDEPENDS += "tfm"

#
# TF-A
#
TFA_PLATFORM = "v3"
TFA_BUILD_TARGET = "bl31"
TFA_BOARD ?= ""
TFA_DEBUG ?= "0"
TFA_LOG_LEVEL ?= "40"
EXTRA_IMAGEDEPENDS += "tfa"

#
# u-boot
#
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-deepx"
PREFERRED_VERSION_u-boot-deepx ?= "2023.10%"
EXTRA_IMAGEDEPENDS += "u-boot-deepx"

#
# Linux kernel
#
PREFERRED_PROVIDER_virtual/kernel:forcevariable = "linux-deepx"
PREFERRED_VERSION_linux-deepx ?= "6.6.8%"
KERNEL_IMAGETYPE ?= "Image"

# prevent the kernel image from being included in the intramfs rootfs
PACKAGE_EXCLUDE = "kernel-image-*"
