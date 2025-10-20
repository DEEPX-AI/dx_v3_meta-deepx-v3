#
# DEEPX Image WIC Class
#
# Provides WIC (OpenEmbedded Kickstart) partition deployment with sparse image
# support for efficient storage and faster flashing.
#
# Features:
#   - Automatic partition extraction from WIC build output
#   - Optional conversion to Android sparse image format
#   - Symbolic link management for latest images
#   - Boot and root partition deployment
#
# Variables:
#   IMAGE_BOOTFS_WIC_SIZE  - Boot partition size (e.g., "64M")
#   IMAGE_BOOTFS_WIC_DISK  - Boot partition disk (e.g., "mmcblk2")
#   IMAGE_ROOTFS_WIC_SIZE  - Root partition size (e.g., "512M", "1G")
#   IMAGE_ROOTFS_WIC_DISK  - Root partition disk (e.g., "mmcblk2")
#   IMAGE_TO_SPARSE_IMAGE  - Enable sparse image conversion (default: "1")
#
# Usage:
#   inherit deepx-image-wic
#
# Output:
#   - ${IMAGE_NAME}-bootfs.ext4       : Boot partition ext4 image
#   - ${IMAGE_NAME}-rootfs.ext4       : Root partition ext4 image
#   - ${IMAGE_NAME}-bootfs.img        : Boot partition sparse image (if enabled)
#   - ${IMAGE_NAME}-rootfs.img        : Root partition sparse image (if enabled)
#   - bootfs.img -> latest boot sparse : Convenience symlink
#   - rootfs.img -> latest root sparse : Convenience symlink
#

# Convert IMAGE_ROOTFS_WIC_SIZE to KB for BitBake size calculations
# This anonymous function runs during recipe parsing and converts human-readable
# size specifications (e.g., "512M", "1G") into kilobytes for IMAGE_ROOTFS_SIZE.
#
# Supported units: K (kilobytes), M (megabytes), G (gigabytes)
# Default unit if omitted: M (megabytes)
python __anonymous() {
    wic_size = d.getVar('IMAGE_ROOTFS_WIC_SIZE')
    if wic_size:
        import re
        match = re.match(r'^(\d+)([KMG]?)$', wic_size)
        if match:
            size_val = int(match.group(1))
            unit = match.group(2) or 'M'

            # Convert to KB based on unit
            size_kb = {'K': size_val, 'M': size_val * 1024, 'G': size_val * 1024 * 1024}[unit]
            d.setVar('IMAGE_ROOTFS_SIZE', str(size_kb))
}

# Configuration
IMAGE_BOOT_PARTITION_NAME = "bootfs"
IMAGE_ROOT_PARTITION_NAME = "rootfs"
IMAGE_TO_SPARSE_IMAGE ?= "1"

# WIC environment variables
# These variables are passed to the WIC tool for kickstart file processing
WICVARS:append = " IMAGE_BOOTFS_WIC_DISK IMAGE_BOOTFS_WIC_SIZE"
WICVARS:append = " IMAGE_ROOTFS_WIC_SIZE IMAGE_ROOTFS_WIC_DISK"

# Runtime dependencies
# android-tools-native provides img2simg for sparse image conversion
DEPENDS:append = "${@' android-tools-native' if d.getVar('IMAGE_TO_SPARSE_IMAGE') == '1' else ''}"

#
# Deploy WIC partition images with optional sparse conversion
#
# This function extracts individual partitions from WIC build output and
# optionally converts them to Android sparse format for efficient flashing.
#
python do_deploy_wic_partitions() {
    """
    Deploy WIC partition images with optional sparse conversion.

    This function:
      1. Locates partition files in the WIC build directory
      2. Copies ext4 partition images to deploy directory
      3. Optionally converts ext4 to sparse format using img2simg
      4. Creates convenience symlinks to latest images

    The function processes boot (.p1) and root (.p2) partitions separately,
    creating both ext4 and sparse versions (if enabled).
    """
    import os, shutil, subprocess

    # Get deploy and build directories
    deploy_dir = d.getVar('IMGDEPLOYDIR')
    build_wic = os.path.join(d.getVar('WORKDIR'), 'build-wic')

    # Validate WIC build directory exists
    if not os.path.exists(build_wic):
        bb.note(f"WIC build directory not found: {build_wic}. Skipping partition deployment.")
        return

    # Cache frequently accessed variables (performance optimization)
    image_basename = d.getVar('IMAGE_BASENAME') or ''
    machine_suffix = d.getVar('IMAGE_MACHINE_SUFFIX') or ''
    version_suffix = d.getVar('IMAGE_VERSION_SUFFIX') or ''

    # Build image naming strings
    image_name = f"{image_basename}{machine_suffix}{version_suffix}"
    link_prefix = f"{image_basename}{machine_suffix}"

    # Configuration
    sparse_enabled = d.getVar('IMAGE_TO_SPARSE_IMAGE') == '1'
    boot_part_name = d.getVar('IMAGE_BOOT_PARTITION_NAME') or 'bootfs'
    root_part_name = d.getVar('IMAGE_ROOT_PARTITION_NAME') or 'rootfs'

    # Partition configuration mapping
    partitions = {
        '.p1': (boot_part_name, 'Boot'),
        '.p2': (root_part_name, 'Root'),
    }

    def create_link(link_path, target):
        """
        Create or update a symbolic link.

        This helper function ensures clean symlink creation by removing any
        existing link before creating a new one.

        Args:
            link_path (str): Full path to the symlink to create
            target (str): Target filename (relative) that the symlink points to

        Note:
            Uses os.lexists() to detect broken symlinks before removal
        """
        if os.path.lexists(link_path):
            os.remove(link_path)
        os.symlink(target, link_path)

    def convert_to_sparse(src, dst, desc):
        """
        Convert an ext4 image to Android sparse image format.

        Sparse images contain only allocated blocks, significantly reducing
        image size and flash time compared to raw ext4 images.

        Args:
            src (str): Source ext4 image full path
            dst (str): Destination sparse image full path
            desc (str): Human-readable description for logging (e.g., 'Boot', 'Root')

        Returns:
            bool: True if conversion succeeded, False otherwise

        Raises:
            Logs warning if img2simg tool is not found or conversion fails
        """
        try:
            subprocess.run(['img2simg', src, dst], check=True, capture_output=True, text=True)
            bb.note(f"{desc} partition sparse image created: {os.path.basename(dst)}")
            return True
        except subprocess.CalledProcessError as e:
            bb.warn(f"Failed to create sparse image for {desc} partition: {e.stderr}")
            return False
        except FileNotFoundError:
            bb.warn("img2simg not found. Install android-tools-native for sparse image support.")
            return False

    #
    # Process each partition file from WIC build output
    #
    # Iterate through all files in the WIC build directory and match them
    # against expected partition suffixes (.p1 for boot, .p2 for root)
    for filename in os.listdir(build_wic):
        for suffix, (part_name, desc) in partitions.items():
            # Skip files that don't match this partition suffix
            if not filename.endswith(suffix):
                continue

            src = os.path.join(build_wic, filename)

            # Deploy ext4 partition image
            # Create versioned filename and convenience symlink for ext4 image
            ext4_name = f"{image_name}-{part_name}.ext4"
            ext4_link = f"{link_prefix}-{part_name}.ext4"
            ext4_dst = os.path.join(deploy_dir, ext4_name)

            # Copy partition image to deploy directory
            shutil.copy2(src, ext4_dst)
            bb.note(f"{desc} partition deployed: {ext4_name}")

            # Create symlink: <basename>-<machine>-<partition>.ext4 -> <versioned>.ext4
            create_link(os.path.join(deploy_dir, ext4_link), ext4_name)
            bb.debug(1, f"Symlink created: {ext4_link} -> {ext4_name}")

            # Convert to Android sparse format (optional)
            # Sparse images are more efficient for flashing as they only contain
            # allocated blocks, reducing both image size and flash time
            if sparse_enabled:
                sparse_name = f"{image_name}-{part_name}.img"
                sparse_link = f"{part_name}.img"
                sparse_dst = os.path.join(deploy_dir, sparse_name)

                # Perform conversion and create symlink if successful
                if convert_to_sparse(ext4_dst, sparse_dst, desc):
                    create_link(os.path.join(deploy_dir, sparse_link), sparse_name)
                    bb.debug(1, f"Sparse symlink created: {sparse_link} -> {sparse_name}")

            # Found matching partition, no need to check other suffixes
            break
}

#
# Task Registration and Configuration
#
# Register the deployment task in the BitBake task dependency chain
# Execution order: do_image_wic -> do_deploy_wic_partitions -> do_image_complete
addtask deploy_wic_partitions after do_image_wic before do_image_complete

# Set working directory for the task
do_deploy_wic_partitions[dirs] = "${IMGDEPLOYDIR}"

# Task documentation for BitBake introspection (bitbake -c listtasks)
do_deploy_wic_partitions[doc] = "Deploy WIC partitions with optional sparse conversion"

#
# Conditional Task Execution
#
# Only run this task if 'wic' is included in IMAGE_FSTYPES
# If WIC is not enabled, remove the task entirely to avoid unnecessary processing
python __anonymous() {
    """
    Conditionally enable partition deployment task.

    This anonymous function runs during recipe parsing and removes the
    deployment task if WIC image generation is not enabled in IMAGE_FSTYPES.
    This prevents unnecessary task execution when WIC is not being used.
    """
    if 'wic' not in (d.getVar('IMAGE_FSTYPES') or ''):
        d.delVarFlag('do_deploy_wic_partitions', 'task')
}
