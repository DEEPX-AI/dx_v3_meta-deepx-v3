# meta-deepx-v3

DEEPX V3 Yocto/OpenEmbedded BSP Layer

## Overview

This layer provides Board Support Package (BSP) and distribution configurations for DEEPX V3 platforms.

## Layer Information

- **Layer Name**: meta-deepx-v3
- **Maintainer**: DEEPX
- **Compatible**: Yocto Scarthgap (5.0)

## Dependencies

This layer depends on:

- **poky** (scarthgap branch)
  - URI: https://git.yoctoproject.org/git/poky
  - Branch: scarthgap
  - Layers: meta, meta-poky

- **meta-openembedded** (scarthgap branch)
  - URI: https://git.openembedded.org/meta-openembedded
  - Branch: scarthgap
  - Layers: meta-oe, meta-python, meta-multimedia, meta-networking

## Directory Structure

```
meta-deepx-v3/
├── classes/              # Custom BitBake classes
├── conf/
│   ├── distro/          # Distribution configurations (deepx-v3)
│   ├── machine/         # Machine(support board) configurations (v3-sort, v3-evb, etc.)
│   └── layer.conf       # Layer configuration
├── kas/                 # KAS build system configurations
├── recipes-bsp/         # BSP-specific recipes
├── recipes-core/        # Core system recipes
├── recipes-devtools/    # Development tools
├── recipes-kernel/      # Kernel recipes
├── recipes-libs/        # Library recipes
└── wic/                 # WIC image creation files
```

## Quick Start

### Prerequisites

- Yocto-compatible Linux distribution (Ubuntu 22.04 LTS recommended)
- KAS build tool installed (`pip install kas`)
- Required Yocto dependencies installed

### Building with KAS

```bash
# Navigate to KAS directory
cd meta-deepx-v3/kas

# Build systemd-based standard image (ext4/wic)
./kas-build.sh -t systemd -i image

# Build busybox-based initramfs image (cpio)
./kas-build.sh -t busybox -i ramfs

# Build SDK (Software Development Kit)
./kas-build.sh -t systemd -i image -S

# Build extended SDK (eSDK) - for recipe development
./kas-build.sh -t systemd -i image -E

# Specify machine (default: v3-evb)
./kas-build.sh -t systemd -i image -m v3-sort

# Enter shell for debugging
./kas-build.sh -t systemd -i image -s

# List all available options
./kas-build.sh -h

# List all available machine and build combinations
./kas-build.sh -l
```

See [kas/README.md](kas/README.md) for detailed KAS build system usage.

## Configuration

For detailed configuration options including:
- Boot stage configurations (TF-M, TF-A, U-Boot, Kernel)
- Secure boot key management
- Init system selection (systemd/busybox)
- User accounts and auto-login
- Image customization
- Production deployment examples

**See [CONFIGURATION.md](CONFIGURATION.md) for complete configuration guide.**

## Documentation

- **[CONFIGURATION.md](CONFIGURATION.md)** - Complete configuration guide with all available variables and examples
- **[kas/README.md](kas/README.md)** - KAS build system usage and configuration

## Contributing

Please submit patches to the DEEPX.

## License

This layer is licensed under MIT License. See COPYING.MIT for details.
