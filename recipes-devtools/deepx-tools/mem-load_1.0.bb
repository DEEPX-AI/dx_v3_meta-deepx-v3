SUMMARY = "Physical memory writer utility"
DESCRIPTION = "Utility to write file contents to physical memory addresses using mmap"
HOMEPAGE = "https://www.deepx.ai"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://mem_load.c;beginline=1;endline=8;md5=798cd73e0d28cfd775dd534afe572db5"

PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = "file://mem_load"

S = "${WORKDIR}/mem_load"

EXTRA_OEMAKE = "'CC=${CC}' 'CFLAGS=${CFLAGS}' 'LDFLAGS=${LDFLAGS}'"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake install DESTDIR=${D} bindir=${bindir}
}
