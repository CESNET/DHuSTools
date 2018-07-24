#!/bin/bash

FILTER=""

while getopts "hf:" opt; do
  case $opt in
        h)
                printf "Parse DHuS logs and generate bandwidth charts.\n\nUsage:\n
\t-h      \tDisplay this help\n \
\t-f <str>\tCustom plot data filter (passed to grep -E before plotting the data\n \
\n\n"
                exit 0
                ;;
        f)
                FILTER="${OPTARG}"
                ;;
  esac
done

shift $(($OPTIND - 1))
MASK=$1

if [ "$MASK" == "" ]; then
	MASK="*.log"
fi

PLOT=""
PID=$$

echo Generating out files by endpoint
for f in $MASK; do
	cat $f | grep "successfully [a-z]* from" | grep "zip'" | sed 's/\[[0-9.-]*\]\s*\[\([0-9: -]*\),[0-9]*\].*(\([0-9]*\) bytes compressed).* from http[s]*:\/\/\([^/]*\).*in \([0-9]*\) ms.*/\1 \2 \4 \3/' | awk -v pid="$PID" '{ outfile=$5"."pid".out"; print $1" "$2" "$3" "$4" "$5 >> outfile }'
done

wc -l *.${PID}.out

echo Generating plot data
for f in *.${PID}.out; do
	BN=`basename $f`
	cat $f | awk -v f="$f" '{
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

if [ "$FILTER" != "" ]; then
	grep -E "${FILTER}" out.$BN.$$.dat > out.$BN.$$.dat.grepped
	mv -f out.$BN.$$.dat.grepped out.$BN.$$.dat
fi

PLOT="${PLOT}\"out.${BN}.$$.dat\" u 2:4 w l, "
done 

cat << EOF > plot.dat
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "$d.%m. %H:%M:%S"

set terminal pdf size 19.20,10.80
set output "out.pdf"

plot $PLOT
EOF

gnuplot plot.dat

rm out.*.$$.dat
rm *.${PID}.out

