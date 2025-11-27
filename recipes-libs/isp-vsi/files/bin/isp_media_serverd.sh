#!/bin/sh

DAEMON="/usr/bin/isp_media_server"
MODULE_SCRIPT="/usr/bin/isp_module.sh"
SENSOR_SCRIPT="/usr/lib/vsi/sensor/isp_os08a20.sh"
# refer to SENSOR_SCRIPT
SENSOR_COMMANDS="
$SENSOR_SCRIPT -m 1;
$SENSOR_SCRIPT -m 4;
$SENSOR_SCRIPT -m 7;
$SENSOR_SCRIPT -m 9;
"

DEBUG_LEVEL=0 # NONE:0, ERROR:1, WARNING:2, FIXME:3, INFO:4, DEBUG:5, LOG:6, TRACE:7, VERBOSE:8
TRACE_LEVEL=0 # NONE:0, INFO:1, WARNING:2, ERROR:3, ALL:7

PIDFILE="/var/run/$(basename "$DAEMON").pid"
CUR_TTY=$(tty)

# Set ISP-VSI library path
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/vsi

start() {
    # Load modules
    if [ -f "$MODULE_SCRIPT" ]; then
        /bin/sh -c "$MODULE_SCRIPT -l"
    fi

    # Setup sensor "/proc/vsi/isp_subdev0"
    if [ -n "$SENSOR_SCRIPT" ] || [ -f "$SENSOR_SCRIPT" ]; then
(
IFS='
'
	for c in $SENSOR_COMMANDS; do
	    cmd=$(echo "$c" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; /^\s*$/d')
	    if [ -n "$cmd" ]; then
		echo "$ $cmd"
		/bin/sh -c "$cmd"
            fi
	done
)
    fi

    printf "\nStarting %s - '%s', log:%d, trace:%d: " \
		"$DAEMON" "$SENSOR_SCRIPT" "$DEBUG_LEVEL" "$TRACE_LEVEL"

    # shellcheck disable=SC2086 # we need the word splitting
    # start-stop-daemon -b -m -S -q -p "$PIDFILE" -x "$DAEMON" --
    if [ $DEBUG_LEVEL = 0 ] && [ $TRACE_LEVEL = 0 ]; then
	# no output
	start-stop-daemon -b -m -S -q -p "$PIDFILE" -x "$DAEMON" --
    else
	# output
	start-stop-daemon -b -m -S -q -p "$PIDFILE" -x /bin/sh -- -c "\
			export ISP_LOG_LEVEL='$DEBUG_LEVEL'; \
			export TRACE_LOG_LEVEL='$TRACE_LEVEL'; \
			exec $DAEMON  > $CUR_TTY 2>&1"
    fi
    status=$?
    if [ "$status" -eq 0 ]; then
        echo "OK"
    else
        echo "FAIL"
    fi
    return "$status"
}

stop() {
    printf 'Stopping %s: ' "$DAEMON"
    start-stop-daemon -K -q -p "$PIDFILE"
    status=$?
    if [ "$status" -eq 0 ]; then
        rm -f "$PIDFILE"
        echo "OK"
    else
        echo "FAIL"
    fi
    return "$status"
}

restart() {
    stop
    sleep 1
    start
}

usage() {
    echo "Usage: $0 -c <start|stop|restart> [-d <debug_level>] [-t <trace level>] [-s <sensor script>]"
    echo "  -c <start|stop|restart> : Specify the command to perform."
    echo "  -s <sensor script>      : Specify the the sensor config script"
    echo "                          : Default: $SENSOR_SCRIPT"
    echo "  -d <debug level>        : Set the debug level (0-8). Default is 0."
    echo "                          : NONE:0, ERROR:1, WARNING:2, FIXME:3, INFO:4, DEBUG:5, LOG:6, TRACE:7, VERBOSE:8"
    echo "  -t <trace level>        : Set the trace lebel (0, 1, 2, 3, 7). Default is 0."
    echo "                          : NONE:0, INFO:1, WARNING:2, ERROR:3, ALL:7"
    exit 1
}

# Parse command-line options
while getopts "c:d:t:s:" opt; do
    case ${opt} in
	c)
	    COMMAND=$OPTARG
	    ;;
	d)
	    DEBUG_LEVEL=$OPTARG
	    ;;
	t)
	    TRACE_LEVEL=$OPTARG
	    ;;
	s)
	    SENSOR_SCRIPT=$OPTARG
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    usage
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    usage
	    ;;
    esac
done

if [ -z $COMMAND ]; then
	usage
fi

$COMMAND
