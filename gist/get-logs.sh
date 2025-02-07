#!/bin/bash
# This gist downloads and combines log files from multiple sources

mkdir -p ./be2-dhus1 ./be2-dhus2 ./be2-dhus1 ./be2-dhus2 ./fe1-dhus1

rsync -v root@be1.dhr.cesnet.cz:/var/dhus/dhus1/dhus-datahub/logs/dhus-2*.log.gz ./be1-dhus1/
rsync -v root@be1.dhr.cesnet.cz:/var/dhus/dhus2/dhus-datahub/logs/dhus-2*.log.gz ./be1-dhus2/
rsync -v root@be2.dhr.cesnet.cz:/var/dhus/dhus1/dhus-datahub/logs/dhus-2*.log.gz ./be2-dhus1/
rsync -v root@be2.dhr.cesnet.cz:/var/dhus/dhus2/dhus-datahub/logs/dhus-2*.log.gz ./be2-dhus2/
rsync -v root@fe1.dhr.cesnet.cz:/var/dhus/dhus-datahub/logs/dhu*.log.gz ./fe1-dhus1/

rm ./dhus-2*.log.gz

find be* -name *.log.gz -exec basename -s .log.gz {} \; | grep -Eo '^dhus-....-..-..' | sort | uniq | while read bn; do
	echo ${bn}
	for file in be*/${bn}*log.gz; do
		>&2 echo "⌞ $file"
		gunzip -c $file
	done | sort | gzip -c > ${bn}.log.gz
done
