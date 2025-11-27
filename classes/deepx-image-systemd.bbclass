# DEEPX systemd Image Configuration Class
# Provides systemd-specific image customizations for DEEPX embedded systems

# This function creates a mask symlink to prevent remount failures on initramfs
mask_systemd_services() {
    # Mask systemd-remount-fs.service for RAM-based root filesystems
    # Only mask for non-ext4 filesystems (e.g., cpio, tar.gz)
    if echo "${IMAGE_FSTYPES}" | grep -qv "ext4"; then
        if [ -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/system ]; then
            bbnote "Masking systemd-remount-fs.service for RAM-based rootfs"
            ln -sf /dev/null \
                ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/systemd-remount-fs.service
        fi
    fi
}

# Register the function to run during rootfs post-processing
ROOTFS_POSTPROCESS_COMMAND += "mask_systemd_services; "
