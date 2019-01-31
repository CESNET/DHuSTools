egrep 'Access.*-SUCCESS-' *.log > dwls
grep 'filter=CreationDate' dwls > queries # Filter out downloads, keep only syncer queries
cat queries | sed 's/.*\[\(201[89]-[0-9][0-9]-[0-9][0-9]\) \([0-9][0-9]\).*Access[^0-9]*\([.0-9]*\)ms\]\s\(\S\S*\).*/\2 \3 \4/' | sort > queries_hrs.csv
cat queries_hrs.csv | awk '{ if($1!=lasthr) { print lasthr "," sum "," count "," sum/count; sum=0; count=0 } sum+=$2; count+=1; lasthr=$1; } END { print lasthr "," sum "," count "," sum/count }'
