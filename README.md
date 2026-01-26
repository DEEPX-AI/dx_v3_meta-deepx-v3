# meta-deepx-v3

DEEPX V3 Yocto/OpenEmbedded BSP Layer

## Table of Contents

- [meta-deepx-v3](#meta-deepx-v3)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Layer Information](#layer-information)
  - [Dependencies](#dependencies)
  - [Directory Structure](#directory-structure)
  - [Prerequisites](#prerequisites)
    - [Installing KAS](#installing-kas)
      - [Ubuntu 20.04 and Earlier](#ubuntu-2004-and-earlier)
      - [Ubuntu 22.04 and Later](#ubuntu-2204-and-later)
  - [Quick Start](#quick-start)
    - [Download Source](#download-source)
    - [Building Image with KAS](#building-image-with-kas)
    - [Building SDK with KAS](#building-sdk-with-kas)
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

### Download Source

Clone the repository with the following command:

```bash
$ git clone git@gh.deepx.ai:deepx/dx_v3_meta-deepx-v3.git meta-deepx-v3
```

**Note:** The directory must be named **`meta-deepx-v3`** for the build to work correctly.

### Building Image with KAS

Build root filesystem images for target devices:

```bash
# Navigate to KAS directory
cd meta-deepx-v3/kas

# Build systemd-based image(ext4 format) for default target (v3-evb)
./kas-build.sh -t systemd -i image

# Enter shell for debugging
./kas-build.sh -t systemd -i image -s

# List all available options
./kas-build.sh -h

# List all available machine and build combinations
./kas-build.sh -l
```

**Build Outputs:**

Images are located in `build/tmp/deploy/images/<machine>/`:


### Building SDK with KAS

Build Software Development Kits for cross-compilation:

```bash
# Navigate to KAS directory
cd meta-deepx-v3/kas

# Build SDK(for application development) for default target (v3-evb)
./kas-build.sh -t systemd -i image -S
```

**SDK Types:**
- **Standard SDK (`-S`)**: Contains cross-compiler, libraries, and headers for application development

**Build Outputs:**

SDK installers are located in `build/tmp/deploy/sdk/`:
- **Standard SDK**: `deepx-v3-x86_64-cortexa53-toolchain-3.0-{machine}-{image}.sh`

Example: `build/tmp/deploy/sdk/deepx-v3-x86_64-cortexa53-toolchain-3.0-v3-evb-deepx-systemd-image.sh`


See [kas.md](documents/kas.md) for detailed KAS build system usage.

## Configuration

For detailed configuration options including:
- Boot stage configurations (TF-M, TF-A, U-Boot, Kernel)
- Secure boot key management
- Init system selection (systemd/busybox)
- User accounts and auto-login
- Image customization
- Production deployment examples

**See [BSP.md](documents/BSP.md) for complete configuration guide.**

## Documentation

- **[BSP.md](documents/BSP.md)** - Complete configuration guide with all available variables and examples
- **[kas.md](documents/kas.md)** - KAS build system usage and configuration

## Contributing

Please submit patches to the DEEPX.

## License

This layer is licensed under MIT License. See COPYING.MIT for details.
