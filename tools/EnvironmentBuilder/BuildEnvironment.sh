#!/bin/bash

SCRIPTPATH="${0%/*}"

source ${SCRIPTPATH}/environment.config

if [ -z "$SECRET" ]; then
	read -p "Enter the passphrase for the environment: " PASSPHRASE
	SECRET="--pass \"$PASSPHRASE\""
fi

UNIT_FOLDER=$(realpath ${SCRIPTPATH}/../../src)
MASTER_FOLDER=$(realpath ${SCRIPTPATH}/../../rfm-master)
UNIT_EEP=$UNIT_PREFIX.eep
UNIT_HEX=$UNIT_PREFIX.hex
MASTER_EEP=master.eep
MASTER_HEX=master.hex
DST_FOLDER=$(realpath ${SCRIPTPATH}/../../bin)

# Compile units
for addr in "${ADDRESSES[@]}"; do
	echo ""
	echo "************************************************"
	echo " Compiling unit #$addr"
	echo "************************************************"
	echo ""
	${UNIT_FOLDER}/compile_unit.sh --addr $addr ${SECRET} --hw $UNIT_HW --freq $RFM_FREQ --rfm-wire $UNIT_RFM_WIRE >/dev/null || { echo ""; echo "Compilation failed for unit $addr; aborting" ; exit 1; }
	mv ${UNIT_FOLDER}/${UNIT_HEX} ${DST_FOLDER}/unit_${addr}.hex
	mv ${UNIT_FOLDER}/${UNIT_EEP} ${DST_FOLDER}/unit_${addr}.eep
	make -C ${UNIT_FOLDER} clean HW=$UNIT_HW >/dev/null
done

# Compile master
echo ""
echo "************************************************"
echo " Compiling master"
echo "************************************************"
echo ""
${MASTER_FOLDER}/compile_master.sh ${SECRET} --hw "$MASTER_HW" --freq $RFM_FREQ >/dev/null || { echo ""; echo "Compilation failed for master; aborting" ; exit 1; }
mv ${MASTER_FOLDER}/${MASTER_HEX} ${DST_FOLDER}/master.hex
mv ${MASTER_FOLDER}/${MASTER_EEP} ${DST_FOLDER}/master.eep
make -C ${MASTER_FOLDER} clean >/dev/null


echo ""
echo ""
echo "************************************************"
echo " Compilation finished"
echo " hex files saved in folder ${DST_FOLDER}"
echo "************************************************"