#!/bin/bash
# This gist parses DHuS logs in local dir and produces a CSV file
# with query response times, suitable for input into spreadsheet
# pilot tables

grep "successfully synchronized" *.log | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*synchronized from.*:\/\/\([^\/]*\).*/s\/\1;\2;\/\1;\3;\//' | sort | uniq > /tmp/syncer.replace.$$

echo 'Date;Source;Duraion-in-ms'

grep -h 'query(Products)' *.log | sed 's/.*\]\[\([0-9][0-9\-]*\).*Synchronizer\#\([0-9][0-9]*\).*done in \([0-9]*\)ms.*/\1;\2;\3/' | sed -f /tmp/syncer.replace.$$

rm -f /tmp/syncer.replace.$$

