# DEEPX V3 Configuration Guide

Complete guide for configuring DEEPX V3 Yocto/OpenEmbedded BSP Layer.

## Table of Contents

- [DEEPX V3 Configuration Guide](#deepx-v3-configuration-guide)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Boot Sequence Overview](#boot-sequence-overview)
  - [Configuration Variables](#configuration-variables)
    - [1. TF-M (Trusted Firmware-M) Configuration - Boot Stage 1](#1-tf-m-trusted-firmware-m-configuration---boot-stage-1)
      - [Key File Requirements for TF-M](#key-file-requirements-for-tf-m)
      - [Security Notes](#security-notes)
    - [2. TF-A (Trusted Firmware-A) Configuration - Boot Stage 2](#2-tf-a-trusted-firmware-a-configuration---boot-stage-2)
      - [Key File Requirements for TF-A](#key-file-requirements-for-tf-a)
    - [3. U-Boot Configuration - Boot Stage 3](#3-u-boot-configuration---boot-stage-3)
      - [Key File Requirements for U-Boot](#key-file-requirements-for-u-boot)
    - [4. Kernel Configuration - Boot Stage 4](#4-kernel-configuration---boot-stage-4)
    - [5. Init System Configuration - Boot Stage 5](#5-init-system-configuration---boot-stage-5)
    - [6. User Account Configuration - User Space Setup](#6-user-account-configuration---user-space-setup)
    - [7. Data Partition Configuration - Storage Mount](#7-data-partition-configuration---storage-mount)
    - [8. Image Configuration - Build Output](#8-image-configuration---build-output)
      - [Standard Image (ext4/wic)](#standard-image-ext4wic)
      - [Initramfs Image Configuration](#initramfs-image-configuration)
    - [9. Package Management - Build System](#9-package-management---build-system)
  - [See Also](#see-also)

---

## Introduction

This layer provides various configurable variables that can be set in:
- `conf/machine/{MACHINE}.conf` - Machine-specific settings
- `local.conf` - User-specific build settings
- KAS YAML files - KAS build system configurations

The configuration sections are organized in **boot sequence order** from hardware initialization to user space.

---

## Boot Sequence Overview

```
Power On → TF-M BL2 → DDR Init → TF-M Secure → TF-A BL31 → U-Boot → Kernel → Init System → User Space
  Stage 1     (2)        (3)         (4)        Stage 2   Stage 3  Stage 4    Stage 5        (6-9)
```

**Boot Chain:**
1. **TF-M BL2** - Secure boot ROM, DDR initialization, image verification
2. **TF-M Secure** - Secure partition manager
3. **TF-A BL31** - ARM Trusted Firmware (EL3 runtime services)
4. **U-Boot** - Universal bootloader
5. **Linux Kernel** - Operating system kernel
6. **Init System** - systemd or busybox init
7. **User Space** - Applications and services

---

## Configuration Variables

### 1. TF-M (Trusted Firmware-M) Configuration - Boot Stage 1

TF-M BL2 is the first-stage bootloader that initializes secure environment and loads subsequent boot stages.

```bitbake
# TF-M Debug Mode
TFM_DEBUG ?= "0"           # 0: Release, 1: Debug

# DDR Memory Speed (MTS)
TFM_DDR_MTS ?= "6400"      # Options: 6400, 3700

# Log Levels
TFM_BL2_LOG_LEVEL ?= "4"   # BL2: 0:OFF, 1:ERROR, 2:WARNING, 3:INFO, 4:VERBOSE, 5:DEBUG
TFM_SECURE_LOG_LEVEL ?= "2" # TFM_S: 0:SILENCE, 1:ERR, 2:INFO, 3:DEBUG

# Production Boot Keys (REQUIRED FOR PRODUCTION)
# Boot key: for signing BL2, DDR FW, TF-M Secure images
TFM_PRODUCTION_BOOT_KEY_PATH ??= ""

# Production User Keys (REQUIRED FOR PRODUCTION)
# User key: for signing user application images
TFM_PRODUCTION_USER_KEY_PATH ??= ""
```

#### Key File Requirements for TF-M

```bash
# Boot key directory must contain:
#   - boot_key.pem  : Private key (RSA 3072-bit, AES-256 encrypted)
#   - boot_key.pub  : Public key (RSA format)
#   - boot_key.pwd  : Password file for encrypted private key

# User key directory must contain:
#   - user_key.pem  : Private key (RSA 3072-bit, AES-256 encrypted)
#   - user_key.pub  : Public key (RSA format)
#   - user_key.pwd  : Password file for encrypted private key

# Generate Boot RSA key pair (3072-bit, AES-256 encrypted):
echo "YourBootPassword" > boot_key.pwd
openssl genrsa -aes256 -passout file:boot_key.pwd -out boot_key.pem 3072
openssl rsa -passin file:boot_key.pwd -in boot_key.pem -out boot_key.pub -pubout

# Generate User RSA key pair (3072-bit, AES-256 encrypted):
echo "YourUserPassword" > user_key.pwd
openssl genrsa -aes256 -passout file:user_key.pwd -out user_key.pem 3072
openssl rsa -passin file:user_key.pwd -in user_key.pem -out user_key.pub -pubout
```

#### Security Notes

- ⚠️ Development keys are automatically provided by `sign-image-native` (DO NOT USE IN PRODUCTION)
- 🔒 Always use production keys for deployment
- 🔐 Store keys in secure location (HSM, encrypted storage, or encrypted USB)
- ❌ Never commit keys to version control

---

### 2. TF-A (Trusted Firmware-A) Configuration - Boot Stage 2

TF-A BL31 provides secure monitor and runtime services, running at EL3.

```bitbake
# TF-A Board Configuration (set in conf/machine/v3-{board}.conf)
TFA_BOARD ?= ""            # Board-specific configuration

# TF-A Debug Mode
TFA_DEBUG ?= "0"           # 0: Release, 1: Debug

# TF-A Log Level
TFA_LOG_LEVEL ?= "40"      # 0-50 (0:none, 10:error, 20:notice, 30:warn, 40:info, 50:verbose)

# Production User Keys (REQUIRED FOR PRODUCTION)
TFA_PRODUCTION_KEY_PATH ??= ""
```

#### Key File Requirements for TF-A

```bash
# User key directory must contain:
#   - user_key.pem  : Private key (RSA 3072-bit, AES-256 encrypted)
#   - user_key.pub  : Public key (RSA format)
#   - user_key.pwd  : Password file for encrypted private key

# Same format as TF-M user keys
```

---

### 3. U-Boot Configuration - Boot Stage 3

U-Boot bootloader loads and starts the Linux kernel.

```bitbake
# U-Boot Machine Configuration (set in conf/machine/v3-{board}.conf)
UBOOT_MACHINE = "v3_{board}_defconfig"

# Image Load Address for secure keys
UBOOT_LOAD_ADDRESS ?= "0x80400000"

# Production User Keys (REQUIRED FOR PRODUCTION)
UBOOT_PRODUCTION_KEY_PATH ??= ""
```

#### Key File Requirements for U-Boot

```bash
# User key directory must contain:
#   - user_key.pem  : Private key (RSA 3072-bit, AES-256 encrypted)
#   - user_key.pub  : Public key (RSA format)
#   - user_key.pwd  : Password file for encrypted private key

# Same format as TF-M/TF-A user keys
```

---

### 4. Kernel Configuration - Boot Stage 4

Linux kernel initialization and hardware driver setup.

```bitbake
# Kernel Image Type
KERNEL_IMAGETYPE ?= "Image"

# Kernel Default Config (set in conf/machine/v3-{board}.conf)
KBUILD_DEFCONFIG = "v3_{board}_defconfig"

# Kernel Device Tree (set in conf/machine/v3-{board}.conf)
KERNEL_DEVICETREE = "deepx/v3-{board}.dtb"
```

---

### 5. Init System Configuration - Boot Stage 5

System initialization and service management (first user space process).

```bitbake
# Select init manager (systemd or busybox)
# Default: systemd
VIRTUAL-RUNTIME_init_manager ?= "systemd"
# or
VIRTUAL-RUNTIME_init_manager ?= "busybox"
```

---

### 6. User Account Configuration - User Space Setup

User accounts, passwords, and auto-login configuration for system access.

```bitbake
# Root Password Hash (change for production!)
# Generate with: openssl passwd -6 <password>
LINUX_ACCOUNT_ROOT_PASSWD_HASH ?= "$6$..."

# Default User Account
LINUX_ACCOUNT_USER_NAME ?= "deepx"
LINUX_ACCOUNT_USER_PASSWD_HASH ?= "$6$..."
LINUX_ACCOUNT_USER_GROUPS ?= "sudo,wheel"

# Auto Login Configuration
LINUX_ACCOUNT_ROOT_AUTOLOGIN ?= ""      # Set to "1" to enable root auto login
LINUX_ACCOUNT_USER_AUTOLOGIN ?= "1"     # Set to "" to disable user auto login
LINUX_ACCOUNT_AUTOLOGIN_TTY ?= "ttyAMA0" # Serial console for auto login
```

---

### 7. Data Partition Configuration - Storage Mount

Data partition auto-mount configuration during system startup.

```bitbake
# Device Node for Data Partition
IMAGE_DATA_PART_DEVICE_NODE ?= "/dev/mmcblk2p3"

# Wait Time (seconds) for device to appear
IMAGE_DATA_PART_WAIT_TIME ?= "2"

# Mount Options for Data Partition
IMAGE_DATA_PART_MOUNT_OPTIONS ?= "defaults,noatime,nofail"
```

---

### 8. Image Configuration - Build Output

Image generation settings for bootfs, rootfs, and initramfs.

#### Standard Image (ext4/wic)

Refer to `wic/deepx-v3-mmc.wks` for partition layout details.

```bitbake
# WKS (Wic KickStart) File - Partition Layout Definition
# Defines the partition table structure and content for the disk image
WKS_FILE ?= "deepx-v3-mmc.wks"

# To customize partition layout:
# 1. Create a new WKS file in wic/ directory (e.g., wic/custom-layout.wks)
# 2. Set WKS_FILE = "custom-layout.wks" in local.conf or machine conf
# 3. Define partitions with --ondisk and --fixed-size options
#
# Example WKS file structure (wic/deepx-v3-mmc.wks):
#   part /boot --source bootimg-partition --ondisk ${IMAGE_BOOTFS_WIC_DISK} \
#              --fstype=ext4 --label boot --align 4096 --fixed-size ${IMAGE_BOOTFS_WIC_SIZE} --active
#   part / --source rootfs --ondisk ${IMAGE_ROOTFS_WIC_DISK} \
#          --fstype=ext4 --label root --align 4096 --fixed-size ${IMAGE_ROOTFS_WIC_SIZE} --use-uuid
#   bootloader --ptable gpt

# Boot Partition (p1)
# NOTE: Partition number is determined by order in WKS file, not by these variables
IMAGE_BOOTFS_WIC_DISK ?= "mmcblk2"     # Boot disk device (partition 1: mmcblk2p1)
IMAGE_BOOTFS_WIC_SIZE ?= "64M"

# Root Partition (p2)
# NOTE: Partition number is determined by order in WKS file, not by these variables
IMAGE_ROOTFS_WIC_DISK ?= "mmcblk2"     # Root disk device (partition 2: mmcblk2p2)
IMAGE_ROOTFS_WIC_SIZE ?= "512M"
IMAGE_ROOTFS_EXTRA_SPACE ?= "0"

# Boot Files (located at boot partition)
IMAGE_BOOT_FILES ?= "${KERNEL_IMAGETYPE} linux.dtb"
```

#### Initramfs Image Configuration

```bitbake
# Initramfs Root Filesystem Size
IMAGE_ROOTFS_SIZE ?= "8192"            # KB (busybox-initramfs)
IMAGE_ROOTFS_SIZE ?= "4096"            # KB (systemd-initramfs)
IMAGE_ROOTFS_EXTRA_SPACE ?= "0"
INITRAMFS_MAXSIZE ?= "262144"          # Maximum size in KB (256MB)
```

---

### 9. Package Management - Build System

Package format and management configuration.

```bitbake
# Package Format (ipk recommended for embedded systems)
PACKAGE_CLASSES ?= "package_ipk"   # or package_deb, package_rpm
```

---
## See Also

- [README.md](README.md) - Layer overview and quick start
- [kas/README.md](kas/README.md) - KAS build system usage guide
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [OpenEmbedded Documentation](https://www.openembedded.org/wiki/Main_Page)
