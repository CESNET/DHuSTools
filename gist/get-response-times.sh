#!/bin/bash
# This gist parses DHuS logs in local dir and produces a CSV file
# with query response times, suitable for input into spreadsheet
# pilot tables

# Query records in the log fil do not mention source, giving only
# a synchronizer number. Therefore we use storage records to find
# out the source for each synchronizer on a given day.
grep "successfully synchronized" *.log | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*synchronized from.*:\/\/\([^\/]*\).*/s\/\1;\2;\/\1;\3;\//' | sort | uniq > /tmp/syncer.replace.$$

# Print out CSV header
echo 'Date;Source;Duraion-in-ms'

# Search for query duration records and replace synchronizer numbers
# with source dnames
grep -h 'query(Products)' *.log | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*done in \([0-9]*\)ms.*/\1;\2;\3/' | sed -f /tmp/syncer.replace.$$

rm -f /tmp/syncer.replace.$$

# To calculate averages, redirect output to this:
# | sort | awk --field-separator=";" 'START{ last=""; count=0 } { datefrom=$1";"$2; if(datefrom!=last) { print last "," sum "," count; sum=0; count=0 } sum+=$3; count+=1; last=datefrom; } END { print last "," sum "," count }'

