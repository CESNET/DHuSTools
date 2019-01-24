#!/bin/bash
# This gist downloads and combines log files from multiple sources

rsync -v root@be1.dhr.cesnet.cz:/var/dhus/dhus-datahub/logs/dhus-2*.log ./be1-dhus1/
rsync -v root@be1.dhr.cesnet.cz:/var/dhus2/dhus-datahub/logs/dhus-2*.log ./be1-dhus2/
rsync -v root@be2.dhr.cesnet.cz:/var/dhus/dhus1/dhus-datahub/logs/dhus-2*.log ./be2-dhus1/
rsync -v root@be2.dhr.cesnet.cz:/var/dhus/dhus2/dhus-datahub/logs/dhus-2*.log ./be2-dhus2/

rm ./dhus-2*.log

for d in be1-dhus1 be1-dhus2 be2-dhus1; do
	cd $d
	for f in *.log; do echo $f; cat $f >> ../$f; done
	cd ..
done

for f in dhus-2*.log; do sort -o $f $f; done
