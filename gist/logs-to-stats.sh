#!/bin/bash

if [ ! -f "users.pat" ]; then
	>&2 printf "This script expects file \"users.pat\" with sed patterns to replace simple username occurrences with csv values. Line by line, for example:\n\ts/^sustr4,/sustr4,Research,Other,Czech Republic,/\nThis is best produced by tweaking the output of:\n\tSELECT login,login,usage,domain,country FROM users;\nIt is possible to start with the \"users.pat\" file in simple tabular TAB-separated format instead. If so this script will attempt to reformat the file on first run.\n"
	exit 1
fi


egrep --text '^s/' users.pat >/dev/null

if [ $? -ne 0 ]; then
	#Fix Korea
	sed -i 's/Korea, Republic of/Korea/g' users.pat

	>&2 printf "Reformatting users.pat\n"
	sed -i 's/\t/,\//' users.pat
	sed -i 's/\t/,/g' users.pat
	sed -i 's/$/,\//' users.pat
	sed -i 's/^/s\/\^/' users.pat
fi

echo login,usage,domain,country,platform,type,product,size

cat *.log | grep SUCCESS | grep '$value' | grep "Products" | grep -v "Products.*Products" | grep -vi manifest | grep -v '/Online/' | sed 's/\]/ /g' | sed 's/\[/ /g' | sed 's/[[:space:]][[:space:]]*/ /g' | awk '{print $7 " " $10}' | sed 's/\/\$value//' >> files.$$.csv

TMP="/var/tmp/logs-to-stats.tmp"
mkdir -p "$TMP"
LINE=0;
NAMEPAT="[sS][1235][ABCDPabcdp]_"
while read -r user url; do
	LINE=$(( $LINE + 1 ))
	url=$( echo "$url" | sed 's/:\/\/127.0.0.1:8081/s:\/\/dhr1.cesnet.cz/' )

	sanit=$( echo "$url" | md5sum | sed 's/\s.*//')

	if [ ! -f "${TMP}/${sanit}.xml" ]; then
		curl -ns -o "${TMP}/${sanit}.xml" "$url"
	fi

	size=$( xmlstarlet sel -d -T -t -v "//_:entry/m:properties/d:ContentLength" "${TMP}/${sanit}.xml")

	if [ $? -eq 3 ]; then # XML broken, try brute force
		
		1>&2 echo "l${LINE}: Brute force workaround for URL $url:"
		size=$( grep -o '"ContentLength":[0-9]*' "${TMP}/${sanit}.xml" | sed 's/.*://' )
		title=$( grep -o '"Name":"[^"]*' "${TMP}/${sanit}.xml" | sed 's/.*:"//' )

		if [ "${title}${size}" != "" ]; then
			echo ${user} ${title} ${size}
		else
			echo ${user} ${url} >> errors.$$.csv
		fi

	else
		title=$( xmlstarlet sel -d -T -t -v "//_:entry/_:title" "${TMP}/${sanit}.xml")
		if [ $? -gt 0 ]; then
			1>&2 echo "l${LINE}: Error parsing XML for URL $url:"
		else
			if [[ ! $title =~ $NAMEPAT ]]; then
				title=$( xmlstarlet sel -d -T -t -v "//_:entry/_:id" "${TMP}/${sanit}.xml" | grep -o "${NAMEPAT}[^']*" )
			fi

			if [ "${title}${size}" != "" ]; then
				echo ${user} ${title} ${size}
			else
				echo ${user} ${url} >> errors.$$.csv
			fi
		fi
	fi
done < files.$$.csv > list.$$.csv

cat list.$$.csv | \
awk '{
	user=$1
	product=toupper(gensub(/-/,"_","g",$2))
	size=$3

	if (product ~ /T.*\.JP2/) {
		platform="S2"
		prodtype="MSIL2A"
	}
	else {
		platform=substr(product,0,2);
		prodtype=product
		gsub(/_20[0-9][0-9][0-1].*/,"",prodtype)
		gsub(/^S[1-9][ABCD][^_]*_/,"",prodtype)
		gsub(/.*_SLC_.*/,"SLC",prodtype)
		gsub(/.*_MSIL1C_.*/,"MSIL1C",prodtype)
		gsub(/^OL_.*/,"OL",prodtype)
		gsub(/^SL_.*/,"SL",prodtype)
		gsub(/^SR_.*/,"SR",prodtype)
		gsub(/^S5P_NRTI_/,"",prodtype)
		gsub(/^S5P_OFFL_/,"",prodtype)
		gsub(/^S5P_RPRO_/,"",prodtype)
	}


	print user "," platform "," prodtype "," product "," size
}' | sed -f users.pat

