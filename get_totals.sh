#!/bin/bash

NUM=14
LAST=1
ATTRIBUTE="CreationDate"

while getopts "hn:u:tic" opt; do
  case $opt in
	h)
		printf "Check total files for a given day at a DHuS endpoint \n\nUsage:\n
\t-h      \tDisplay this help\n \
\t-n <num>\tNumber of days to count back this help\n \
\t-t      \tAlso include TODAY
\t-i      \tSearch by INGESTION Date (default Creation)
\t-c      \tSearch by CONTENT Date (default Creation)
\t-u <str>\tuser:password to use accessing the remote site. This is passed directly to curl.\n"
		exit 0
		;;
	u)
		UPWD=$OPTARG
		;;
	n)
		NUM=$OPTARG
		;;
	t)
		LAST=0
		;;
	i)
		ATTRIBUTE="IngestionDate"
		;;
	c)
		ATTRIBUTE="ContentDate"
		;;
  esac
done

shift $(($OPTIND - 1))
URL=$1


echo "Counting $NUM days back"

NOW=`date -d 'yesterday 00:00:00' "+%s"`
let START=$NOW-$NUM*86400+$LAST*86400


for i in `seq 1 $NUM`; do
	SSTRING=`date -d @$START "+%Y-%m-%dT%H:%M:%S.000"`
	let ETIME=$START+86400
	ESTRING=`date -d @$ETIME "+%Y-%m-%dT%H:%M:%S.000"`
	let MTIME=$START+43200
	MSTRING=`date -d @$START "+%Y-%m-%d"`

	printf "\n$MSTRING,"
	curl -u "$UPWD" ${URL}/odata/v1/Products//%24count?%24filter=${ATTRIBUTE}%20gt%20datetime%27${SSTRING}%27%20and%20${ATTRIBUTE}%20lt%20datetime%27${ESTRING}%27
	if [ $? -gt 0 ]; then
		break
	fi
	let START+=86400
done

printf "\n"


exit 0
