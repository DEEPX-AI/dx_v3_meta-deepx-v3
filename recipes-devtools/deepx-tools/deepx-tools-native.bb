# Copyright (C) 2025 deepx.ai. or its subsidiaries

SUMMARY = "DEEPX V3 tools"
HOMEPAGE = "https://deepx.ai/"
LICENSE = "CLOSED"

SRC_URI = "git://git@github.com/DEEPX-AI/dx_v3_linux_tools.git;protocol=ssh;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

# Inherit native for host-side build
inherit native

# Tools to be deployed
XMODEM_TOOL_DIR = "xmodem"

SCRIPTS_TO_DEPLOY = "scripts/mk_extractimg.sh \
        scripts/mk_ramimg.sh \
        scripts/fastboot-download.sh \
        scripts/dfu-download.sh \
        scripts/flash-update.sh \
        scripts/boot-download.sh \
        scripts/xmodem-download.sh \
        scripts/mk_ext4img.sh \
        scripts/mk_bootparam.sh"

# Extract machine suffix (remove 'v3-' prefix from MACHINE)
def get_machine_suffix(d):
    machine = d.getVar('MACHINE')
    if machine and machine.startswith('v3-'):
        return machine[3:]  # Remove 'v3-' prefix
    return machine

MACHINE_SUFFIX = "${@get_machine_suffix(d)}"
FLASH_TABLE_FILE = "scripts/flash_table_${MACHINE_SUFFIX}.txt"

JTAGS_TO_DEPLOY = "jtag/v3_cm0_attach.cmm \
        jtag/v3_a53_attach.cmm \
        jtag/v3_a53_attach_smp.cmm \
        jtag/v3_linux_boot.cmm"

do_compile() {
    # Build xmodem tool
    bbnote "Building xmodem tool"
    if [ -d "${S}/${XMODEM_TOOL_DIR}" ]; then
        oe_runmake -C "${S}/${XMODEM_TOOL_DIR}" "BUILD_DIR=${B}/xmodem"
    else
        bbfatal "xmodem directory not found in source"
    fi

    # Modify JTAG files - replace &DIR="../../outputs" with &DIR=".."
    bbnote "Processing JTAG files for DIR path modification"
    for f in ${JTAGS_TO_DEPLOY}; do
        if [ -f "${S}/${f}" ]; then
            # Create backup and modify file
            sed -i 's/&DIR="\.\.\/\.\.\/outputs"/\&DIR="\.\.\"/g' "${S}/${f}"
            bbnote "Modified DIR path in ${f}"
       fi
    done
}

do_install() {
    # Create installation directories
    bin_dir="${D}"
    script_dir="${D}"
    jtag_dir="${D}/jtag"

    if ! install -d "${jtag_dir}"; then
        bbfatal "Failed to create jtag directory: ${jtag_dir}"
    fi

    # Install compiled xmodem tool
    if ! install -m 0755 "${B}/xmodem/xmodem" "${bin_dir}"; then
        bbfatal "Failed to install xmodem tool"
    fi
    bbnote "Installed xmodem tool to ${bin_dir}"

    # Install specified script tools
    for f in ${SCRIPTS_TO_DEPLOY}; do
        if [ -f "${S}/${f}" ]; then
            cp -p "${S}/${f}" "${script_dir}"
            bbnote "Installed ${f} to ${script_dir}"
        fi
    done

    # Install machine-specific flash table file
    if [ -f "${S}/${FLASH_TABLE_FILE}" ]; then
        cp -p "${S}/${FLASH_TABLE_FILE}" "${script_dir}"
        bbnote "Installed ${FLASH_TABLE_FILE} to ${script_dir}"
    else
        bbwarn "Machine-specific flash table file not found: ${FLASH_TABLE_FILE}"
    fi

    # Install specified jtags tools
    for f in ${JTAGS_TO_DEPLOY}; do
        if [ -f "${S}/${f}" ]; then
            cp -p "${S}/${f}" "${jtag_dir}"
            bbnote "Installed ${f} to ${jtag_dir}"
        fi
    done
}

do_deploy() {
    bin_dir="${D}"
    script_dir="${D}"
    jtag_dir="${D}/jtag"

    # Ensure deploy directory exists
    install -d "${DEPLOY_DIR_IMAGE}"

    # Deploy compiled xmodem tool
    if ! install -m 0755 "${bin_dir}/xmodem" "${DEPLOY_DIR_IMAGE}"; then
        bbfatal "Failed to deploy xmodem tool"
    fi
    bbnote "Deploy xmodem tool to ${bin_dir}"

    # Deploy specified script tools
    for f in ${SCRIPTS_TO_DEPLOY}; do
        if [ -f "${script_dir}/$(basename ${f})" ]; then
            cp -p "${script_dir}/$(basename ${f})" "${DEPLOY_DIR_IMAGE}"
            bbnote "Deploy ${script_dir}/$(basename ${f}) to ${DEPLOY_DIR_IMAGE}"
        fi
    done

    # Deploy machine-specific flash table file
    if [ -f "${script_dir}/$(basename ${FLASH_TABLE_FILE})" ]; then
        cp -p "${script_dir}/$(basename ${FLASH_TABLE_FILE})" "${DEPLOY_DIR_IMAGE}"
        bbnote "Deploy ${script_dir}/$(basename ${FLASH_TABLE_FILE}) to ${DEPLOY_DIR_IMAGE}"
    fi

    # Deploy specified jtags tools
    if ! cp -r ${jtag_dir} ${DEPLOY_DIR_IMAGE}; then
        bbfatal "Failed to deploy jtag tools to deploy directory"
    fi

    bbnote "BSP tools deployment completed to ${DEPLOY_DIR_IMAGE}"
}

# Clean deployed files when cleanall is executed
do_cleandeploy() {
    # Remove xmodem tool
    if [ -f "${DEPLOY_DIR_IMAGE}/xmodem" ]; then
        rm "${DEPLOY_DIR_IMAGE}/xmodem"
    fi

    # Remove specified script tools
    for f in ${SCRIPTS_TO_DEPLOY}; do
        if [ -f "${DEPLOY_DIR_IMAGE}/$(basename ${f})" ]; then
            rm "${DEPLOY_DIR_IMAGE}/$(basename ${f})"
        fi
    done

    # Remove machine-specific flash table file
    if [ -f "${DEPLOY_DIR_IMAGE}/$(basename ${FLASH_TABLE_FILE})" ]; then
        rm "${DEPLOY_DIR_IMAGE}/$(basename ${FLASH_TABLE_FILE})"
    fi

    # Remove specified jtags tools
    if [ -d "${DEPLOY_DIR_IMAGE}/jtag" ]; then
        rm -rf "${DEPLOY_DIR_IMAGE}/jtag"
    fi
}

# Deploy task configuration
addtask deploy after do_install before do_build
addtask cleandeploy after do_clean

do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_cleanall[postfuncs] += "do_cleandeploy"
