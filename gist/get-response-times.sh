#!/bin/bash
# This gist parses DHuS logs in local dir and produces a CSV file
# with query response times, suitable for input into spreadsheet
# pilot tables

# Query records in the log fil do not mention source, giving only
# a synchronizer number. Therefore we use storage records to find
# out the source for each synchronizer on a given day.
for l in *.log.gz; do gunzip -c $l; done | grep "successfully synchronized" | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*synchronized from.*:\/\/\([^\/]*\).*/s\/\1;\2;\/\1;\3;\//' | sort | uniq > /tmp/syncer.replace.$$

# Print out CSV header
echo 'Date;Source;Duraion-in-ms'

# Search for query duration records and replace synchronizer numbers
# with source dnames
for l in *.log.gz; do gunzip -c $l; done | grep -h 'query(Products)' | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*done in \([0-9]*\)ms.*/\1;\2;\3/' | sed -f /tmp/syncer.replace.$$

rm -f /tmp/syncer.replace.$$

