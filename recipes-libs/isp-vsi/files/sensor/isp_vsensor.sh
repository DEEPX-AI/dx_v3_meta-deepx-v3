#!/bin/sh

ISP_INPUT_PORT=12
ISP_SENSOR_LIB=libdeepx_vs.so
ISP_SENSOR_SYM=DEEPX_VS_IsiCamDrvConfig

echo $ISP_INPUT_PORT input_type=sensor > /proc/vsi/isp_subdev0;
echo $ISP_INPUT_PORT lib=$ISP_SENSOR_LIB > /proc/vsi/isp_subdev0;
echo $ISP_INPUT_PORT isi_sym=$ISP_SENSOR_SYM > /proc/vsi/isp_subdev0;
echo $ISP_INPUT_PORT mode=0 > /proc/vsi/isp_subdev0;
