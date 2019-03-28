#!/bin/bash

fromhuman() {
	echo $@ | awk '{
		switch ($2) {
			case "GB":
			        factor = 1073741824;
        			break
			case "MB":
			        factor = 1048576;
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

MONTHS=1

FOOTPRINT='footprint:"Intersects(POLYGON((7.125551570329695 56.82293997800775,8.187468460585468 54.83362909344714,10.15067615685664 54.76675883034369,11.614158257713337 54.49298748079582,12.613609448542297 54.57582966128987,12.711769833355858 55.41530314074643,12.756388190089293 55.75824345184793,12.256662594674813 56.656540063131985,10.775333151124743 57.99562854221014,7.125551570329695 56.82293997800775,7.125551570329695 56.82293997800775)))"'

ENDPOINT='https://scihub.copernicus.eu/dhus'

FIELDS='&select=Id'


echo Date Range, Platform, Product Type, Size [b], Count
for MONTH in `seq 1 $MONTHS`; do	# Get products per month
	MONTHLESS=$(($MONTH-1))
	POSCONDITION=" AND beginposition:%5BNOW-${MONTH}MONTHS TO NOW-${MONTHLESS}MONTHS%5D"

	DATERANGE=`date +%Y-%m-%d -d "now - $MONTH month"`--`date +%Y-%m-%d -d "now - $MONTHLESS month"`

	declare -A SIZES
	declare -A COUNTS

	START=0
	while [ true ];	do # Iterate through pages. Don't worry, there will be an exit condition at the end of the loop

		FULLREQUEST=`echo "${ENDPOINT}/search?q=${FOOTPRINT}${POSCONDITION}&start=${START}&rows=100" | sed 's/ /%20/g; s/"/%22/g;'`

		RAWXML=`curl -nsS "$FULLREQUEST"`	# The sed removes all newlines
		RAWXML=`echo $RAWXML | sed 's/\r//g'`
		TOTAL=`echo "$RAWXML" | sed 's/.*<opensearch:totalResults>\(.*\)<\/opensearch:totalResults>.*/\1/'`

		while read ENTRY; do
			PLATFORM=`echo $ENTRY | sed 's/.*<str name="platformname">\([^<]*\).*/\1/'`
			PRODUCTTYPE=`echo $ENTRY | sed 's/.*<str name="producttype">\([^<]*\).*/\1/'`
			SIZE=`echo $ENTRY | sed 's/.*<str name="size">\([^<]*\).*/\1/'`
			SIZE=`fromhuman $SIZE`

#			echo $PLATFORM,$SIZE

			SIZES["$PLATFORM,all"]=$((${SIZES["$PLATFORM,all"]}+$SIZE))
			SIZES["$PLATFORM,$PRODUCTTYPE"]=$((${SIZES["$PLATFORM,$PRODUCTTYPE"]}+$SIZE))
			COUNTS["$PLATFORM,all"]=$((${COUNTS["$PLATFORM,all"]}+1))
			COUNTS["$PLATFORM,$PRODUCTTYPE"]=$((${COUNTS["$PLATFORM,$PRODUCTTYPE"]}+1))
		done < <(echo $RAWXML | sed 's/<\/entry>/<\/entry>\n/g' | grep -v '</feed>')

		START=$(($START+100))
# XXX		if [ $START -ge $TOTAL ]; then
			break
# XXX		fi
	done

	for PLATFORM in "${!SIZES[@]}"; do
		echo $DATERANGE,$PLATFORM,${SIZES[$PLATFORM]},${COUNTS[$PLATFORM]}
	done

	unset SIZES
	unset COUNTS
done

