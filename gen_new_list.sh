#!/bin/bash

WRKD="/tmp"
VARTMP="/var/tmp/gen_new_list"
NETRCOPT="-n"
FROM=`date -d "yesterday-30 days" +%Y-%m-%dT%H:%M:%S.000`
VERBOSE=0
DRY=0


debug() {
	MESSAGE=$@
	if [ $VERBOSE -gt 0 ]; then
		>&2 printf "$MESSAGE"
	fi
}


# Use last timestamp for start if possible
if [ -s "${VARTMP}/timestamp" ]; then
	STORED=`grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}' "${VARTMP}/timestamp"`
	if [ "${STORED}" != "" ]; then
		FROM="$STORED"
		debug "Using stored timestamp \"${FROM}\"\n"
	else
		1>&2 echo Timestamp file exists but is formatted incorrectly
	fi
fi

#TODO: Add options to support other types of output besides IDs
while getopts "hvdn:f:u:t:" opt; do
  case $opt in
        h)
                printf "Generate a list of Sentinel products recently published at an endpoint.\n\nUsage:\n
\t-h      \t\tDisplay this help\n \
\t-d      \t\tDry run: do not store results at all\n \
\t-n <str>\t\taltarnative .netrc file (default ~/.netrc)\n \
\t-u <str>\t\tusername:password to be used instead of .netrc\n \
\t-f <Y-M-DTH-M-S.SSS>\tStarting date (default ${FROM})\n \
\t-t <str>\t\tsemi-permanent location to store state\n\t\t\t\t(default: $VARTMP)\n \
\t-v      \t\tVerbose: more output, preserve work directory\n \
\n\n"
                exit 0
                ;;
        n)
		NETRCOPT="--netrc-file ${OPTARG}"
                ;;
        u)
		NETRCOPT="-u \"${OPTARG}\""
                ;;
        f)
		FROM="${OPTARG}"
                ;;
        t)
		VARTMP="${OPTARG}"
                ;;
        v)
		VERBOSE=1
                ;;
        d)
		DRY=1
                ;;
  esac
done

shift $(($OPTIND - 1))
URL=$1

get_list() {
        PAGESIZE=100
        SKIP=0

	PTYPE=$1

        let COUNT=$PAGESIZE+1
        while [ $COUNT -gt $PAGESIZE ]; do
                COUNT=0
                SEG=$(curl -sS ${NETRCOPT} ${OS_ACCESS_TOKEN:+-H "Authorization: Bearer $OS_ACCESS_TOKEN"} "${URL}/odata/v1/Products?%24format=text/csv&%24select=Name,Id,CreationDate&%24skip=${SKIP}&%24top=${PAGESIZE}&%24filter=CreationDate%20ge%20datetime%27${FROM}%27")
                while read -r line; do
                        if [ $COUNT -ne 0 ]; then
                                echo $line;
                        fi
                        let COUNT=$COUNT+1
                done <<< $SEG
                let SKIP=$SKIP+$PAGESIZE
        done
}

if [ "$URL" == "" ]; then
	>&2 echo "You must specify DHuS endpoint (e.g., https://dhr1.cesnet.cz)"
	exit 1
fi

# TODO: Check binaries

PWD=`pwd`
mkdir -p "${WRKD}/newcomp.$$"
cd "${WRKD}/newcomp.$$"
mkdir -p "${VARTMP}"
if [ $? -gt 0 ]; then echo Failed creating directory \"$VARTMP\"; exit 1; fi

##########################################
# Step 10: List files

get_list > newraw.csv

debug "Got `wc -l newraw.csv | awk '{ print $1 }'` matches.\n"

##########################################
# Step 20: Eliminate previous matches

if [ -s "${VARTMP}/list" ]; then
	debug Filtering out `wc -l ${VARTMP}/list` files from previous list
	cat newraw.csv | grep -v -f "${VARTMP}/list" > list
	rm newraw.csv
else
	debug No previous files. Using full list.
	mv newraw.csv list
fi



##########################################
# Step 30: Get the newest time

if [ -s list -a $DRY -eq 0 ]; then #If the new file has non-zero length
	cat list | sed 's/.*,//' | sort | tail -n 1 > "${VARTMP}/timestamp"
	cp list "${VARTMP}/list"
	debug "Files copied and most recent creation date saved\n"
else
	debug "No new products\n"
fi


##########################################
# Step 50: Make results

cat list | awk -F',' '{print $2}'

debug "A total of `wc -l list | awk '{ print $1 }'` products found for processing.\n"
cd "${PWD}"

if [ $VERBOSE -eq 0 ]; then
	rm -rf "${WRKD}/newcomp.$$"
else
	>&2 printf "Working data kept in \"${WRKD}/newcomp.$$\"\n"
fi

