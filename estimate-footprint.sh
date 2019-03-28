#!/bin/bash

fromhuman() {
	echo $@ | awk '{
		switch ($2) {
			case "GB":
			        factor = 1073741824; # We know from the authors that DHuS indicates in GiB
        			break
			case "MB":
			        factor = 1048576; # We know from the authors that DHuS indicates in MiB
        			break
			case "KB":
			case "kB":
			        factor = 1024;
        			break
			default:
			        factor = 1;
        			break
		}
		printf "%d\n", $1 * factor;
	}'
}

UPWD="-n"
MONTHS=6
ENDPOINT='https://scihub.copernicus.eu/dhus'
OUTPUTPLATFORM=1
OUTPUTTYPES=1

while getopts "hn:e:DTAu:" opt; do
  case $opt in
        h)
                printf "Take DHuS query footprint and get the number and size of files matching that footprint over past months.\n\nUsage:\n \
\t`basename "$0"` [options] '<footprint>'\n\n \
\t<footprint>\tDHuS SOLR footprint syntax. This can be copied\n\t\t\tstraight from DHuS' Web interface. It is best\n\t\t\tenclosed in single quotes: ''\n \
\t-n <int>\tNumber of months to iterate back (Default $MONTHS)\n \
\t-e <str>\tEndpoint to use for the query\n\t\t\t(Default \"${ENDPOINT}\")\n \
\t-u <str>\tuser:password to use accessing the remote site.\n \
\t-D      \tDemo: use demo footprint (Denmark)\n \
\t-T      \tDo not output per product type, only platform summary\n \
\t-A      \tDo not output platform summary, only product types\n \
                \n"
                exit 0
                ;;
        n)
                MONTHS=$OPTARG
                ;;
        e)
                ENDPOINT=$OPTARG
                ;;
        D)
		FOOTPRINT='footprint:"Intersects(POLYGON((7.125551570329695 56.82293997800775,8.187468460585468 54.83362909344714,10.15067615685664 54.76675883034369,11.614158257713337 54.49298748079582,12.613609448542297 54.57582966128987,12.711769833355858 55.41530314074643,12.756388190089293 55.75824345184793,12.256662594674813 56.656540063131985,10.775333151124743 57.99562854221014,7.125551570329695 56.82293997800775,7.125551570329695 56.82293997800775)))"'
		>&2 printf "Using demo footprint:\n${FOOTPRINT}\n"
                ;;
        T)
                OUTPUTTYPES=0
		OUTPUTPLATFORM=1
                ;;
        A)
                OUTPUTTYPES=1
		OUTPUTPLATFORM=0
                ;;
  esac
done
if [ "$FOOTPRINT" == "" ]; then
	shift $(expr $OPTIND - 1 )
	FOOTPRINT="$@"
	if [ "$FOOTPRINT" == "" ]; then
		>&2 echo 'You must specify footprint (or -D for demo)'
		exit 1
	fi
fi

>&2 echo $FOOTPRINT

echo Date Range,Platform,Product Type,Size [B],Size [TiB],Count
for MONTH in `seq 1 $MONTHS`; do	# Get products per month
	MONTHLESS=$(($MONTH-1))
	POSCONDITION=" AND beginposition:%5BNOW-${MONTH}MONTHS TO NOW-${MONTHLESS}MONTHS%5D"

	DATERANGE=`date +%Y-%m-%d -d "now - $MONTH month"`--`date +%Y-%m-%d -d "now - $MONTHLESS month"`

	declare -A SIZES
	declare -A COUNTS

	START=0
	while [ true ];	do # Iterate through pages. Don't worry, there will be an exit condition at the end of the loop

		FULLREQUEST=`echo "${ENDPOINT}/search?q=${FOOTPRINT}${POSCONDITION}&start=${START}&rows=100" | sed 's/ /%20/g; s/"/%22/g;'`

		RAWXML=`curl ${UPWD} -sS "$FULLREQUEST"`	# The sed removes all newlines
		if [ $? -gt 0 ]; then
			break 2
		fi
		RAWXML=`echo $RAWXML | sed 's/\r//g'`
		TOTAL=`echo "$RAWXML" | sed 's/.*<opensearch:totalResults>\(.*\)<\/opensearch:totalResults>.*/\1/'`

		while read ENTRY; do
			PLATFORM=`echo $ENTRY | sed 's/.*<str name="platformname">\([^<]*\).*/\1/'`
			PRODUCTTYPE=`echo $ENTRY | sed 's/.*<str name="producttype">\([^<]*\).*/\1/'`
			SIZE=`echo $ENTRY | sed 's/.*<str name="size">\([^<]*\).*/\1/'`
			SIZE=`fromhuman $SIZE`

#			echo $PLATFORM,$SIZE

			if [ $OUTPUTPLATFORM -gt 0 ]; then
				SIZES["$PLATFORM,all"]=$((${SIZES["$PLATFORM,all"]}+$SIZE))
				COUNTS["$PLATFORM,all"]=$((${COUNTS["$PLATFORM,all"]}+1))
			fi

			if [ $OUTPUTTYPES -gt 0 ]; then
				SIZES["$PLATFORM,$PRODUCTTYPE"]=$((${SIZES["$PLATFORM,$PRODUCTTYPE"]}+$SIZE))
				COUNTS["$PLATFORM,$PRODUCTTYPE"]=$((${COUNTS["$PLATFORM,$PRODUCTTYPE"]}+1))
			fi
		done < <(echo $RAWXML | sed 's/<\/entry>/<\/entry>\n/g' | grep -v '</feed>')

		START=$(($START+100))
		if [ $START -ge $TOTAL ]; then
			break
		fi
	done

	for PLATFORM in "${!SIZES[@]}"; do
		echo $DATERANGE,$PLATFORM,${SIZES[$PLATFORM]},`echo ${SIZES[$PLATFORM]} | awk '{ printf "%.3f\n", $1/1024^4}'`,${COUNTS[$PLATFORM]}
	done

	unset SIZES
	unset COUNTS
done

