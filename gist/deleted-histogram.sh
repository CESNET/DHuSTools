#!/bin/bash
# Lists all deleted products reported by the remote site

	URL="https://colhub.copernicus.eu/dhus"
	UPWD="-n"
	NOW=`date -d 'yesterday 00:00:00' "+%s"`
	START=0 # Start from the beginning of the world (i.e., Jan 1970)

	SSTRING=`date -d @$START "+%Y-%m-%dT%H:%M:%S.000"`
	let ETIME=$START+86400
	ESTRING=`date -d @$NOW "+%Y-%m-%dT%H:%M:%S.000"`
	PAGESIZE=100
	SKIP=0

	

	let COUNT=$PAGESIZE+1
	while [ $COUNT -gt $PAGESIZE ]; do
		COUNT=0
		SEG=`curl -sS $UPWD ${URL}/odata/v1/DeletedProducts?%24format=text/csv\&%24select=Name,CreationDate,DeletionDate,DeletionCause\&%24skip=$SKIP\&%24top=$PAGESIZE\&%24filter=CreationDate%20gt%20datetime%27${SSTRING}%27%20and%20CreationDate%20lt%20datetime%27${ESTRING}%27%20and%20startswith%28DeletionCause,%27Invalid%27%29`
		while read -r line; do
			if [ $COUNT -ne 0 ]; then
				echo $line;
			fi
			let COUNT=$COUNT+1
		done <<< $SEG
		let SKIP=$SKIP+$PAGESIZE
	done

