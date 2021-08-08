#!/bin/bash
# This script assumes gzipped log files in "be*" directories by instance
# It counts the occurrences of "Content-Legnth does not match downloaded bytes count"
# fails in the log files
for d in be*; do gunzip -c $d/dhus-2021-0* | grep -B1 "Content-Legnth does not match downloaded bytes count" | while read line; do echo $d $line; done; done | awk '{print $1 " " $2 " " $8}' | grep -Ev '[-][-]' | grep -v java.lang.IllegalStateException | sed 's/\]\[/ /' | sed 's/ \[/ /' | sed 's/https:\/\/\([^/]*\).*/\1/'
