
if [ "$1" == "" ]; then
	MASK="*.log"
else
	MASK=$1
fi

PLOT=""

for f in $MASK; do 

BN=`basename $f`	
cat $f | grep "stored in synchronized-hfs-without-copy datastore" | grep "zip:" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*:\([0-9]*\)\].*in \([0-9]*\)ms.*$/\1 \2 \3/' | awk -v f="$f" '{
	etime=$1" "$2;
	gsub(":"," ",etime);
	gsub("-"," ",etime);
	ets=mktime(etime);
	dura=($4==0)? 0 : $4/1000;
	sts=ets-dura
	print $1 $2 $3 $4 $5
	bw=($4==0)? 0 : $3/$4/1000;
	print strftime("%Y-%m-%e %H:%M:%S", sts) "," f "," bw;
	print strftime("%Y-%m-%e %H:%M:%S", ets) "," f ",-" bw;
}' | sort | awk -v f="$f" -F "\"*,\"*" 'BEGIN{
	sum=0;
	printf "\n\n", f
} {
	oldsum=sum
	sum+=$3
	printf "%s %s %0.1f\n", $2, $1, oldsum
	printf "%s %s %0.1f\n", $2, $1, sum
}' > out.$BN.$$.dat
PLOT="${PLOT}\"out.${BN}.$$.dat\" u 2:4 w l, "
done 

cat << EOF > plot.dat
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "$d.%m. %H:%M:%S"

set terminal pdf size 11.69,8.27
set output "out.pdf"

plot $PLOT
EOF

gnuplot plot.dat

rm out.*.$$.dat

