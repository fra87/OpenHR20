#!/bin/bash

SCRIPTPATH="${0%/*}"

source ${SCRIPTPATH}/environment.config

SRC_FOLDER=$(realpath ${SCRIPTPATH}/../../${BIN_FOLDER})
TARGET_PREFIX=""

printUsage() {
	echo "$0 [--list] [--unit <addr>] [--master]"
	echo "  --list         Show the list of available targets"
	echo "  --unit <addr>  Flash the unit <addr>"
	echo "  --master       Flash the master"
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
		shift;shift;
	elif [ "$1" == "--master" ]; then
		[ -z "$TARGET_PREFIX" ] || { echo "Too many targets specified; can only flash one device"; exit 1; }
		TARGET_PREFIX="$(GetBinaryFilePrefix MASTER)"
		shift;
	else
		echo "unknown options starting at $*"
		printUsage
		exit 1
	fi
done

[ -z "$TARGET_PREFIX" ] && { echo; echo "No target specified"; echo; printUsage; exit 1; }

# TBD: copy the flashing script here, since the locations are quite different.
# Better to start from flash_unit.sh
