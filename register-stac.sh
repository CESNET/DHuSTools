#!/bin/bash

ID="$1"
HOST="https://dhr1.cesnet.cz/"
COLLECTION="https://resto.c-scale.zcu.cz/collections/S2-experimental"
TMP="/tmp"
SUCCPREFIX="/var/tmp/register-stac-success-"
ERRPREFIX="/var/tmp/register-stac-error-"

######################################
#
# Initial checks and settings
#
######################################

if [ "${ID}" == "" ]; then
	1>&2 echo $0: No ID specified
	exit 1
fi

RUNDATE=`date +%Y-%m-%d`

######################################
#
# Get metadata from DHuS Database
#
######################################

XML=`curl -n -o - "${HOST}odata/v1/Products(%27${ID}%27)/Nodes"`
TITLE=`echo "${XML}" | sed "s/.*<entry>.*<link href=.Nodes('\([^']*\).*/\1/"`
PREFIX=`echo "${XML}" | sed "s/.*<entry>.*<id>\([^<]*\).*/\1/"`
PRODUCTURL=`echo "${PREFIX}" | sed 's/\\Nodes.*//'`


1>&2 echo Getting metadata for $TITLE "(ID: ${ID})"
1>&2 echo Download prefix: ${PREFIX}


######################################
#
# Extract metadata files (manifests)
#
######################################

ORIGDIR=`pwd`

mkdir -p "${TMP}/register-stac.$$"

cd "${TMP}/register-stac.$$"

mkdir "${TITLE}"

# Get manifest

curl -n -o "${TITLE}/manifest.safe" "${PREFIX}/Nodes(%27manifest.safe%27)/%24value"

# download other metadata files line by line
cat "${TITLE}/manifest.safe" | grep 'href=' | grep -E "/MTD_MSIL2A.xml|MTD_MSIL1C.xml|/MTD_TL.xml" | sed 's/.*href="//' | sed 's/".*//' |
while read file; do
	1>&2 echo Downloading $file
	URL="${PREFIX}/Nodes(%27$(echo $file | sed "s|^\.*\/*||" | sed "s|\/|%27)/Nodes(%27|g")%27)/%24value"
#	echo $URL
	mkdir -p "${TITLE}/$(dirname ${file})"
	curl -n -o "${TITLE}/${file}" "${URL}"
done

find . -type f 1>&2

######################################
#
# Generate JSON
#
######################################

~/.local/bin/stac sentinel2 create-item "${TITLE}" ./

######################################
#
# Doctor JSON
#
######################################

file=`ls *.json | head -n 1`
printf "\n" >> "$file" # Poor man's hack to make sure `read` gets all lines
cat "$file" | while IFS= read line; do
	if [[ "$line" =~ .*\"href\":.*\.SAFE.* ]]; then # TODO: Less fragile code
		path=`echo "$line" | sed 's/^[^"]*"href":[^"]*"//' | sed 's/",$//'`
		LEAD=`echo "$line" | sed 's/"href":.*/"href":/'`
		URL="${PRODUCTURL}/Nodes(%27$(echo $path | sed "s|^\.*\/*||" | sed "s|\/|%27)/Nodes(%27|g")%27)/%24value"
		echo "$LEAD \"${URL}\"," >> "new_${file}"

	else # No change
		echo "${line}" >> "new_${file}"
	fi
done


######################################
#
# Upload
#
######################################

curl -n -o output.json -X POST "${COLLECTION}/items" -H 'Content-Type: application/json' -H 'Accept: application/json' --upload-file "new_${file}"

######################################
#
# Cleanup
#
######################################

grep '"status":"success"' output.json >/dev/null
if [ $? -eq 0 ]; then
	echo "${ID}" >> "${SUCCPREFIX}${RUNDATE}.csv"
else
	echo "${ID}" >> "${ERRPREFIX}${RUNDATE}.csv"
	DEBUG="1"
fi


cd "${ORIGDIR}"

if [ "$DEBUG" == "" ]; then
	rm -rf "${TMP}/register-stac.$$"
else
	1>&2 echo Artifacts in "${TMP}/register-stac.$$"
fi

