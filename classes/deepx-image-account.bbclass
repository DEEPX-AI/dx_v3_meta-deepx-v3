# DEEPX Image Account Configuration Class
#
# Configures root and user accounts from distro.conf variables:
#   LINUX_ACCOUNT_ROOT_PASSWD_HASH    - Root password hash
#
#   LINUX_ACCOUNT_USER_NAME           - User account name
#   LINUX_ACCOUNT_USER_PASSWD_HASH    - User password hash
#   LINUX_ACCOUNT_USER_GROUPS         - User groups (e.g., "sudo,wheel")

inherit extrausers

# Build account commands dynamically: set EXTRA_USERS_PARAMS
python __anonymous() {
    root_pass = d.getVar('LINUX_ACCOUNT_ROOT_PASSWD_HASH')
    user_name = d.getVar('LINUX_ACCOUNT_USER_NAME')
    user_pass = d.getVar('LINUX_ACCOUNT_USER_PASSWD_HASH')
    user_groups = d.getVar('LINUX_ACCOUNT_USER_GROUPS')
    params = ""

    if root_pass:
        params = "usermod -p '%s' root;" % root_pass

    if user_name and user_pass:
        params += " useradd -p '%s' %s;" % (user_pass, user_name)
        if user_groups:
            params += " usermod -a -G %s %s;" % (user_groups, user_name)

    if params:
        d.setVar('EXTRA_USERS_PARAMS', params)
}

# Configure sudoers for sudo/wheel groups
setup_sudoers() {
    install -d ${IMAGE_ROOTFS}/etc/sudoers.d

    # Enable sudo group (password required)
    echo '%sudo ALL=(ALL) ALL' > ${IMAGE_ROOTFS}/etc/sudoers.d/sudo-group

    # Enable wheel group (password required)
    echo '%wheel ALL=(ALL) ALL' > ${IMAGE_ROOTFS}/etc/sudoers.d/wheel-group

    # Disable sudo lecture message
    echo 'Defaults lecture = never' > ${IMAGE_ROOTFS}/etc/sudoers.d/no-lecture
    chmod 0440 ${IMAGE_ROOTFS}/etc/sudoers.d/*
}

ROOTFS_POSTPROCESS_COMMAND += "setup_sudoers; "
