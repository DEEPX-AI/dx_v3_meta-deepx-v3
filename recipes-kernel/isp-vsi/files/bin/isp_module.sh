#!/bin/sh

MODULE_DIR="/lib/modules/6.6.8/updates"

MODULES="
	${MODULE_DIR}/vvcam_mipi.ko
	${MODULE_DIR}/vvcam_vi.ko
	${MODULE_DIR}/vvcam_isp.ko
	${MODULE_DIR}/vvcam_vb.ko
	${MODULE_DIR}/vvcam_isp_subdev.ko
	${MODULE_DIR}/vvcam_video.ko
	${MODULE_DIR}/vsensor.ko
"

get_module_name() {
	module="$1"
	basename "${module}" .ko
}

module_loaded() {
	name="$1"
	grep -E "^${name}\>" /proc/modules >/dev/null 2>&1
}

module_load() {
	for module in $MODULES; do
		name=$(get_module_name "$module")
		if ! module_loaded "$name"; then
			echo "load  :$name"
			insmod "$module"
		fi
	done
}

module_unload() {
	local REVERSED=""
	for module in $MODULES; do
		REVERSED="$module $REVERSED"
	done
	for module in $REVERSED; do
		name=$(get_module_name "$module")
		if module_loaded "$name"; then
			echo "unload: $name"
			rmmod "$name"
		fi
	done
}

case "$1" in
	-l) module_load;;
	-u) module_unload;;
	-r) module_unload
	    module_load;;
	*)  echo "Usage: $0 -l[insmod] | -u[rmmod] | -r[reload]"
	    exit 1;;
esac
