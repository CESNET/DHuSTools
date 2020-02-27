
echo Average qeuery response duration by hour of day
NAM=`ls *.log | egrep -o '[0-9][0-9\-]*' | sort | tail -n 1`
egrep 'Access.*-SUCCESS-' *.log > dwls
grep 'filter=CreationDate' dwls > queries # Filter out downloads, keep only syncer queries
cat queries | sed 's/.*\[\(201[89]-[0-9][0-9]-[0-9][0-9]\) \([0-9][0-9]\).*Access[^0-9]*\([.0-9]*\)ms\]\s\(\S\S*\).*/\1;\2 \3 \4/' | sort > queries_hrs.csva
echo "Date;Hour,Duration,Count,Average [s]" > res-by-hr-${NAM}.csv
cat queries_hrs.csv | awk 'START{ last=$1 } { if($1!=lasthr) { if(count + 0 != 0) {avg=sum/count/1000} else { avg="" }; print lasthr "," sum "," count "," avg ; sum=0; count=0 } sum+=$2; count+=1; lasthr=$1; } END { print lasthr "," sum "," count "," sum/count/1000 }' >> res-by-hr-${NAM}.csv


echo Avreage query response duration by originator
cat queries | sed 's/.*\[\(201[89]-[0-9][0-9]-[0-9][0-9]\) \([0-9][0-9]\).*Access[^0-9]*\([.0-9]*\)ms\]\s\(\S\S*\).*/\4 \3/' | sort > query_srcs.csv
cat query_srcs.csv | awk 'START{ last=$1; count=0 } { if($1!=last) { if(count + 0 != 0) {avg=sum/count/1000} else { avg="" }; print last "," sum "," count "," avg; sum=0; count=0 } sum+=$2; count+=1; last=$1; } END { print last "," sum "," count "," sum/count/1000 }' > res-histo-${NAM}.csv
