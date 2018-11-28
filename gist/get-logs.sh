#!/bin/bash
# This gist downloads and combines log files from multiple sources

rsync -v root@be1.dhr.cesnet.cz:/var/dhus/dhus-datahub/logs/dhus-2018-*.log ./dhus1/
rsync -v root@be1.dhr.cesnet.cz:/var/dhus2/dhus-datahub/logs/dhus-2018-*.log ./dhus2/

cd dhus1
for f in *.log; do echo $f; cat $f > ../$f; done
cd ..

cd dhus2
for f in *.log; do echo $f; cat $f >> ../$f; sort -o ../$f ../$f; done
cd ..

