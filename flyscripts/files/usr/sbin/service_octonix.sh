#!/bin/sh
#
# Push data to OctoniX service
#
CLOUD="http://esp8266.flymon.net:81/"

##################

get_date(){
  DATE=`date +%G-%m-%d`
}

get_time(){
  TIME="`date +%H:%M:%S` MSK"
}

get_name(){
  NAME=`uci get system.@system[0].hostname`
}

get_macid(){
  MACID=`ifconfig eth0 | grep HWaddr | awk '{FS=" "; if(NR==1) {print $5}};' | tr -d ':' | tr 'a-z' 'A-Z'`
}

get_wanif(){
  WANIF=`route | awk '/default/ {print $8}' | head -n 1`
}

get_wanip(){
  WANIP=`ifconfig $WANIF | grep 'Mask:' | tr ':' ' ' | awk '{print $3}' | head -n 1`
}

get_memory(){
  MEMORY=`free | awk '/Mem:/ {print $4}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_uptime(){
  UPTIME=`cat /proc/uptime | cut -d '.' -f 1 | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_wlmod(){
  WLMOD=`uci get wireless.@wifi-iface[0].mode`
}

get_wlcon(){
  WLCON=`iwinfo wlan0 assoclist | grep 'dBm' | wc -l | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_rssi(){
  RSSI=`iw wlan0 link | awk '/signal:/ {print $2}' | tail -n 1 | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_method(){
  if [ -O /usr/bin/httping ] ; then
    PUSHCMD="httping -q -G -c 1 -t 5 -g"
  else
    PUSHCMD="wget -q -O /dev/null"
  fi
  METH=`echo $PUSHCMD | awk '{print $1}'`
}

##################

get_sensor_amh(){
  AMH=`am2321 -r | awk '/Humidity/ {print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$' ; sleep 2`
}

get_sensor_amt(){
  AMT=`am2321 -r | awk '/Temperature/ {print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_bmpp(){
  BMPP=`bmp085 | awk '/Pressure/ {print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_bmpt(){
  BMPT=`bmp085 | awk '/Temperature/ {print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_ds(){
  DS=`ds1621 | awk '{print $1}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_inac(){
  INAC=`ina219 -b 0 -w -c | awk '{print $1}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_inav(){
  INAV=`ina219 -b 0 -w -v | awk '{print $1}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_lm(){
  LM=`lm75 72 | awk '{print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_dsw(){
  DSW=`awk -F= '/t=/ {printf "%.02f\n", $2/1000}' /sys/bus/w1/drivers/w1_slave_driver/*/w1_slave | tr '\n' ' '`
  DSW1=`echo $DSW | awk '{print $1}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
  DSW2=`echo $DSW | awk '{print $2}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
  DSW3=`echo $DSW | awk '{print $3}' | egrep '^[-+]?[0-9]*\.?[0-9]+$'`
}

get_sensor_button1(){
  BUTTON1=`cat /sys/kernel/debug/gpio | grep "btn1" | awk '{print $5}'`
  #
  if [[ "$BUTTON1" == 'lo' ]]; then
    ENERGY="1"
  elif [[ "$BUTTON1" == 'hi' ]]; then
    ENERGY="0"
  fi
}

##################

get_date; get_time; get_name; get_macid; get_wanif; get_wanip; get_memory; get_uptime; get_wlmod; get_wlcon; get_rssi; get_method;
get_sensor_amh; get_sensor_amt; get_sensor_bmpp; get_sensor_bmpt; get_sensor_ds; get_sensor_inac; get_sensor_inav; get_sensor_lm; get_sensor_dsw; get_sensor_button1

SYSTEM="host=$NAME&mac=$MACID&wanif=$WANIF&wanip=$WANIP&freemem=$MEMORY&uptime=$UPTIME&wlmod=$WLMOD&wlcon=$WLCON&rssi=$RSSI&method=$METH"
SENSOR="amh=$AMH&amt=$AMT&bmpp=$BMPP&bmpt=$BMPT&ds=$DS&lm=$LM&inac=$INAC&inav=$INAV&dsw1=$DSW1&dsw2=$DSW2&dsw3=$DSW3&energy=$ENERGY"

$PUSHCMD "$CLOUD?$SYSTEM&$SENSOR" && logger -t service_octonix "$CLOUD?$SYSTEM&$SENSOR"
