#!/bin/sh
# $(basename $0) -p [port] -m [mode]
#

MODE_SELECT=""
ISP_SENSOR_LIB=libos08a20.so
ISP_SENSOR_SYM=OS08a20_IsiCamDrvConfig
ISP_SENSOR_DIR="/lib/vsi/sensor/os08a20"

# [index] = [sensor_port]:[mipi_id]:[sensor_mode]:[calibration json]:[manual json]:[auto json]
#
# - sensor_port: VI200
#    0  = VI2 port 0(RX0-4L)
#    4  = VI2 port 4(RX1-4L)
#    8  = VI2 port 8(RX0-2L)
#    10 = VI2 port10(RX1-2L)
# - mipi_id
#    0 = RX0-4L
#    1 = RX1-4L
#    2 = RX0-2L
#    3 = RX1-2L
# - sensor mode
#    0  = 1080p24     , 4lane,
#    1  = 1080p60     , 4lane,
#    3  = 2160p3.7(4K), 4lane,
#    14 = 1080p24     , 2lane
#    15 = 1080p60     , 2lane
#
SENSOR_MODE="
0= 0:0: 0:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
1= 0:0: 1:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
2= 0:0: 3:$ISP_SENSOR_DIR/OS08a20_4k.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
3= 4:1: 0:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
4= 4:1: 1:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
5= 4:1: 3:$ISP_SENSOR_DIR/OS08a20_4k.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
6= 8:2:14:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
7= 8:2:15:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
8=10:3:14:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
9=10:3:15:$ISP_SENSOR_DIR/OS08a20_1080p.json:$ISP_SENSOR_DIR/manual_ext.json:$ISP_SENSOR_DIR/auto.json
"
usage() {
    echo "Usage: $0 -m <mode>"
    echo "  -m <mode> : Specify the the sensor mode"
    echo "  -l        : List up the sensor modes"
    exit 1
}

MODE_LISTUP=false
while getopts "m:l" opt; do
    case ${opt} in
	m)
	    MODE_SELECT=$OPTARG
	    ;;
	l)
	    MODE_LISTUP=true
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

if [ $MODE_LISTUP = true ]; then
(
IFS='
'
    echo "[index] = [sensor_port]:[mipi_id]:[sensor_mode]:[calibration]:[manual]:[auto]"
    for m in $SENSOR_MODE; do
	m=$(echo "$m" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; /^\s*$/d')
	if [ -n "$m" ]; then
	    i=$(echo "$m" | cut -d'=' -f1 | tr -d '[:space:]')
	    m=$(echo "$m" | cut -d'=' -f2 | tr -d '[:space:]')
	    echo "[$i] = $m"
	fi
    done
    echo "- sensor_port: 0=VI2_0(RX0-4L), 4=VI2_4(RX1-4L), 8=VI2_8(RX0-2L), 10=VI2_10(RX1-2L)"
    echo "- mipi_id    : 0=RX0-4L, 1=RX1-4L, 2=RX0-2L, 3=RX1-2L"
)
    exit 0
fi

if [ -z $MODE_SELECT ]; then
	usage
fi

sensor_mode=$(echo "$SENSOR_MODE" | grep "^${MODE_SELECT}=")
if [ -z "$sensor_mode" ]; then
    echo "Error: not support mode: $MODE_SELECT"
    usage
fi
sensor_mode=$(echo "$sensor_mode" | cut -d'=' -f2 | tr -d '[:space:]')

ISP_SENSOR_PORT=$(echo "$sensor_mode" | cut -d':' -f1)
ISP_SENSOR_MIPI=$(echo "$sensor_mode" | cut -d':' -f2)
ISP_SENSOR_MODE=$(echo "$sensor_mode" | cut -d':' -f3)
ISP_SENSOR_CALI=$(echo "$sensor_mode" | cut -d':' -f4)
ISP_SENSOR_MANU=$(echo "$sensor_mode" | cut -d':' -f5)
ISP_SENSOR_AUTO=$(echo "$sensor_mode" | cut -d':' -f6)

echo "sensor port[$ISP_SENSOR_PORT]"
echo " - mipi_id     : $ISP_SENSOR_MIPI"
echo " - sensor mode : $ISP_SENSOR_MODE"
echo " - library     : $ISP_SENSOR_LIB"
echo " - calibration : $ISP_SENSOR_CALI"
echo " - manual      : $ISP_SENSOR_MANU"
echo " - auto        : $ISP_SENSOR_AUTO"

ISP_VSI_RPOC="/proc/vsi/isp_subdev0"
echo $ISP_SENSOR_PORT input_type=sensor > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT lib=$ISP_SENSOR_LIB > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT isi_sym=$ISP_SENSOR_SYM > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT mode=$ISP_SENSOR_MODE > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT calib=$ISP_SENSOR_CALI > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT manu_json=$ISP_SENSOR_MANU > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT auto_json=$ISP_SENSOR_AUTO > $ISP_VSI_RPOC;
echo $ISP_SENSOR_PORT mipi_id=$ISP_SENSOR_MIPI > $ISP_VSI_RPOC;
