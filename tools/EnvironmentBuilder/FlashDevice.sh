#!/bin/bash

SCRIPTPATH="${0%/*}"

source ${SCRIPTPATH}/environment.config

SRC_FOLDER=$(realpath ${SCRIPTPATH}/../../${BIN_FOLDER})
TARGET_PREFIX=""
HARDWARE_PLATFORM=""
SETFUSES=0
DRYRUN=0
BACKUP=1
# Logic on EEPROM inverted with respect to original flash to avoid erasing the old EEPROM
EEPROM=0
FIRSTWRITE=0

printUsage() {
	echo "$0 [--list] [--unit <addr>] [--master] [--setFuses] [--dryRun] [--noBackup] [--writeEEPROM]"
	echo "  --list         Show the list of available targets"
	echo "  --unit <addr>  Flash the unit <addr>"
	echo "  --master       Flash the master"
	echo "  Other options:"
	echo "  --setFuses     Flash the fuses with the binary (needed only once)"
	echo "  --dryRun       Echo the AVRDUDE commands instead of executing them"
	echo "  --noBackup     Avoid reading the firmware on the board (and saving it) before flashing"
	echo "  --writeEEPROM  Write the EEPROM memory together with the firmware"
	echo "  --firstWrite   First writing of the firmware (forces backup, fuses and EEPROM)"
}

while [ "$#" -ne 0 ]; do
	if [ "$1" == "--list" ]; then
		echo "Available targets:"
		[ -f "$SRC_FOLDER/$(GetBinaryFileName HEX MASTER)" -a -f "$SRC_FOLDER/$(GetBinaryFileName EEPROM MASTER)" ] && echo "  MASTER"
		for i in {1..29}; do
		   [ -f "$SRC_FOLDER/$(GetBinaryFileName HEX UNIT $i)" -a -f "$SRC_FOLDER/$(GetBinaryFileName HEX UNIT $i)" ] && echo "  UNIT $i"
		done
		exit 0;
	elif [ "$1" == "--unit" ]; then
		[ -z "$TARGET_PREFIX" ] || { echo "Too many targets specified; can only flash one device"; exit 1; }
		TARGET_PREFIX="$(GetBinaryFilePrefix UNIT $2)" || { echo "Invalid address $2; aborting"; exit 1; }
		HARDWARE_PLATFORM=$UNIT_HW
		shift;shift;
	elif [ "$1" == "--master" ]; then
		[ -z "$TARGET_PREFIX" ] || { echo "Too many targets specified; can only flash one device"; exit 1; }
		TARGET_PREFIX="$(GetBinaryFilePrefix MASTER)"
		HARDWARE_PLATFORM=$MASTER_HW
		shift;
	elif [ "$1" == "--setFuses" ]; then
		SETFUSES=1; shift;
	elif [ "$1" == "--dryRun" ]; then
		DRYRUN=1; shift;
	elif [ "$1" == "--noBackup" ]; then
		BACKUP=0; shift;
	elif [ "$1" == "--writeEEPROM" ]; then
		EEPROM=1; shift;
	elif [ "$1" == "--firstWrite" ]; then
		FIRSTWRITE=1; shift;
	else
		echo "unknown options starting at $*"
		printUsage
		exit 1
	fi
done

# Done here to force the behavior (and avoid to ignore backup when, for instance, one calls ./FlashDevice.sh --firstWrite --noBackup)
if [ "$FIRSTWRITE" == "1" ]; then
	EEPROM=1
	BACKUP=1
	SETFUSES=1
fi

[ -z "$TARGET_PREFIX" ] && { echo; echo "No target specified"; echo; printUsage; exit 1; }

# Flashing script adapted from /src/flash_unit.sh

set -o nounset
set -o errexit
#set -o xtrace

# Get processor code
PROC="$(GetProcessorCode ${HARDWARE_PLATFORM})"

# Load fuses settings
[ -f ${SCRIPTPATH}/fuses/${PROC}.fuses ] || { echo "Cannot find fuses file for ${PROC}"; exit 1; }
source ${SCRIPTPATH}/fuses/${PROC}.fuses

# EEPROM settings
if [ "$EEPROM" == "1" ]; then
	WRITE_EEPROM="-e -U eeprom:w:${SRC_FOLDER}/${TARGET_PREFIX}.eep"
else
	WRITE_EEPROM=
fi

# Backup directory
BDIR="$(realpath ${SCRIPTPATH}/../../backup)/${TARGET_PREFIX}/$(date  "+%F_%T")"

# AVRDUDE command
DUDE="avrdude -p ${PROC} -c ${PROGRAMMER} -P ${PROGRAMMER_PORT} ${PROGRAMMER_OPTS}"

if [ "$DRYRUN" != "0" ]; then
	DUDE="echo DRY RUN: $DUDE"
fi

echo ""

if [ "$BACKUP" != "0" ]; then
	# do a backup
	echo "*** making backup to ${BDIR}"
	if [ ! -x $BDIR ]; then
		mkdir -p $BDIR
	fi
	echo "*** backing up fuses..."
	$DUDE -U lfuse:r:${BDIR}/lfuse.hex:h -U hfuse:r:${BDIR}/hfuse.hex:h -U efuse:r:${BDIR}/efuse.hex:h || exit
	sleep 3

	echo "*** backing up flash and eeprom..."
	$DUDE -U flash:r:${BDIR}/${TARGET_PREFIX}.hex:i -U eeprom:r:${BDIR}/${TARGET_PREFIX}.eep:i
	sleep 3

	echo ""
fi

#flash files from current dir
if [ "$SETFUSES" == "1" ]; then
	echo "*** setting fuses..."
	$DUDE -U hfuse:w:${HFUSE_PROTECTED_EEPROM}:m -U lfuse:w:${LFUSE}:m -U efuse:w:${EFUSE}:m
	sleep 3
	echo ""
fi

# Unprotect EEPROM if needed
[ "$EEPROM" == "1" ] && $DUDE -U hfuse:w:${HFUSE_UNPROTECTED_EEPROM}:m

echo "*** writing openhr20 flash (and possibly eeprom)"
$DUDE -U flash:w:${SRC_FOLDER}/${TARGET_PREFIX}.hex $WRITE_EEPROM

# if we wrote the eeprom, then protect the eeprom from erase next time
# so that we can just update the code without blowing away the eeprom
[ "$EEPROM" == "1" ] && $DUDE -U hfuse:w:${HFUSE_PROTECTED_EEPROM}:m

echo ""

echo "*** done!"
