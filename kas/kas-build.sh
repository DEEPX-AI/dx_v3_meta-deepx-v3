#!/bin/bash
# DEEPX V3 KAS Build Helper Script
# Quick reference for common build commands

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAS_DIR="${SCRIPT_DIR}"

# Default values
MACHINE="v3-evb"
INIT_SYSTEM=""
IMAGE_TYPE=""
ACTION="build"
SHOW_LIST=0
BUILD_SDK=0

# Build directory configuration
# Can be overridden with -b option
BUILD_DIR="${SCRIPT_DIR}/../../build"

function logerr() { echo -e "\033[1;31m$*\033[0m" >&2; }
function logmsg() { echo -e "\033[0;33m$*\033[0m"; }
function logext() {
	echo -e "\033[1;31m$*\033[0m" >&2
	exit 1
}

print_header() {
	logmsg "========================================"
	logmsg "$1"
	logmsg "========================================"
}

print_usage() {
	print_header "DEEPX V3 KAS Build System"
	echo ""
	echo "Usage: $0 -t <init> -i <image> [OPTIONS]"
	echo ""
	echo "Required Options:"
	echo "  -t <init>       System : systemd | busybox"
	echo "  -i <image>      Image  : image | ramfs"
	echo ""
	echo "Optional:"
	echo "  -m <machine>    Machine name (default: ${MACHINE})"
	echo "                  Available machines:"
	ls -1 "${KAS_DIR}"/v3-*.yml | sed 's|.*/||' | sed 's/.yml$//' | sed 's/^/                    /'
	echo "  -b <dir>        Build directory (default: $(realpath "${BUILD_DIR}"))"
	echo "  -s              Enter shell instead of building"
	echo "  -S              Build SDK (populate_sdk)"
	echo "  -l              List all available combinations"
	echo "  -h              Show this help message"
	echo ""
	echo "Note:"
	echo "  Downloads: \${BUILD_DIR}/downloads"
	echo "  Sstate  : \${BUILD_DIR}/sstate-cache"
	echo ""
}

list_combinations() {
	print_header "Available Build Combinations"
	echo ""
	logmsg " systemd + image (ext4/wic)"
	echo " $ $0 -t systemd -i image -m <machine>"
	echo ""
	logmsg " systemd + ramfs (cpio)"
	echo " $ $0 -t systemd -i ramfs -m <machine>"
	echo ""
	logmsg " busybox + image (ext4/wic)"
	echo " $ $0 -t busybox -i image -m <machine>"
	echo ""
	logmsg " busybox + ramfs (cpio)"
	echo " $ $0 -t busybox -i ramfs -m <machine>"
	echo ""
	logmsg "Available machines:"
	ls -1 "${KAS_DIR}"/v3-*.yml | sed 's|.*/||' | sed 's/.yml$//' | sed 's/^/  - /'
	echo ""
}

# Parse command line options with getopts
while getopts "t:i:m:b:sSlh" opt; do
	case ${opt} in
		t)
			INIT_SYSTEM="${OPTARG}"
			;;
		i)
			IMAGE_TYPE="${OPTARG}"
			;;
		m)
			MACHINE="${OPTARG}"
			;;
		b)
			# Check if build dir contains path separator or starts with /
			if [[ "${OPTARG}" == */* ]] || [[ "${OPTARG}" == /* ]]; then
				# Use as-is if it's a path (absolute or relative)
				BUILD_DIR="${OPTARG}"
			else
				# Otherwise, use default parent directory
				BUILD_DIR="../../${OPTARG}"
			fi
			;;
		s)
			ACTION="shell"
			;;
		S)
			BUILD_SDK=1
			;;
		l)
			SHOW_LIST=1
			;;
		h)
			print_usage
			exit 0
			;;
		\?)
			logerr "Error: Invalid option -${OPTARG}"
			echo ""
			print_usage
			exit 1
			;;
		:)
			logerr "Error: Option -${OPTARG} requires an argument"
			echo ""
			print_usage
			exit 1
			;;
	esac
done

shift $((OPTIND - 1))

# Export build directory for KAS
mkdir -p ${BUILD_DIR}
export KAS_BUILD_DIR="${BUILD_DIR}"

# Show list if requested
if [ ${SHOW_LIST} -eq 1 ]; then
	list_combinations
	 exit 0
fi

# Validate required parameters
if [ -z "${INIT_SYSTEM}" ] || [ -z "${IMAGE_TYPE}" ]; then
	logerr "Error: Init system (-t) and image type (-i) are required"
	echo ""
	print_usage
	exit 1
fi

IMAGE_NAME="deepx-image"
# Validate init system
case ${INIT_SYSTEM} in
	systemd)
		IMAGE_NAME="${IMAGE_NAME}-systemd"
		;;
	busybox)
		IMAGE_NAME="${IMAGE_NAME}-busybox-init"
		;;
	*)
		logerr "Error: Invalid init system '${INIT_SYSTEM}'"
		logmsg "Valid options: systemd, busybox"
		exit 1
		;;
esac

# Validate image type
case ${IMAGE_TYPE} in
	image)
		IMAGE_NAME="${IMAGE_NAME}-image"
		;;
	ramfs)
		IMAGE_NAME="${IMAGE_NAME}-initramfs"
		;;
	*)
		logerr "Error: Invalid image type '${IMAGE_TYPE}'"
		logmsg "Valid options: image, ramfs"
		exit 1
		;;
esac

# Machine config file
MACHINE_FILE="${KAS_DIR}/${MACHINE}.yml"

# Check if machine file exists
if [ ! -f "${MACHINE_FILE}" ]; then
	logerr "Error: Machine file not found: ${MACHINE_FILE}"
	logmsg "Available machines:"
	ls -1 "${KAS_DIR}"/v3-*.yml | sed 's|.*/||' | sed 's/.yml$//' | sed 's/^/  - /'
	exit 1
fi

# Build configuration strings
# Use combined configuration file (init + image type)
CONFIG_FILE="${KAS_DIR}/${INIT_SYSTEM}-${IMAGE_TYPE}.yml"
KAS_CONFIG="${MACHINE_FILE}:${CONFIG_FILE}"

# Execute action
logmsg "Machine     : ${MACHINE}"
logmsg "Init        : ${INIT_SYSTEM}"
logmsg "Image       : ${IMAGE_TYPE}"
logmsg "Image name  : ${IMAGE_NAME}"
logmsg "Build Dir   : $(realpath "${KAS_BUILD_DIR}")"
logmsg "Config      : ${KAS_CONFIG}"

if [ "${ACTION}" = "build" ]; then
	if [ ${BUILD_SDK} -eq 1 ]; then
		target="SDK"
		options="-- -c populate_sdk ${IMAGE_NAME}"
		print_header "Building SDK for ${INIT_SYSTEM} + ${IMAGE_TYPE}"
	else
		target="Image"
		options=""
		print_header "Building ${INIT_SYSTEM} + ${IMAGE_TYPE} image"
	fi
	logmsg "Target      : ${target}"
	echo ""
	command="kas build ${KAS_CONFIG} ${options}"

elif [ "${ACTION}" = "shell" ]; then
	print_header "Entering ${INIT_SYSTEM} build shell"
	echo ""
	command="kas shell ${KAS_CONFIG}"
fi

logmsg "$ ${command}"
echo ""
bash -c "${command}"

