#!/bin/sh
#

UDC_FUNCTIONS=""
UDC_START=true

ID_VENDOR="0x1ff4"
ID_PRODUCT="0x0001"
MANUFACTURER="$(echo $(hostname))"
PRODUCT="UDC"
SERIALNUM="$(echo $(hostname))"
CONFIGURATION="UDC Configuration"

CONFIG_DIR="/sys/kernel/config"
GADGET_DIR="${CONFIG_DIR}/usb_gadget/g1"

UDC_FUNCTION_ADB="ffs.adb"
UDC_FUNCTION_ETH="rndis.usb0" # rndis.usb0 or ecm.usb0

udc_args() {
	for i in ${@}; do
	case ${i} in
		"adb")
			UDC_FUNCTIONS="${UDC_FUNCTIONS} adb";;
		"eth")
			UDC_FUNCTIONS="${UDC_FUNCTIONS} eth";;
		"start")
			UDC_START=true;;
		"stop")
			UDC_START=false;;
		serial=*)
			SERIALNUM="${i#serial=}";;
		*)
		echo "Usage: ${0} [adb|eth] start|stop [serial={serialnumber}]"
		exit 1;
	esac
	done
}

udc_start() {
	if [ ${UDC_START} = false ]; then
		return
	fi

	# if lo is not up, error cannot bind 'tcp:5037'
	ip link set lo up

	if ! mount | grep ${CONFIG_DIR} > /dev/null; then
		mount -t configfs none ${CONFIG_DIR}
	fi

	echo "Gadget dir   : ${GADGET_DIR}"
	echo "ID           : ${ID_VENDOR}, ${ID_PRODUCT}"
	echo "Manufacturer : ${MANUFACTURER}"
	echo "Product      : ${PRODUCT}"
	echo "Serial       : ${SERIALNUM}"

	# Create USB Device Descriptor
	mkdir -p ${GADGET_DIR}
	mkdir -p ${GADGET_DIR}/strings/0x409
	mkdir -p ${GADGET_DIR}/configs/c.1
	mkdir -p ${GADGET_DIR}/configs/c.1/strings/0x409

	# Set USB Device Descriptor
	echo "${ID_VENDOR}"     > ${GADGET_DIR}/idVendor
	echo "${ID_PRODUCT}"    > ${GADGET_DIR}/idProduct
	echo "${MANUFACTURER}"  > ${GADGET_DIR}/strings/0x409/manufacturer
	echo "${PRODUCT}"       > ${GADGET_DIR}/strings/0x409/product
	echo "${SERIALNUM}"     > ${GADGET_DIR}/strings/0x409/serialnumber;
	# Set USB Config Descriptor
	echo "${CONFIGURATION}" > ${GADGET_DIR}/configs/c.1/strings/0x409/configuration

	# Create/Set USB Interface Descriptor (Functions)
	for f in ${UDC_FUNCTIONS}; do
		if [ ${f} = "adb" ]; then
			gadget_fnc=${UDC_FUNCTION_ADB}
		elif [ ${f} = "eth" ]; then
			gadget_fnc=${UDC_FUNCTION_ETH}
		fi

		echo "Function     : ${f}"
		mkdir -p ${GADGET_DIR}/functions/${gadget_fnc}
		if [ ! -e "${GADGET_DIR}/configs/c.1/${gadget_fnc}" ]; then
			# Link USB Interface Descriptor (Functions)
			ln -s ${GADGET_DIR}/functions/${gadget_fnc} ${GADGET_DIR}/configs/c.1;
		fi

		if [ ${f} = "adb" ]; then
			echo "Run ADB Daemon"
			gadget_dev="/dev/usb-ffs/adb"
			mkdir -p ${gadget_dev}
			if ! mount | grep ${gadget_dev} > /dev/null; then
				mount -o uid=2000,gid=2000 -t functionfs adb ${gadget_dev}
			fi
			adbd &
			sleep 1
		fi
	done

	# Bring up USB (RESET)
	device="$(ls /sys/class/udc/ 2>/dev/null | head -1)"
	if [ -z "${device}" ]; then
		echo "Error: No UDC device found"
		return 1
	fi
	echo "Bring up ${device} > '${GADGET_DIR}/UDC' ..."
	echo ${device} > ${GADGET_DIR}/UDC
	
	# Bring up ethernet interface if eth function is enabled
	if echo "${UDC_FUNCTIONS}" | grep -q "eth"; then
		echo "Bringing up usb0 ethernet interface ..."
		ip link set usb0 up
	fi
}

udc_stop() {
	# First, disconnect UDC to safely disable gadget
	if [ -f "${GADGET_DIR}/UDC" ]; then
		echo "" > ${GADGET_DIR}/UDC
		echo "UDC disconnected"
	fi

	for f in ${UDC_FUNCTIONS}; do
		if [ ${f} = "adb" ]; then
			gadget_fnc=${UDC_FUNCTION_ADB}
			gadget_dev="/dev/usb-ffs/adb"
			pid=$(pidof adbd 2>/dev/null)
			if [ -n "${pid}" ]; then
				kill ${pid}
				sleep 1
			fi
			if mount | grep ${gadget_dev} > /dev/null; then
				umount -l ${gadget_dev}
				rmdir ${gadget_dev} 2>/dev/null
			fi
		elif [ ${f} = "eth" ]; then
			gadget_fnc=${UDC_FUNCTION_ETH}
		fi

		if [ -d "${GADGET_DIR}/functions/${gadget_fnc}" ]; then
		    rm ${GADGET_DIR}/configs/c.1/${gadget_fnc} > /dev/null 2>&1
		    rmdir ${GADGET_DIR}/functions/${gadget_fnc} > /dev/null 2>&1
		fi
		echo "Stop ${gadget_fnc} ..."
	done

	rmdir ${GADGET_DIR}/configs/c.1/strings/0x409 > /dev/null 2>&1
	rmdir ${GADGET_DIR}/configs/c.1 > /dev/null 2>&1
	rmdir ${GADGET_DIR}/strings/0x409 > /dev/null 2>&1
	rmdir ${GADGET_DIR} > /dev/null 2>&1
	echo "USB gadget stopped"
}

udc_args ${@}

if [ -z "${UDC_FUNCTIONS}" ]; then
	UDC_FUNCTIONS="adb eth"
fi

if [ ${UDC_START} = false ]; then
	udc_stop
else
	udc_stop  # Always stop first to clean up
	udc_start
fi
