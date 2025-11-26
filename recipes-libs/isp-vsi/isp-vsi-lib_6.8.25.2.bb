SUMMARY = "DEEPX V3 ISP VSI library and media server"
DESCRIPTION = "ISP VSI library, sensor files, and media server for DEEPX V3 platform"
LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "^v3-.*"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'systemd', '', d)}

FILESEXTRAPATHS:prepend := "${THISDIR}:"

# Configuration
ISP_VSI_SENSOR ?= "os08a20"
ISP_VSI_BUILD_MODE ?= "release"
ISP_VSI_DAEMON_ENABLE ?= "0"

# Source files
SRC_URI = "\
    file://bin \
    file://sensor \
    file://debug \
    file://release \
"
SRC_URI:append = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', ' file://isp-media.service', '', d)}"
SRC_URI:append = "${@bb.utils.contains('ISP_VSI_DAEMON_ENABLE', '1', \
    bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', ' file://S60isp_media_serverd', '', d), '', d)}"

# Package files
FILES:${PN} += "\
    ${bindir}/* \
    ${libdir}/vsi/* \
    ${sysconfdir}/profile.d/isp-vsi-lib.sh \
"

FILES:${PN}:append = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', \
    ' ${systemd_system_unitdir}/isp-media.service ${sysconfdir}/ld.so.conf.d/isp-vsi-lib.conf', '', d)}"

FILES:${PN}:append = "${@bb.utils.contains('ISP_VSI_DAEMON_ENABLE', '1', \
    bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', ' ${sysconfdir}/rc5.d/S60isp_media_serverd', '', d), '', d)}"

# Skip QA checks for pre-built binaries
INSANE_SKIP:${PN} += "already-stripped ldflags file-rdeps arch textrel dev-so libdir"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'isp-media.service', '', d)}"
SYSTEMD_AUTO_ENABLE:${PN} = "${@bb.utils.contains('ISP_VSI_DAEMON_ENABLE', '1', 'enable', 'disable', d)}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

pkg_postinst:${PN}() {
    #!/bin/sh
    if ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'true', 'false', d)}; then
        [ -z "$D" ] && ldconfig
    fi
}

do_install() {
    local mode="${ISP_VSI_BUILD_MODE}"
    [ "${mode}" != "debug" ] && mode="release"

    # Install binaries and libraries
    install -d ${D}${bindir} ${D}${libdir}/vsi
    [ -d "${WORKDIR}/bin" ] && install -m 0755 "${WORKDIR}/bin"/* ${D}${bindir}/
    [ -f "${WORKDIR}/${mode}/bin/isp_media_server" ] && \
        install -m 0755 "${WORKDIR}/${mode}/bin/isp_media_server" ${D}${bindir}/
    [ -d "${WORKDIR}/${mode}/lib" ] && cp -a "${WORKDIR}/${mode}/lib"/* ${D}${libdir}/vsi/

    # Install sensor files
    for sensor in ${ISP_VSI_SENSOR}; do
        local sensor_dir="${D}${libdir}/vsi/sensor/${sensor}"
        install -d ${sensor_dir}

        [ -f "${WORKDIR}/sensor/isp_${sensor}.sh" ] && \
            install -m 0755 "${WORKDIR}/sensor/isp_${sensor}.sh" ${D}${libdir}/vsi/sensor/
        [ -d "${WORKDIR}/sensor/${sensor}/configs" ] && \
            cp -a "${WORKDIR}/sensor/${sensor}/configs"/* ${sensor_dir}/
        [ -d "${WORKDIR}/sensor/${sensor}/${mode}" ] && \
            cp -a "${WORKDIR}/sensor/${sensor}/${mode}"/* ${D}${libdir}/vsi/
    done

    # Install profile.d script
    install -d ${D}${sysconfdir}/profile.d
    cat > ${D}${sysconfdir}/profile.d/isp-vsi-lib.sh <<EOF
export LD_LIBRARY_PATH=${libdir}:${base_libdir}:${libdir}/vsi
EOF
    chmod 0755 ${D}${sysconfdir}/profile.d/isp-vsi-lib.sh

    # Install init system specific files
    if ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', 'true', 'false', d)}; then
        if [ "${ISP_VSI_DAEMON_ENABLE}" = "1" ]; then
            install -d ${D}${sysconfdir}/rc5.d
            [ -f "${WORKDIR}/S60isp_media_serverd" ] && \
                install -m 0755 "${WORKDIR}/S60isp_media_serverd" ${D}${sysconfdir}/rc5.d/
        fi
    fi

    if ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir} ${D}${sysconfdir}/ld.so.conf.d
        [ -f "${WORKDIR}/isp-media.service" ] && \
            install -m 0644 "${WORKDIR}/isp-media.service" ${D}${systemd_system_unitdir}/
        echo "${libdir}/vsi" > ${D}${sysconfdir}/ld.so.conf.d/isp-vsi-lib.conf
    fi

    chown -R root:root ${D}
}
