#!/bin/bash


echo Downloading ...

mkdir -p dhr1
mkdir -p dhr2

#scp root@dhr1.cesnet.cz:/mnt/data-archive/logs_history/* dhr1/
#scp root@dhr2.cesnet.cz:/mnt/rbd-dhr2_data/logs_history/* dhr2/

ORIGDIR=`pwd`

echo ORIGDIR is $ORIGDIR

find . -mindepth 1 -maxdepth 1 -type d | while read dir; do
	echo linking files in $dir
	DBN=`basename ${dir}`
	for f in ${dir}/*.tar.gz; do
		BN=`basename $f`
		1>&2 echo untar $f
		mkdir tmp.$$
		tar xfz $f -C tmp.$$
		find tmp.$$ -type f -exec mv {} ./ \;
		find tmp.$$ -depth -type d -exec rmdir {} \;
		for lg in *.log; do
			1>&2 echo $lg
			mv $lg ${DBN}-${lg}
			gzip ${DBN}-${lg}
		done
	done
done
