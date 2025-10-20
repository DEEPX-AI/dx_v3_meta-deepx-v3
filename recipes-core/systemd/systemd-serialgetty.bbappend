FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Auto login configuration variables
LINUX_ACCOUNT_ROOT_AUTOLOGIN ??= ""
LINUX_ACCOUNT_USER_AUTOLOGIN ??= ""
LINUX_ACCOUNT_AUTOLOGIN_TTY ??= "ttyAMA0"

# Add auto login template if enabled
SRC_URI += "${@'file://systemd-autologin.conf' \
            if d.getVar('LINUX_ACCOUNT_ROOT_AUTOLOGIN') or \
               d.getVar('LINUX_ACCOUNT_USER_AUTOLOGIN') \
            else ''}"

do_install:append() {
    # Determine auto login user (root has priority over regular user)
    if [ -n "${LINUX_ACCOUNT_ROOT_AUTOLOGIN}" ]; then
        autologin_user="root"
    elif [ -n "${LINUX_ACCOUNT_USER_AUTOLOGIN}" ]; then
        autologin_user="${LINUX_ACCOUNT_USER_NAME}"
    else
        autologin_user=""
    fi

    # Install auto login drop-in if enabled
    if [ -n "${autologin_user}" ]; then
        tty="${LINUX_ACCOUNT_AUTOLOGIN_TTY}"
        dropin_dir="${D}${sysconfdir}/systemd/system/serial-getty@${tty}.service.d"

        bbnote "Configuring auto login: ${autologin_user} on ${tty}"
        install -d ${dropin_dir}
        sed "s|@AUTOLOGIN_USER@|${autologin_user}|g" \
            ${WORKDIR}/systemd-autologin.conf > ${dropin_dir}/autologin.conf
    fi
}

# Conditionally package auto login drop-in file
FILES:${PN}:append = " ${@'%s/systemd/system/serial-getty@%s.service.d/' % \
                        (d.getVar('sysconfdir'), \
                         d.getVar('LINUX_ACCOUNT_AUTOLOGIN_TTY')) \
                      if d.getVar('LINUX_ACCOUNT_ROOT_AUTOLOGIN') or \
                         d.getVar('LINUX_ACCOUNT_USER_AUTOLOGIN') \
                      else ''}"
