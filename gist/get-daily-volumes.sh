#!/bin/bash
for f in *.log; do
	NAM=`echo -e $f	| egrep -o '[0-9][0-9\-]*'`
	printf $NAM
	if [ -d daily-$NAM ]; then
		echo already exists
	else
		mkdir  daily-$NAM
		./DataHubStats_TiB.sh $NAM $NAM daily-$NAM
	fi
done

find daily-* -name "retrieved_report*" -exec cat {} > retr-$NAM.csv \;
