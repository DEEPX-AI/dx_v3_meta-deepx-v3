# KAS Configuration Files

This directory contains KAS configuration files for building DEEPX V3 images.

## Table of Contents

- [KAS Configuration Files](#kas-configuration-files)
  - [Table of Contents](#table-of-contents)
  - [File Structure](#file-structure)
    - [Base Configuration](#base-configuration)
    - [Machine Configurations](#machine-configurations)
    - [Build Configurations (Init + Image Type)](#build-configurations-init--image-type)
  - [Prerequisites](#prerequisites)
  - [Building Images](#building-images)
    - [Using kas-build.sh (Recommended)](#using-kas-buildsh-recommended)
    - [Using KAS directly](#using-kas-directly)
    - [Outputs](#outputs)
      - [systemd + image](#systemd--image)
      - [systemd + ramfs](#systemd--ramfs)
      - [busybox + image](#busybox--image)
      - [busybox + ramfs](#busybox--ramfs)
  - [Building SDK](#building-sdk)
    - [Using kas-build.sh (Recommended)](#using-kas-buildsh-recommended-1)
    - [Using KAS directly](#using-kas-directly-1)
    - [Outputs](#outputs-1)
      - [Standard SDK (`-S` option)](#standard-sdk--s-option)
  - [Directory Layout](#directory-layout)
    - [Repository Paths](#repository-paths)
    - [Build Directory](#build-directory)
    - [Build Resources](#build-resources)

## File Structure

### Base Configuration
- **deepx-v3.yml**: Base configuration with common settings for all builds

### Machine Configurations
- **v3-evb.yml**: Configuration for v3-evb machine

### Build Configurations (Init + Image Type)
Combined configuration files that specify both init system and image type:

- **systemd-image.yml**: systemd + Standard image (ext4/wic)
- **systemd-ramfs.yml**: systemd + Initramfs image (cpio)
- **busybox-image.yml**: busybox + Standard image (ext4/wic)
- **busybox-ramfs.yml**: busybox + Initramfs image (cpio)

## Prerequisites

- Yocto-compatible Linux distribution (Ubuntu 22.04 LTS recommended)
- KAS build tool installed (`pip install kas`)
- Required Yocto dependencies installed

## Building Images

### Using kas-build.sh (Recommended)

```bash
# Build with systemd and image (ext4/wic)
./kas-build.sh -t systemd -i image

# Build with busybox and ramfs (cpio)
./kas-build.sh -t busybox -i ramfs

# Specify machine
./kas-build.sh -t systemd -i image -m v3-evb

# Specify build directory
./kas-build.sh -t systemd -i image -b /path/to/build

# Enter shell for debugging
./kas-build.sh -t systemd -i image -s

# List all available combinations
./kas-build.sh -l
```

### Using KAS directly

```bash
# Build with systemd and standard image
kas build v3-evb.yml:systemd-image.yml

# Build with busybox and initramfs
kas build v3-evb.yml:busybox-ramfs.yml

# Enter shell
kas shell v3-evb.yml:systemd-image.yml
```

### Outputs

#### systemd + image
- Target: `deepx-image-systemd-image`
- Output: `deepx-image-systemd-image-v3-evb.wic`
- Format: ext4 + WIC bootable image
- Location: `build/tmp/deploy/images/v3-evb/`

#### systemd + ramfs
- Target: `deepx-image-systemd-initramfs`
- Output: `deepx-image-systemd-initramfs-v3-evb.cpio.gz`
- Format: Compressed CPIO archive
- Location: `build/tmp/deploy/images/v3-evb/`

#### busybox + image
- Target: `deepx-image-busybox-init-image`
- Output: `deepx-image-busybox-init-image-v3-evb.wic`
- Format: ext4 + WIC bootable image
- Location: `build/tmp/deploy/images/v3-evb/`

#### busybox + ramfs
- Target: `deepx-image-busybox-init-initramfs`
- Output: `deepx-image-busybox-init-initramfs-v3-evb.cpio.gz`
- Format: Compressed CPIO archive
- Location: `build/tmp/deploy/images/v3-evb/`

## Building SDK

### Using kas-build.sh (Recommended)

```bash
# Build SDK
./kas-build.sh -t systemd -i image -S

# Build SDK for specific machine
./kas-build.sh -t systemd -i image -m v3-sort -S

# Build both image and SDK together
./kas-build.sh -t systemd -i image -S
```

### Using KAS directly

```bash
# Build SDK
kas build v3-evb.yml:systemd-image.yml -- -c populate_sdk deepx-image-systemd-image
```

### Outputs

#### Standard SDK (`-S` option)
- Output: `deepx-v3-x86_64-cortexa53-toolchain-3.0.sh`
- Location: `build/tmp/deploy/sdk/`
- Size: ~500MB - 1GB
- Use case: Application development and cross-compilation
- Installation: Run the `.sh` script to install SDK
- Default install location: `/opt/deepx-v3/3.0/`

Example installation:
```bash
# Default installation (interactive)
./deepx-v3-x86_64-cortexa53-toolchain-3.0.sh

# Non-interactive installation with custom path
./deepx-v3-x86_64-cortexa53-toolchain-3.0.sh -d /home/user/sdk -y

# Installation options:
# -d <path>  : Install to custom directory
# -y         : Accept license and install automatically (non-interactive)
# -h         : Show help

# Setup environment for cross-compilation
source /opt/deepx-v3/3.0/environment-setup-cortexa53-deepx-linux

# With custom path
source /home/user/sdk/environment-setup-cortexa53-deepx-linux
```

**Note**:
- SDK naming is simplified (machine-independent) via `TOOLCHAIN_OUTPUTNAME`

## Directory Layout

```
scarthgap/
├── poky/                      # Yocto Poky (shared)
├── meta-openembedded/         # Meta-OE layers (shared)
├── build/                     # Build directory
│   ├── downloads/             # Download directory (DL_DIR)
│   ├── sstate-cache/          # Sstate cache (SSTATE_DIR)
│   ├── tmp/                   # Build artifacts
│   └── conf/                  # Build configuration
└── meta-deepx-v3/
    └── kas/
        ├── deepx-v3.yml       # Base configuration
        ├── v3-evb.yml        # Machine configuration
        ├── systemd-*.yml      # systemd configurations
        ├── busybox-*.yml      # busybox configurations
        └── kas-build.sh       # Build helper script
```

### Repository Paths
All repositories (poky, meta-openembedded) are stored at the scarthgap level:
- Path: `../../poky`
- Path: `../../meta-openembedded`

### Build Directory
Default build directory: `../../build` (can be changed with `-b` option)

### Build Resources
All build resources are stored within the build directory:
- DL_DIR: `${TOPDIR}/downloads` (can be changed with `-d` option)
- SSTATE_DIR: `${TOPDIR}/sstate-cache` (can be changed with `-c` option)

This keeps all build-related files contained within the build directory.