# For each day and download source print the number of ms spent downloading products
# It also outputs the total size of the products for bandwidth assessment
# Output to be fed into pivot tables

cat *.log | grep "successfully synchronized from" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \(\S\S*\).*(\([0-9][0-9]*\) bytes compressed).*from https:\/\/\([^/]*\).*/\2,\1,b,\3,\4,cut_here/' > list.$$.A

cat *.log | grep "stored in " | grep ".zip:" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \[\(\S\S*\)\.zip:.*stored.* in \([0-9][0-9]*\)ms.*/\2,\1,a,\3,/' > list.$$.B

sort list.$$.A list.$$.B > list.$$.C

cat list.$$.C | while read l; do printf "${l/,cut_here/\\n}"; done > list.$$.all.csv


echo date,source,ms,hrs,count,size
cat list.$$.all.csv | egrep ',a,.*,b,' | egrep -v '([^,]*,){9}' | awk -F '[, ]' '{ print $2 "," $11 " " $5 " " $10 }' | sort | awk 'BEGIN {
	lastdatesrc="";
	sum=0;
	sizesum=0;
	count=0; }
{
	if($1 != lastdatesrc) {
		if(lastdatesrc != "") {
			print lastdatesrc "," sum "," sum/3600000 "," count "," sizesum; }
		sum=0;
		sizesum=0;
		count=0;
		lastdatesrc=$1;
		print lastdatesrc > "/dev/stderr"
	}
	sum+=$2;
	sizesum+=$3;
	count+=1;
} END {
	print lastdatesrc "," sum "," sum/3600000 "," count "," sizesum; }'


rm list.$$.A list.$$.B list.$$.C list.$$.all.csv

