#!/bin/bash
# This code snippet cycles throug available DHuS log files and calls
# the offical statistics script for each one separately.
# Finally it aggregates the results and cleans them up so that they
# can be entered "as-is" into any spreadsheet's Pilot Table.

for f in *.log; do
	NAM=`echo -e $f	| egrep -o '[0-9][0-9\-]*'`
	printf "$NAM"
	if [ -d "daily-$NAM" ]; then
		echo " already exists"
	else
		mkdir -p daily-$NAM
		./DataHubStats_TiB.sh $NAM $NAM daily-$NAM
	fi
done

find daily-* -name "retrieved_report*" -exec cat {} > retr-$NAM.csv \;

head -n 1 retr-$NAM.csv > retr-$NAM-pilot.csv
cat retr-$NAM.csv | egrep -v ";size;|;S[123][ABCD][_.]*;" | sed 's/ to [0-9\-]*//' | sed 's/https:\/\///' | sed 's/\/dhus.*\/v[0-9]//' | sed 's/.copernicus.eu//' >> retr-$NAM-pilot.csv

