# DEEPX Image WIC Class
# Provides WIC partition deployment with sparse image support

# Variables:
#   IMAGE_BOOTFS_WIC_SIZE  - Boot partition size (e.g., "64M")
#   IMAGE_BOOTFS_WIC_DISK  - Boot partition disk (e.g., "mmcblk2")
#   IMAGE_ROOTFS_WIC_SIZE  - Root partition size (e.g., "512M", "1G")
#   IMAGE_ROOTFS_WIC_DISK  - Root partition disk (e.g., "mmcblk2")
#   IMAGE_TO_SPARSE_IMAGE  - Enable sparse image (default: "1")

# Convert IMAGE_ROOTFS_WIC_SIZE to KB for BitBake
python __anonymous() {
    wic_size = d.getVar('IMAGE_ROOTFS_WIC_SIZE')
    if wic_size:
        import re
        match = re.match(r'^(\d+)([KMG]?)$', wic_size)
        if match:
            size_val = int(match.group(1))
            unit = match.group(2) or 'M'

            # Convert to KB
            size_kb = {'K': size_val, 'M': size_val * 1024, 'G': size_val * 1024 * 1024}[unit]
            d.setVar('IMAGE_ROOTFS_SIZE', str(size_kb))
}

# Configuration
IMAGE_BOOT_PARTITION_NAME = "bootfs"
IMAGE_ROOT_PARTITION_NAME = "rootfs"
IMAGE_TO_SPARSE_IMAGE ?= "1"

# WIC environment variables
WICVARS:append = " IMAGE_BOOTFS_WIC_DISK IMAGE_BOOTFS_WIC_SIZE"
WICVARS:append = " IMAGE_ROOTFS_WIC_SIZE IMAGE_ROOTFS_WIC_DISK"

# Runtime dependencies
DEPENDS:append = "${@' android-tools-native' if d.getVar('IMAGE_TO_SPARSE_IMAGE') == '1' else ''}"

# Deploy WIC partition images with optional sparse conversion
python do_deploy_wic_partitions() {
    import os, shutil, subprocess

    deploy_dir = d.getVar('IMGDEPLOYDIR')
    build_wic = os.path.join(d.getVar('WORKDIR'), 'build-wic')

    if not os.path.exists(build_wic):
        bb.debug(1, f"WIC build directory not found: {build_wic}")
        return

    # Image naming
    image_basename = d.getVar('IMAGE_BASENAME') or ''
    machine_suffix = d.getVar('IMAGE_MACHINE_SUFFIX') or ''
    version_suffix = d.getVar('IMAGE_VERSION_SUFFIX') or ''
    image_name = f"{image_basename}{machine_suffix}{version_suffix}"
    link_prefix = f"{image_basename}{machine_suffix}"

    # Configuration
    sparse_enabled = d.getVar('IMAGE_TO_SPARSE_IMAGE') == '1'
    partitions = {
        '.p1': (d.getVar('IMAGE_BOOT_PARTITION_NAME') or 'bootfs', 'Boot'),
        '.p2': (d.getVar('IMAGE_ROOT_PARTITION_NAME') or 'rootfs', 'Root'),
    }

    def create_link(link_path, target):
        """Create or update symlink"""
        if os.path.lexists(link_path):
            os.remove(link_path)
        os.symlink(target, link_path)

    def convert_to_sparse(src, dst, desc):
        """Convert ext4 to sparse image"""
        try:
            subprocess.run(['img2simg', src, dst], check=True, capture_output=True, text=True)
            bb.note(f"{desc} sparse image created: {os.path.basename(dst)}")
            return True
        except subprocess.CalledProcessError as e:
            bb.warn(f"Failed to create sparse image for {desc} partition: {e.stderr}")
        except FileNotFoundError:
            bb.warn("img2simg not found. Install android-tools-native.")
        return False

    # Process partitions
    for filename in os.listdir(build_wic):
        for suffix, (part_name, desc) in partitions.items():
            if not filename.endswith(suffix):
                continue

            src = os.path.join(build_wic, filename)

            # Deploy ext4 partition
            ext4_name = f"{image_name}-{part_name}.ext4"
            ext4_link = f"{link_prefix}-{part_name}.ext4"
            ext4_dst = os.path.join(deploy_dir, ext4_name)

            shutil.copy2(src, ext4_dst)
            bb.note(f"{desc} partition deployed: {ext4_name}")

            create_link(os.path.join(deploy_dir, ext4_link), ext4_name)
            bb.debug(1, f"Symlink: {ext4_link} -> {ext4_name}")

            # Convert to sparse if enabled
            if sparse_enabled:
                sparse_name = f"{image_name}-{part_name}.img"
                sparse_link = f"{part_name}.img"
                sparse_dst = os.path.join(deploy_dir, sparse_name)

                if convert_to_sparse(ext4_dst, sparse_dst, desc):
                    create_link(os.path.join(deploy_dir, sparse_link), sparse_name)
                    bb.debug(1, f"Sparse link: {sparse_link} -> {sparse_name}")

            break
}

# Task configuration
addtask deploy_wic_partitions after do_image_wic before do_image_complete
do_deploy_wic_partitions[dirs] = "${IMGDEPLOYDIR}"
do_deploy_wic_partitions[doc] = "Deploy WIC partitions with optional sparse conversion"

# Conditional execution
python __anonymous() {
    if 'wic' not in (d.getVar('IMAGE_FSTYPES') or ''):
        d.delVarFlag('do_deploy_wic_partitions', 'task')
}
