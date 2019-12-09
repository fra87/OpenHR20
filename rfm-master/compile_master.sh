#!/bin/bash

set -o nounset
set -o errexit

# save script directory (to launch makefile in this folder)
SCRIPTPATH="${0%/*}"

# Arduino shares HW configuration with NANODE
HW=NANODE
KEY0=01
KEY1=23
KEY2=45
KEY3=67
KEY4=89
KEY5=ab
KEY6=cd
KEY7=ef
RFM_FREQ=868

while [ "$#" -ne 0 ]; do
	if [ "$1" == "--key" ]; then
		shift;
		KEY0=$1; KEY1=$2; KEY2=$3; KEY3=$4;
		KEY4=$5; KEY5=$6; KEY6=$7; KEY7=$8;
		shift; shift; shift; shift;
		shift; shift; shift; shift;
	elif [ "$1" == "--HW" ] || [ "$1" == "--hw" ]; then
		HW=$2; shift; shift;
	elif [ "$1" == "--pass" ]; then
		PASSPHRASE=$2; shift; shift;
		HASHED=$(echo -n "$PASSPHRASE" | sha256sum)
		KEY0="${HASHED:0:2}"
		KEY1="${HASHED:2:2}"
		KEY2="${HASHED:4:2}"
		KEY3="${HASHED:6:2}"
		KEY4="${HASHED:8:2}"
		KEY5="${HASHED:10:2}"
		KEY6="${HASHED:12:2}"
		KEY7="${HASHED:14:2}"
	elif [ "$1" == "--freq" ]; then
		RFM_FREQ=$2; shift; shift;
	else
		echo "unknown options starting at $*"
		echo "e.g. $0 [--key <k0> <k1> <k2> <k3> <k4> <k5> <k6> <k7>] [--HW NANODE|JEENODE|...] [--freq <freq>] [--pass <passphrase>]"
		echo "defaults: --key $KEY0 $KEY1 $KEY2 $KEY3 $KEY4 $KEY5 $KEY6 $KEY7 --HW $HW --freq $RFM_FREQ"
		exit 1
	fi
done

case "$HW" in
	NANODE|JEENODE)
		HW_STRING="${HW}=1"
		;;
	*)
		HW_STRING=""
		;;
esac

make -C ${SCRIPTPATH} clean
make -C ${SCRIPTPATH} \
RFM_TUNING=1 \
RFM_FREQ_MAIN=${RFM_FREQ} \
RFM_FREQ_FINE=0.35 \
RFM_BAUD_RATE=19200 \
SECURITY_KEY_0=0x${KEY0} \
SECURITY_KEY_1=0x${KEY1} \
SECURITY_KEY_2=0x${KEY2} \
SECURITY_KEY_3=0x${KEY3} \
SECURITY_KEY_4=0x${KEY4} \
SECURITY_KEY_5=0x${KEY5} \
SECURITY_KEY_6=0x${KEY6} \
SECURITY_KEY_7=0x${KEY7} \
${HW_STRING}
