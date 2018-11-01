#!/bin/bash

NUM=14
LAST=0
ATTRIBUTE="CreationDate"
SELATTR="${ATTRIBUTE}"
LIST=0
PREFIX=""
MATCH=""
UPWD="-n"

while getopts "hn:u:ticlp:m:" opt; do
  case $opt in
	h)
		printf "Check total files for a given day at a DHuS endpoint \n\nUsage:\n
\t-h      \tDisplay this help\n \
\t-n <num>\tNumber of days to count back (default 14)\n \
\t-p <str>\tName prefix (Platform: S1, S2, or S3)\n \
\t-m <str>\tName contents match (e.g.: _SLC_)\n \
\t-t      \tAlso include TODAY\n \
\t-i      \tSearch by INGESTION Date (default Creation)\n \
\t-c      \tSearch by CONTENT Date (default Creation)\n \
\t-l      \tSuppress normal output, list ALL products matching criteria\n \
\t-u <str>\tuser:password to use accessing the remote site.\n \
\t\t\tThis is passed directly to curl.\n\n"
		exit 0
		;;
	u)
		UPWD="-u \"$OPTARG\""
		;;
	n)
		NUM=$OPTARG
		;;
	t)
		LAST=1
		;;
	i)
		ATTRIBUTE="IngestionDate"
		SELATTR="${ATTRIBUTE}"
		;;
	c)
		ATTRIBUTE="ContentDate/End"
		SELATTR="ContentDate"
		;;
	l)
		LIST=1
		;;
	p)
		PREFIX="%20and%20startswith(Name,%27${OPTARG}%27)"
		;;
	m)
		MATCH="%20and%20substringof(%27${OPTARG}%27,Name)"
		;;
  esac
done

shift $(($OPTIND - 1))
URL=$1


NOW=`date -d 'yesterday 00:00:00' "+%s"`
let START=$NOW-$NUM*86400+86400

let NUM=$NUM+$LAST

get_totals() {

for i in `seq 1 $NUM`; do
	SSTRING=`date -d @$START "+%Y-%m-%dT%H:%M:%S.000"`
	let ETIME=$START+86400
	ESTRING=`date -d @$ETIME "+%Y-%m-%dT%H:%M:%S.000"`
	let MTIME=$START+43200
	MSTRING=`date -d @$START "+%Y-%m-%d"`

	printf "\n$MSTRING,"
	curl $UPWD ${URL}/odata/v1/Products//%24count?%24filter=${ATTRIBUTE}%20gt%20datetime%27${SSTRING}%27%20and%20${ATTRIBUTE}%20lt%20datetime%27${ESTRING}%27${PREFIX}${MATCH}
	if [ $? -gt 0 ]; then
		break
	fi
	let START+=86400
done

printf "\n"
}

get_list() {
	SSTRING=`date -d @$START "+%Y-%m-%dT%H:%M:%S.000"`
	let ETIME=$START+86400
	ESTRING=`date -d @$NOW "+%Y-%m-%dT%H:%M:%S.000"`
	PAGESIZE=100
	SKIP=0

	

	let COUNT=$PAGESIZE+1
	while [ $COUNT -gt $PAGESIZE ]; do
		COUNT=0
		SEG=`curl -sS $UPWD ${URL}/odata/v1/Products?%24format=text/csv\&%24select=Name,${SELATTR}\&%24skip=$SKIP\&%24top=$PAGESIZE\&%24filter=${ATTRIBUTE}%20gt%20datetime%27${SSTRING}%27%20and%20${ATTRIBUTE}%20lt%20datetime%27${ESTRING}%27${PREFIX}${MATCH}`
		while read -r line; do
			if [ $COUNT -ne 0 ]; then
				echo $line;
			fi
			let COUNT=$COUNT+1
		done <<< $SEG
		let SKIP=$SKIP+$PAGESIZE
	done
}

if [ $LIST -eq 1 ]; then
	get_list
else
	get_totals
fi


exit 0
