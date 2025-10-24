# KAS Configuration Files

This directory contains KAS configuration files for building DEEPX V3 images.

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

## Usage

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

# Build SDK
./kas-build.sh -t systemd -i image -S

# Build extended SDK (eSDK) - for recipe development
./kas-build.sh -t systemd -i image -E

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

# Build SDK
kas build v3-evb.yml:systemd-image.yml -- -c populate_sdk deepx-image-systemd-image

# Build extended SDK
kas build v3-evb.yml:systemd-image.yml -- -c populate_sdk_ext deepx-image-systemd-image

# Enter shell
kas shell v3-evb.yml:systemd-image.yml
```

## Build Outputs

### Images

#### systemd + image
- Target: `deepx-image-systemd-image`
- Output: `deepx-image-systemd-image-v3-evb.wic`
- Format: ext4 + WIC bootable image

#### systemd + ramfs
- Target: `deepx-image-systemd-initramfs`
- Output: `deepx-image-systemd-initramfs-v3-evb.cpio.gz`
- Format: Compressed CPIO archive

#### busybox + image
- Target: `deepx-image-busybox-init-image`
- Output: `deepx-image-busybox-init-image-v3-evb.wic`
- Format: ext4 + WIC bootable image

#### busybox + ramfs
- Target: `deepx-image-busybox-init-initramfs`
- Output: `deepx-image-busybox-init-initramfs-v3-evb.cpio.gz`
- Format: Compressed CPIO archive

### SDK

#### Standard SDK (`-S` option)
- Output: `build/tmp/deploy/sdk/deepx-v3-x86_64-cortexa53-toolchain-3.0.sh`
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

#### Extended SDK (`-E` option)
- Output: `build/tmp/deploy/sdk/deepx-v3-x86_64-cortexa53-toolchain-ext-3.0.sh`
- Size: 5GB - 10GB+ (includes sstate-cache)
- Use case: Recipe development, package modification, devtool workflow
- Build time: 2-3x longer than standard SDK
- Installation: Same as standard SDK

**Note**:
- SDK naming is simplified (machine-independent) via `TOOLCHAIN_OUTPUTNAME`
- Use standard SDK (`-S`) for most development tasks
- Use extended SDK (`-E`) only when you need to modify recipes or packages

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