#!/bin/bash
# This script goes through DHuS log files and searches for OData synchronizer
# queries placed by remote nodes. It makes a CSV showing each unique
# synchronizer's user account, filter setting and CreationDate value.
# NOTE: The output is actually not comma-separated but rather
# space separated!

echo Date Time User Filter CreationDate
grep -h filter=CreationDate%20ge% *.log | grep SUCCESS | sed 's/\[[^]]*\]\[\([^]]*\)\].*ms\]\s\(\S\S*\)\s.*filter=CreationDate%20ge%20datetime\([^%]*\)\(.*\)..orderby=.*/\1 \2 \4 \3/'

>&2 echo Remember columns in the output are separated by spaces!

