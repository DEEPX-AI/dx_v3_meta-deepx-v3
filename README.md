# meta-deepx-v3

DEEPX V3 Yocto/OpenEmbedded BSP Layer

## Table of Contents

- [Overview](#overview)
- [Layer Information](#layer-information)
- [Dependencies](#dependencies)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
  - [Installing KAS](#installing-kas)
    - [Ubuntu 20.04 and Earlier](#ubuntu-2004-and-earlier)
    - [Ubuntu 22.04 and Later](#ubuntu-2204-and-later)
- [Quick Start](#quick-start)
  - [Building with KAS](#building-with-kas)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

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

## Prerequisites

- Yocto-compatible Linux distribution (Ubuntu 22.04 LTS recommended)
- KAS build tool installed
- Required Yocto dependencies installed

### Installing KAS

#### Ubuntu 20.04 and Earlier

For Ubuntu 20.04 and earlier versions, you can install KAS using the traditional pip method:

```bash
# Update package list
sudo apt update

# Install Python pip (if not already installed)
sudo apt install python3-pip

# Install KAS directly with pip
pip3 install kas

# Verify installation
kas --version
```

#### Ubuntu 22.04 and Later

Ubuntu 22.04 introduced PEP 668 (externally managed environment) which restricts system-wide pip installations to prevent conflicts with system packages. Here are the recommended installation methods:

**Method 1: Using pipx (Recommended)**
```bash
# Install pipx and KAS
sudo apt update
sudo apt install pipx
pipx ensurepath
source ~/.bashrc
pipx install kas-container

# Verify installation
kas --version
```

**Method 2: Using virtual environment**
```bash
# Create and activate virtual environment
python3 -m venv ~/kas-env
source ~/kas-env/bin/activate
pip install kas-container

# Add alias for convenience (optional)
echo 'alias kas-env="source ~/kas-env/bin/activate"' >> ~/.bashrc
source ~/.bashrc

# Usage: activate environment before using kas
kas-env
kas --version
deactivate
```

**Method 3: Using pip with --user flag**
```bash
# Install to user directory
pip install kas-container --user

# Ensure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
kas --version
```

**Method 4: Override PEP 668 (Not recommended)**
```bash
# Force install system-wide (may cause conflicts)
pip install kas-container --break-system-packages

# Verify installation
kas --version
```

## Quick Start

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
