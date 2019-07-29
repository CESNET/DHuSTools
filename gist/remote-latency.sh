#!/bin/bash
# This script goes through DHuS log files and searches for OData synchronizer
# queries placed by remote nodes. It takes unique synchronizers it finds,
# finds the freshest queries by CreationDate and calculates the most
# recent known latency (difference between the time of the query and the
# CreationDate it contained. Prints the time of the last query, user name and
# latency in HOURS

grep -h filter=CreationDate%20ge% *.log | grep SUCCESS | sed 's/\[[^]]*\]\[\([^]]*\)\].*ms\]\s\(\S\S*\)\s.*filter=CreationDate%20ge%20datetime\([^%]*\)\(.*\)..orderby=.*/\1 \2 \4 \3/' | sort -r -k4 rip-syncer-conf.csv | sort -k2,2 -u | awk '{ printf "%s %s %0.1f\n", $1, $2, (mktime(gensub("[T:-]|\\..*"," ","G",$1))-mktime(gensub("\47|[T:-]|\\..*"," ","G",$4)))/3600.0 }'


