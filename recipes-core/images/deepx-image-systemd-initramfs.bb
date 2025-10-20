# DEEPX Minimal Tiny Image with systemd init system
#
# This is a minimal size image with only essential components for systemd boot.
# Designed for resource-constrained embedded systems where image size is critical.
#
# IMPORTANT: This image REQUIRES systemd init manager
#   Set in build/conf/local.conf:
#   VIRTUAL-RUNTIME_init_manager = "systemd"
#
# Size optimization strategies:
#   - Uses packagegroup-core-boot only (no extended packages)
#   - No SSH server
#   - No package management (rpm/dnf removed)
#   - Minimal systemd configuration
#   - No development tools
#   - No locale data
#
# Build:
#   bitbake deepx-image-systemd-initramfs

SUMMARY = "DEEPX minimal tiny image with systemd"
DESCRIPTION = "Ultra-minimal DEEPX initramfs with systemd - optimized for smallest size"
LICENSE = "MIT"

#
# Init Manager Validation
#
# Require systemd init manager - validation handled by deepx-image-validate class
REQUIRED_INIT_MANAGER = "systemd"

# Inherit core image class
inherit core-image
inherit extrausers

inherit deepx-image-validate
inherit deepx-image-account
inherit deepx-image-cpio
inherit deepx-image-systemd

# Minimal image features - remove all optional features
IMAGE_FEATURES = ""

export IMAGE_BASENAME = "deepx-systemd-initramfs"

# Remove package management to reduce size
IMAGE_FEATURES:remove = "package-management"

# Only include absolute minimum packages for boot
# packagegroup-core-boot provides: base-files, base-passwd, busybox, systemd, udev, netbase
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"
# Add shadow for password management
IMAGE_INSTALL:append = " shadow"

# Add sudo for privilege escalation (sudo group members can use sudo)
IMAGE_INSTALL:append = " sudo"

# Add only critical DEEPX-specific packages
IMAGE_INSTALL:append = " kernel-modules"

# Add systemd mount services (data partition)
IMAGE_INSTALL:append = " systemd-mount-data"

# Configure sudo to allow sudo group without password (optional)
# Uncomment the line below for passwordless sudo
# EXTRA_USERS_PARAMS:append = " sed -i 's/# %sudo/%sudo/' /etc/sudoers; "

# Keep essential features:
# - kmod: Kernel module loading (required)
# - networkd: Network management
# - resolved: DNS resolution
# - timesyncd: Time synchronization
# - myhostname: Hostname resolution
# - randomseed: Random seed for security
BAD_RECOMMENDATIONS += " \
    systemd-battery-check \
    systemd-extra-utils \
    systemd-analyze \
    udev-hwdb \
    systemd-journal-gatewayd \
    systemd-journal-remote \
    systemd-journal-upload \
    systemd-container \
    systemd-bash-completion \
    systemd-zsh-completion \
    udev-bash-completion \
"

# Minimal root filesystem size
IMAGE_ROOTFS_SIZE ?= "4096"
IMAGE_ROOTFS_EXTRA_SPACE = "512"

# Optimize for size
IMAGE_OVERHEAD_FACTOR = "1.0"

# Remove locales to save space
IMAGE_LINGUAS = ""

# Use cpio format for initramfs
IMAGE_FSTYPES = "cpio"

# Machine-specific settings
IMAGE_MACHINE_SUFFIX = "-${MACHINE}"
IMAGE_VERSION_SUFFIX = "-${DATETIME}"
IMAGE_VERSION_SUFFIX[vardepsexclude] = "DATETIME"
