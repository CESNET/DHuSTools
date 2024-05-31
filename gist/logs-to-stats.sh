#!/bin/bash

if [ "$1" == "" ]; then
	1>&2 echo "No pattern given, counting for all logs"
	PATTERN=""
else 
	1>&2 echo "Only considering logs with \"$1\""
	PATTERN="*$1"
fi

if [ ! -f "users.pat" ]; then
	>&2 printf "This script expects file \"users.pat\" with sed patterns to replace simple username occurrences with csv values. Line by line, for example:\n\ts/^sustr4,/sustr4,Research,Other,Czech Republic,/\nThis is best produced by tweaking the output of:\n\tSELECT login,login,usage,domain,country FROM users;\nIt is possible to start with the \"users.pat\" file in simple tabular TAB-separated format instead. If so this script will attempt to reformat the file on first run.\n\nYou can use an argument as a pattern (e.g., year) to filter log files that should be considered.\n"
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

for f in "${PATTERN}*.log.gz"; do gunzip -c $f; done | \
grep --text -E '(download.*by.*user.*completed)' | grep -v manifest.safe | grep -v xfdumanifest.xml | grep -ivE '.[GXK]ML)' | awk '{ print $10 " " $6 " " $15 }' | sed "s/['()]//g" | \
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
