SUMMARY = "DEEPX V3 ISP VSI library and media server"
DESCRIPTION = "ISP VSI library, sensor files, and media server for DEEPX V3 platform"
LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "^v3-.*"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'systemd', '', d)}

FILESEXTRAPATHS:prepend := "${THISDIR}:"

# Source files
SRC_URI = "\
    file://bin \
    file://sensor \
    file://debug \
    file://release \
"
SRC_URI:append = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', ' file://S60isp_media_serverd', '', d)}"
SRC_URI:append = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', ' file://isp-media.service', '', d)}"

# Configuration
ISP_VSI_SENSOR ?= "os08a20"
ISP_VSI_BUILD_MODE ?= "release"

# Package files
FILES:${PN} += "${bindir}/* ${libdir}/vsi/*"
FILES:${PN}:append = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', \
    ' ${sysconfdir}/rc5.d/S60isp_media_serverd', \
    ' ${systemd_system_unitdir}/isp-media.service \
      ${sysconfdir}/profile.d/isp-vsi-lib.sh \
      ${sysconfdir}/ld.so.conf.d/isp-vsi-lib.conf', d)}"

# Skip QA checks for pre-built binaries
INSANE_SKIP:${PN} += "already-stripped ldflags file-rdeps arch textrel dev-so libdir"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'isp-media.service', '', d)}"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

pkg_postinst:${PN}() {
    #!/bin/sh
    # Update library cache for systemd (on target system only)
    if ${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'true', 'false', d)}; then
        if [ -z "$D" ]; then
            ldconfig
        fi
    fi
}

do_install() {
    local mode="${ISP_VSI_BUILD_MODE}"

    [ "${mode}" != "debug" ] && mode="release"

    local use_systemd="${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'systemd', 'true', 'false', d)}"
    local use_busybox="${@bb.utils.contains('VIRTUAL-RUNTIME_init_manager', 'busybox', 'true', 'false', d)}"

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

    # Install init system specific files
    if [ "${use_busybox}" = "true" ]; then
        # Busybox: SysV init script and /etc/profile
        install -d ${D}${sysconfdir}/rc5.d
        [ -f "${WORKDIR}/S60isp_media_serverd" ] && \
            install -m 0755 "${WORKDIR}/S60isp_media_serverd" ${D}${sysconfdir}/rc5.d/

        echo "export LD_LIBRARY_PATH=${libdir}:${base_libdir}:${libdir}/vsi" > ${D}${sysconfdir}/profile
    fi

    if [ "${use_systemd}" = "true" ]; then
        # Systemd: service unit, ld.so.conf.d, and profile.d
        install -d ${D}${systemd_system_unitdir}
        [ -f "${WORKDIR}/isp-media.service" ] && \
            install -m 0644 "${WORKDIR}/isp-media.service" ${D}${systemd_system_unitdir}/

        install -d ${D}${sysconfdir}/ld.so.conf.d
        echo "${libdir}/vsi" > ${D}${sysconfdir}/ld.so.conf.d/isp-vsi-lib.conf

        install -d ${D}${sysconfdir}/profile.d
        echo "export LD_LIBRARY_PATH=${libdir}:${base_libdir}:${libdir}/vsi" > ${D}${sysconfdir}/profile.d/isp-vsi-lib.sh
        chmod 0755 ${D}${sysconfdir}/profile.d/isp-vsi-lib.sh
    fi

    chown -R root:root ${D}
}
