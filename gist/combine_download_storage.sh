# Grep synchronized product records form DHuS logs and produce a one-per line
# CSV file suitable as input into spreadsheet pilot tables

cat *.log | grep "successfully synchronized from" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \(\S\S*\).*(\([0-9][0-9]*\) bytes compressed).*from https:\/\/\([^/]*\).*/\2,a,\1,\3,\4,stitch_here/' > list.A

cat *.log | grep "stored in " | grep ".zip:" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \[\(\S\S*\)\.zip:.*stored.* in \([0-9][0-9]*\)ms.*/\2,b,\1,\3/' > list.B

sort list.A list.B > list.all.csv

sed -i ':a;N;$!ba;s/stitch_here\n//g' list.all.csv

