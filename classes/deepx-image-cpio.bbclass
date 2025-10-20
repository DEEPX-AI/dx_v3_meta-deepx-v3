# Rootfs cpio image specific configuration and deployment

# Create symbolic link for rootfs image : rootfs.cpio -> actual cpio file
IMAGE_ROOTFS_CPIO_NAME = "rootfs.cpio"

do_deploy_cpio() {
    link=${IMAGE_ROOTFS_CPIO_NAME}

    image="${IMAGE_LINK_NAME}.cpio"
    bbnote "Creating symbolic link ${link} for ${image}"

    if [ -L "${IMGDEPLOYDIR}/${image}" ]; then
        cd ${IMGDEPLOYDIR}
        rm -f "${link}"

        if ! ln -s "$(readlink "${image}")" "${link}"; then
            bbfatal "Failed to create ${link} link in ${IMGDEPLOYDIR}"
        fi
    fi

    image="${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.cpio"
    bbnote "Creating symbolic link ${link} for ${image}"

    if [ -L "${image}" ]; then
        cd ${DEPLOY_DIR_IMAGE}
        rm -f "${link}"

        if ! ln -s "$(readlink "${image}")" "${link}"; then
            bbfatal "Failed to create ${link} link in ${DEPLOY_DIR_IMAGE}"
        fi
    fi
}
# Add deploy_cpio task into the task graph:
addtask deploy_cpio after do_image_complete before do_build

# Skip do_deploy_cpio if image does not generate any cpio artifact
python () {
    fstypes = (d.getVar('IMAGE_FSTYPES') or '').split()

    # Match any token containing 'cpio' (covers cpio, cpio.gz, cpio.xz, etc.)
    if not any('cpio' in ft for ft in fstypes):
        bb.note('Skipping do_deploy_cpio (no cpio format in IMAGE_FSTYPES)')
        d.setVarFlag('do_deploy_cpio', 'noexec', '1')
}

