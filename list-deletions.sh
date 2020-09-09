#!/bin/bash

# Defaults
UPSTREAMURL="https://colhub.copernicus.eu/dhus"
LOCALURL="https://dhr1.cesnet.cz"
UPWD="-n"
NOW=`date -d 'yesterday 00:00:00' "+%s"`
START=0
VARDIR="/var/tmp/dhus-deletions"
REASONPREFIX="Invalid"
REASONCONTENT=""

XTRAARG=""

# Override defaults with config file content, if CFs exist
for CONF in "/etc/list-deletions.conf" "$HOME/.list-deletions.conf"; do
	if [ -f "$CONF" ]; then
		echo Reading configuration from "$CONF"
		source "$CONF"
	fi
done

#Expand tildes in paths if used
VARDIR="${VARDIR/#\~/$HOME}"
XTRAARG="${XTRAARG/#\~/$HOME}"

while getopts "hw:x:c:p:m:s:" opt; do
  case $opt in
        h)
                printf "Collect DHuS Synchronizer settings, compile into table and upload.\n\nUsage:\n
\t-w <str>\tPath to the working directory (Default \"${VARDIR}\")\n \
\t-x <str>\tAny extra arguments to be handed over to curl\n \
\t-c <str>\tPath to configuration file to specify multiple options\n \
\t-p <str>\tReason Prefix (DeleteReason must start with this prefix)\n \
\t-m <str>\tReason Content (DeleteReason must contain this substring)\n \
\t-s <Y-M-D>\tStart Date override (check deletions after this date)\n \
		\n"
                exit 0
                ;;
	d)
		DRY=1
                ;;
	w)
		vardir=$optarg
                ;;
	x)
		XTRAARG=" $OPTARG "
                ;;
	c)
		CONF="$OPTARG"
		if [ -f "$CONF" ]; then
			echo Reading configuration from "$CONF"
			source "$CONF"
		else
			echo "Specified configuration file $CONF not found" >&2
			exit 1
		fi
                ;;
	s)
		STRSTART=$optarg
                ;;
	p)
		REASONPREFIX=$optarg
                ;;
	m)
		REASONCONTENT=$optarg
                ;;
  esac
done

REASONPREFIX="%20and%20startswith(Name,%27${REASONPREFIX}%27)"
REASONCONTENT="%20and%20substringof(%27${REASONCONTENT}%27,Name)"

#TODO Convert STRSTART

function check_binaries()
{
	for file in $@; do
		ret=`which $file 2> /dev/null`
		if [ -n "$ret" -a -x "$ret" ]; then
			echo $ret
	        else
			echo "command $file not found" >&2
			exit 1
	        fi
	done
}

check_binaries curl date awk sed grep


SSTRING=`date -d @$START "+%Y-%m-%dT%H:%M:%S.000"`
let ETIME=$START+86400
ESTRING=`date -d @$NOW "+%Y-%m-%dT%H:%M:%S.000"`
PAGESIZE=100
SKIP=0


# Step 10
# Get a list of products deleted since last time

#TODO Honor all variables

let COUNT=$PAGESIZE+1
while [ $COUNT -gt $PAGESIZE ]; do
		COUNT=0
		SEG=`curl -sS $UPWD ${UPSTREAMURL}/odata/v1/DeletedProducts?%24format=text/csv\&%24select=Name,CreationDate,DeletionDate,DeletionCause\&%24skip=$SKIP\&%24top=$PAGESIZE\&%24filter=CreationDate%20gt%20datetime%27${SSTRING}%27%20and%20CreationDate%20lt%20datetime%27${ESTRING}%27%20and%20startswith%28DeletionCause,%27Invalid%27%29`
		while read -r line; do
			if [ $COUNT -ne 0 ]; then
				echo $line;
			fi
			let COUNT=$COUNT+1
		done <<< $SEG
		let SKIP=$SKIP+$PAGESIZE
done

# Step 20
# Check local status of deleted products and generate list

