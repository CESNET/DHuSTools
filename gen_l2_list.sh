#!/bin/bash

WRKD="/tmp"
VARTMP="/var/tmp/gen_l2_list"
NETRCOPT="-n"
TODAY=`date -d "today" +%Y-%m-%d`
FROM=`date -d "yesterday-30 days" +%Y-%m-%d`
VERBOSE=0
NDAYS=3

while getopts "hvn:f:u:p:" opt; do
  case $opt in
        h)
                printf "Generate a list of L1 products (Sentinel2) that do not have a matching L2A product.\n\nUsage:\n
\t-h      \tDisplay this help\n \
\t-n <str>\tpath to an altarnative .netrc file (default ~/.netrc)\n \
\t-u <str>\tusername:password to be used instead of .netrc\n \
\t-f <Y-M-D>\tStarting date (default ${FROM})\n \
\t-p <num>\tdisregard files already returned within past 'p' days (default ${NDAYS})\n \
\t-v      \tVerbose: May add more output, preserves working directory\n \
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
        p)
		NDAYS="${OPTARG}"
                ;;
        v)
		VERBOSE=1
                ;;
  esac
done

shift $(($OPTIND - 1))
URL=$1

debug() {
	MESSAGE=$@
	if [ $VERBOSE -gt 0 ]; then
		>&2 printf "$MESSAGE"
	fi
}

get_list() {
        SSTRING="${FROM}T00:00:00.000"
        PAGESIZE=100
        SKIP=0

	PTYPE=$1


        let COUNT=$PAGESIZE+1
        while [ $COUNT -gt $PAGESIZE ]; do
                COUNT=0
                SEG=$(curl -sS ${NETRCOPT} ${URL}/odata/v1/Products?%24format=text/csv\&%24select=Name,Id\&%24skip=$SKIP\&%24top=$PAGESIZE\&%24filter=CreationDate%20gt%20datetime%27${SSTRING}%27%20and%20startswith\(Name,%27S2%27\)%20and%20substringof\(%27${PTYPE}%27,Name\))
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

PWD=`pwd`
mkdir -p "${WRKD}/l2comp.$$"
cd "${WRKD}/l2comp.$$"
mkdir -p "${VARTMP}"

##########################################
# Step 10: List L1C files

get_list _MSIL1C_ > l1raw.csv


##########################################
# Step 20: List L2A files

get_list _MSIL2A_ > l2raw.csv


##########################################
# Step 30: Make lists comparable

cat l1raw.csv | sed 's/,.*//' > l1list.csv
cat l2raw.csv | sed 's/,.*//' | sed 's/_MSIL2A_/_MSIL1C_/' > l2list.csv

##########################################
# Step 40: Compare lists

grep -v -f l2list.csv l1list.csv > l1only.csv

##########################################
# Step 50: Make results

grep -f l1only.csv l1raw.csv | sed 's/.*,//' > product_list.txt

if [ $NDAYS -gt 0 ]; then
	for i in `seq 0 $NDAYS`; do
		THEDAY=`date -d "${TILL}-${i} days" +%Y-%m-%d`
		debug "Removing products found on ${THEDAY} (using list in \"${VARTMP}/${THEDAY}\")\n"
		if [ -f "${VARTMP}/${THEDAY}" ]; then
			grep -v -f "${VARTMP}/${THEDAY}" product_list.txt > product_list.short.txt
			mv -f product_list.short.txt product_list.txt
		fi
	done
fi


##########################################
# Step 60: Output results

cat product_list.txt >> "${VARTMP}/${TODAY}"
cat product_list.txt

debug "A total of `wc -l product_list.txt | awk '{ print $1 }'` products found for processing.\nFound `wc -l l1raw.csv | awk '{ print $1 }'` L1 and `wc -l l2raw.csv | awk '{ print $1 }'` L2 products for the given period.\n"
cd "${PWD}"

if [ $VERBOSE -eq 0 ]; then
	rm -rf "${WRKD}/l2comp.$$"
else
	>&2 printf "Working data kept in \"${WRKD}/l2comp.$$\"\n"
fi

