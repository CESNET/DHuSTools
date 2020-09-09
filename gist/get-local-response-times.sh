#!/bin/bash
# A simple example that greps successful answers to syncer queries from log files
# and outputs average response time for each user in a CVS

>&2 echo USING FILES:
>&2 ls -l dhus*.log.gz

>&2 echo OUTPUT:
echo User,Average
for f in dhus*.log.gz; do
	DATE=`echo $f | grep -Eo "[0-9][0-9]*-[0-9]*-[0-9]*[0-9]"`
	gunzip -c $f | grep "filter=CreationDate%20ge%20" | grep '\-SUCCESS\-' | sed 's/.*\s\(\S*\)ms\] \(\S*\).*/\2 \1/' | sort | awk 'BEGIN {olduname=""} {if(olduname != "" && $1 != olduname) {print olduname "," usum/unr; usum=0; unr=0;}; sum+=$2; usum+=$2; unr+=1; olduname=$1;} END {print olduname "," usum/unr; print "Overall," sum/NR}' | sed "s/^/$DATE,/"
done
