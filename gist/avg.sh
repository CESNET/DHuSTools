#!/bin/bash

# This script shows how to go through a log file, extracting a sequence of
# numbers, and then use the stat() function to compute essential statistical
# characteristics

function stat()
{
	awk 'BEGIN {
		min=999999999;
		max=0;
		count=0;
		sum=0;
		sqsum=0;
	} {
		count+=1;
		sum+=$1;
		sqsum+=$1^2;
		if (min > $1) {
			min=$1
		}
		if (max < $1) {
			max=$1
		}
	} END {
		printf " Count:\t\t%20d\n Sum:\t\t%20d\n Average:\t%20.0f\n Std. dev.:\t%20.0f\n Min:\t\t%20d\n Max:\t\t%20d\n", count, sum, sum/count, sqrt(sqsum*count - sum^2)/count, min, max;
	}'

}

echo S1
cat *.log | grep "downloaded" | grep '.zip' | grep \'S1 | egrep -o '[0-9]* bytes' | grep -o '[0-9]*' | stat

echo S2
cat *.log | grep "downloaded" | grep '.zip' | grep \'S2 | egrep -o '[0-9]* bytes' | grep -o '[0-9]*' | stat

