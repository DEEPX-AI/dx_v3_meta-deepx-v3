# DEEPX Image Skeleton Class
# Provides essential rootfs structure and init script setup

# Create essential directory structure (busybox init only)
setup_skeleton() {
    bbnote "Setting up skeleton directories for busybox init"
    local dirs="dev mnt proc sys tmp var run boot data dev/shm dev/pts"
    for dir in ${dirs}; do
        install -d ${IMAGE_ROOTFS}/${dir}
    done

    # Create symbolic links for compatibility
    ln -sf ../run ${IMAGE_ROOTFS}/var/run
    ln -sf ../tmp ${IMAGE_ROOTFS}/var/log
    ln -sf ../tmp ${IMAGE_ROOTFS}/var/tmp
}

# Generate /init script (busybox init only)
setup_initscripts() {
    bbnote "Setting up init script for busybox init"
    cat > ${IMAGE_ROOTFS}/init << 'INIT_SCRIPT'
#!/bin/sh
# Mount devtmpfs
if ! mountpoint -q /dev; then
    /bin/mount -t devtmpfs devtmpfs /dev
fi

# Setup console
if (exec 0</dev/console) 2>/dev/null; then
    exec 0</dev/console
    exec 1>/dev/console
    exec 2>/dev/console
fi
INIT_SCRIPT

    cat >> ${IMAGE_ROOTFS}/init << 'INIT_END'

exec /sbin/init "$@"
INIT_END

    chmod +x ${IMAGE_ROOTFS}/init
}

# Setup hostname (busybox init only)
setup_hostname() {
    bbnote "Setting up hostname for busybox init"
    echo "${MACHINE}" > ${IMAGE_ROOTFS}/etc/hostname
}

# Copy configuration files from recipe (busybox init only)
setup_boot_files() {
    bbnote "Setting up init configuration files for busybox init"
    # Copy fstab
    if [ -f ${THISDIR}/files/fstab_default ]; then
        install -d ${IMAGE_ROOTFS}/etc
        install -m 0644 ${THISDIR}/files/fstab_default ${IMAGE_ROOTFS}/etc/fstab
    fi

    # Copy inittab
    if [ -f ${THISDIR}/files/inittab ]; then
        install -d ${IMAGE_ROOTFS}/etc
        install -m 0644 ${THISDIR}/files/inittab ${IMAGE_ROOTFS}/etc/inittab
    fi
}

# Register post-process commands (only for busybox init)
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_skeleton; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_initscripts; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' and 'cpio' in d.getVar('IMAGE_FSTYPES').split() else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_hostname; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
ROOTFS_POSTPROCESS_COMMAND += "${@'setup_boot_files; ' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ''}"
