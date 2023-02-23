#!/bin/bash


echo Downloading ...

mkdir -p dhr1
mkdir -p dhr2

scp root@dhr1.cesnet.cz:/mnt/data-archive/logs_history/* dhr1/
scp root@dhr2.cesnet.cz:/mnt/rbd-dhr2_data/logs_history/* dhr2/

ORIGDIR=`pwd`

echo ORIGDIR is $ORIGDIR

find . -mindepth 1 -maxdepth 1 -type d | while read dir; do
	cd $dir
	echo Unpacking files in $dir
	for f in *.tar.gz; do
		tar xfz $f
	done

	touch test.log

	echo Moving logs from $dir to $ORIGDIR
	for f in *.log; do
		mv $f ${ORIGDIR}/`basename ${dir}`-${f}
	done

	cd ${ORIGDIR}
done
