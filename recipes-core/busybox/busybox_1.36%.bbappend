# Setup file search paths for busybox 1.36.x versions
FILESEXTRAPATHS:prepend := "${THISDIR}/1.36:${THISDIR}:"

# Apply defconfig for busybox 1.36.x versions based on init manager
# - defconfig: Used when busybox is the init manager (CONFIG_INIT=y)
# - defconfig-systemd: Used when systemd is the init manager (CONFIG_INIT is not set)
SRC_URI:append = " \
    ${@' file://defconfig' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ' file://defconfig-systemd'} \
"

# Remove syslog.cfg when using systemd (systemd-journald replaces busybox-syslog)
SRC_URI:remove = "${@'' if d.getVar('VIRTUAL-RUNTIME_init_manager') == 'busybox' else ' file://syslog.cfg'}"

# Whether to split the suid apps into a seperate binary
BUSYBOX_SPLIT_SUID = "0"

# Apply custom defconfig as the final step in configuration
# This ensures our config overrides any other configuration changes
#
do_configure:append() {
    bbnote "Applying custom defconfig for busybox"

    # Determine which defconfig to use based on init manager
    if [ "${VIRTUAL-RUNTIME_init_manager}" = "busybox" ]; then
        defconfig_file="${WORKDIR}/defconfig"
        bbnote "Using defconfig (busybox as init manager)"
    else
        defconfig_file="${WORKDIR}/defconfig-systemd"
        bbnote "Using defconfig-systemd (systemd as init manager)"
    fi

    # Note: busybox.inc backs up .config and include/autoconf.h to .config.orig include/autoconf.h.orig
    # in do_configure and restores it in do_compile, so we need to modify .config.orig/autoconf.h.orig
    # instead in poky/meta/recipes-core/busybox/busybox.inc

    if [ -f "${defconfig_file}" ]; then
        bbnote "Found custom defconfig - applying to both .config and .config.orig"

        # Apply to current .config
        cp "${defconfig_file}" ${B}/.config

        # Also apply to .config.orig so it persists when busybox.inc restores it
        cp "${defconfig_file}" ${B}/.config.orig

        # Process the configuration to handle any new options
        cd ${B}
        yes "" | oe_runmake oldconfig 2>/dev/null || true

        # Update .config.orig and include/autoconf.h.orig with the processed configuration
        # This ensures the final config is what gets restored in do_compile
        cp ${B}/.config ${B}/.config.orig
        cp ${B}/include/autoconf.h ${B}/include/autoconf.h.orig

        bbnote "Custom defconfig applied to both .config and .config.orig"
        bbnote "Configuration will persist through busybox.inc's restore mechanism"
    else
        bbwarn "Custom defconfig not found: ${defconfig_file}"
    fi
}
