# Process DHuS log files, extract product synchronization and storage records,
# put them side by side and output a CSV file suitable for spreadsheet pilot tables


cat *.log | grep "successfully synchronized from" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \(\S\S*\).*(\([0-9][0-9]*\) bytes compressed).*from https:\/\/\([^/]*\).*/\2,a,\1,\3,\4,stitch_here/' > list.A
cat *.log | grep "stored in synchronized-hfs-without-copy" | grep ".zip:" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*Product \[\(\S\S*\)\.zip:.*stored.* in \([0-9][0-9]*\)ms.*/\2,b,\1,\3/' > list.B

sort list.A list.B > list.all.csv
sed -i ':a;N;$!ba;s/stitch_here\n//g' list.all.csv

