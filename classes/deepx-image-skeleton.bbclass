#
# DEEPX Image Skeleton Class
#
# Provides essential rootfs structure and init script setup for busybox init.
#
# This class is responsible for:
#   - Creating directory structure for busybox init system
#   - Generating /init script for cpio/initramfs images
#   - Setting up hostname configuration
#   - Installing boot configuration files (fstab, inittab)
#
# Usage:
#   inherit deepx-image-skeleton
#
# Notes:
#   - Functions only execute when VIRTUAL-RUNTIME_init_manager = "busybox"
#   - /init script generation is conditional on IMAGE_FSTYPES containing "cpio"
#   - All functions are added to ROOTFS_POSTPROCESS_COMMAND
#

# Create essential directory structure for busybox init system
# This function creates the basic filesystem hierarchy required for proper
# system boot and operation.
setup_skeleton() {
    bbnote "Setting up skeleton directories for busybox init"

    # Define required directories
    local dirs="dev mnt proc sys tmp var run boot data dev/shm dev/pts"

    # Create each directory
    for dir in ${dirs}; do
        install -d ${IMAGE_ROOTFS}/${dir}
    done

    # Create symbolic links for FHS (Filesystem Hierarchy Standard) compatibility
    # These links ensure proper operation of legacy applications
    ln -sf ../run ${IMAGE_ROOTFS}/var/run
    ln -sf ../tmp ${IMAGE_ROOTFS}/var/log
    ln -sf ../tmp ${IMAGE_ROOTFS}/var/tmp
}

# Generate /init script for cpio/initramfs images
# This script is the first process executed by the kernel and is responsible
# for early system initialization before handing control to /sbin/init.
#
# The generated script:
#   - Mounts devtmpfs for device access
#   - Redirects console I/O for proper logging
#   - Executes /sbin/init with all arguments
setup_initscripts() {
    bbnote "Setting up init script for busybox init"

    # Generate /init script with proper shebang and early mount
    cat > ${IMAGE_ROOTFS}/init << 'INIT_SCRIPT'
#!/bin/sh
#
# Early Init Script for DEEPX V3
#
# This script is executed as PID 1 by the kernel during boot.
# It performs minimal initialization before transferring control to /sbin/init.
#

# Mount devtmpfs for device access
# Only mount if not already mounted
if ! mountpoint -q /dev; then
    /bin/mount -t devtmpfs devtmpfs /dev
fi

# Setup console I/O redirection
# This ensures all output goes to the console
if (exec 0</dev/console) 2>/dev/null; then
    exec 0</dev/console
    exec 1>/dev/console
    exec 2>/dev/console
fi
INIT_SCRIPT

    # Add final exec to transfer control to init
    cat >> ${IMAGE_ROOTFS}/init << 'INIT_END'

# Transfer control to the real init system
exec /sbin/init "$@"
INIT_END

    # Make script executable
    chmod +x ${IMAGE_ROOTFS}/init
}

# Configure system hostname for busybox init
# Sets the hostname to match the MACHINE variable, ensuring consistent
# identification across the system.
setup_hostname() {
    bbnote "Setting up hostname for busybox init"
    echo "${MACHINE}" > ${IMAGE_ROOTFS}/etc/hostname
}

# Install boot configuration files for busybox init
# Copies essential configuration files from the recipe files directory:
#   - fstab: Filesystem mount table
#   - inittab: Init process configuration
#
# Files are sourced from: ${THISDIR}/files/
setup_boot_files() {
    bbnote "Setting up init configuration files for busybox init"

    # Install fstab (filesystem table)
    if [ -f ${THISDIR}/files/fstab_default ]; then
        install -d ${IMAGE_ROOTFS}/etc
        install -m 0644 ${THISDIR}/files/fstab_default ${IMAGE_ROOTFS}/etc/fstab
    fi

    # Install inittab (init configuration)
    if [ -f ${THISDIR}/files/inittab ]; then
        install -d ${IMAGE_ROOTFS}/etc
        install -m 0644 ${THISDIR}/files/inittab ${IMAGE_ROOTFS}/etc/inittab
    fi
}

#
# ROOTFS Post-Process Command Registration
#
# These commands are executed after rootfs creation but before image generation.
# They are conditionally added based on init manager and image type.
#

# Register post-process commands (only for busybox init)
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_skeleton; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_initscripts; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' and 'cpio' in d.getVar('IMAGE_FSTYPES').split() else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_hostname; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_boot_files; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
