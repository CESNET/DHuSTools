#!/bin/bash

if [ "$1" == "" ]; then
	1>&2 echo "No pattern given, counting for all logs"
	PATTERN=""
else 
	1>&2 echo "Only considering logs with \"$1\""
	PATTERN="*$1"
fi

echo "No. and volume of products publised by platform"

for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
grep --text "successfully synchronized from" | sed "s/.* Product \(S[1-9]\).*(\([0-9]*\) bytes compressed.*/\1\t\2/" | datamash --sort -g 1 count 2 sum 2 | awk '{ printf "%s\t%d\t%d\t%0.2f\n", $1, $2, $3, $3/1000000000000.0}'


printf "\nNumber of users who at least connected (NOT PART of ESA SPREADSHEET)"
for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
grep --text "Connection success for "  | awk '{print $7}' | sort | uniq | wc -l

printf "\nNumber of users having placed queries (NOT PART of ESA SPREADSHEET)\n"
for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
grep --text '/search?' | grep -v '/api/' | grep PENDING | awk '{print $7}' | sort | uniq > solr.$$.csv
SOLR=`cat solr.$$.csv | wc -l`
for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
grep --text '/odata/v[0-9]/' | grep -v '$value' | awk '{print $7}' | sort | uniq > odata.$$.csv
ODATA=`cat odata.$$.csv | wc -l`
TOTAL=`cat solr.$$.csv odata.$$.csv | sort | uniq | wc -l`
printf "$SOLR (SOLR) + $ODATA (OData) ~ $TOTAL\n"

rm -f solr.$$.csv odata.$$.csv

printf "\nNumber of users having triggered a search, discovery, viewing or processing service involving Copernicus Sentinel data on the service platform\n"



curl --silent -JO "https://security.metacentrum.cz/export/metacentrum_hosts.csv"

if [ -f metacentrum_hosts.csv ]; then
 
	for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
	grep --text SUCCESS | awk '{print $8}' | sort | uniq | sed 's/[)(]//g' > IP-addresses.$$.csv
	cat metacentrum_hosts.csv | awk -F';' '{print $1}' | sed 's/\.[^.]*$//' | sort | uniq > prefixes.$$.csv

	#IPv6 by listing
	echo "2a00:5800:" >> prefixes.$$.csv # MUNI
	echo "2001:718:" >> prefixes.$$.csv # CESNET
	
	sed -i 's/^/^/' prefixes.$$.csv 

	grep -f prefixes.$$.csv IP-addresses.$$.csv > own-addresses.$$.csv

	sed -i 's/^/(/' own-addresses.$$.csv
	sed -i 's/$/)/' own-addresses.$$.csv

	for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
	grep --text SUCCESS | grep -f own-addresses.$$.csv | awk '{print $7}' | sort > platform-users.$$.csv

	TOTUSERS=`cat platform-users.$$.csv | uniq | wc -l`
	TOTFILES=`cat platform-users.$$.csv | wc -l`

	printf "$TOTUSERS users, $TOTFILES files\n\n"

printf "\nNumber of users having triggered at least one processing run involving Copernicus Sentinel data on the platform\n"

	for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
	grep --text SUCCESS | grep '$value' | grep -v 'manifest.' | grep -f own-addresses.$$.csv | awk '{print $7}' | sort > platform-users.$$.csv

	TOTUSERS=`cat platform-users.$$.csv | uniq | wc -l`
	TOTFILES=`cat platform-users.$$.csv | wc -l`

	printf "$TOTUSERS users, $TOTFILES files\n\n"

#	cat platform-users.$$.csv | uniq -c | sort -rn

	rm -f IP-addresses.$$.csv own-addresses.$$.csv platform-users.$$.csv prefixes.$$.csv

else

	1>&2 echo File metacentrum_hosts.csv not found

fi

printf "\nNumber of registered users\n"

if [ -f users.pat ]; then

	cat users.pat | awk -F"," '{print $3}' | sort | uniq -c

	printf "\n"

	cat users.pat | awk -F"," '{print $4}' | sort | uniq -c

	printf "\n\t...\n"

	cat users.pat | awk -F"," '{print $5}' | sort | uniq -c | sort -n | tail -n 5

	printf "`cat users.pat | wc -l`\tTOTAL\n"

else

	1>&2 echo File users.pat not found

fi


