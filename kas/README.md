# KAS Configuration Files

This directory contains KAS configuration files for building DEEPX V3 images.

## File Structure

### Base Configuration
- **deepx-v3.yml**: Base configuration with common settings for all builds

### Machine Configurations
- **v3-sort.yml**: Configuration for v3-sort machine

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
./kas-build.sh -t systemd -i image -m v3-sort

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
kas build v3-sort.yml:systemd-image.yml

# Build with busybox and initramfs
kas build v3-sort.yml:busybox-ramfs.yml

# Enter shell
kas shell v3-sort.yml:systemd-image.yml
```

## Build Outputs

### systemd + image
- Target: `deepx-image-systemd-image`
- Output: `deepx-image-systemd-image-v3-sort.wic`
- Format: ext4 + WIC bootable image

### systemd + ramfs
- Target: `deepx-image-systemd-initramfs`
- Output: `deepx-image-systemd-initramfs-v3-sort.cpio.gz`
- Format: Compressed CPIO archive

### busybox + image
- Target: `deepx-image-busybox-init-image`
- Output: `deepx-image-busybox-init-image-v3-sort.wic`
- Format: ext4 + WIC bootable image

### busybox + ramfs
- Target: `deepx-image-busybox-init-initramfs`
- Output: `deepx-image-busybox-init-initramfs-v3-sort.cpio.gz`
- Format: Compressed CPIO archive

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
        ├── v3-sort.yml        # Machine configuration
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