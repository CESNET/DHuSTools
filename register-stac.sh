#!/bin/bash

DEBUG=1
ID="$1"
HOST="https://dhr1.cesnet.cz/"
STACHOST="https://stac.cesnet.cz"
TMP="/tmp"
SUCCPREFIX="/var/tmp/register-stac-success-"
ERRPREFIX="/var/tmp/register-stac-error-"

######################################
#
# functions
#
######################################

make-sed-filter () {

cat << EOF > ${TMP}/prefix2collection.sed
s/^S1[A-DP]_.._GRD[HM]_.*/sentinel-1-grd/
s/^S1[A-DP]_.._SLC__.*/sentinel-1-slc/
s/^S1[A-DP]_.._RAW__.*/sentinel-1-raw/
s/^S1[A-DP]_.._OCN__.*/sentinel-1-ocn/
s/^S2[A-DP]_MSIL1B_.*/sentinel-2-l1b/
s/^S2[A-DP]_MSIL1C_.*/sentinel-2-l1c/
s/^S2[A-DP]_MSIL2A_.*/sentinel-2-l2a/
s/^S3[A-DP]_OL_1_.*/sentinel-3-olci-l1b/
s/^S3[A-DP]_OL_2_.*/sentinel-3-olci-l2/
s/^S3[A-DP]_SL_1_.*/sentinel-3-slstr-l1b/
s/^S3[A-DP]_SL_2_.*/sentinel-3-slstr-l2/
s/^S3[A-DP]_SR_1_.*/sentinel-3-stm-l1/
s/^S3[A-DP]_SR_2_.*/sentinel-3-stm-l2/
s/^S3[A-DP]_SY_1_.*/sentinel-3-syn-l1/
s/^S3[A-DP]_SY_2_.*/sentinel-3-syn-l2/
s/^S5[A-DP]_OFFL_L1_.*/sentinel-5p-l1/
s/^S5[A-DP]_NRTI_L1_.*/sentinel-5p-l1/
s/^S5[A-DP]_OFFL_L2_.*/sentinel-5p-l2/
s/^S5[A-DP]_NRTI_L2_.*/sentinel-5p-l2/
EOF

}


######################################
#
# Initial checks and settings
#
######################################

if [ "${ID}" == "" ]; then
	1>&2 echo $0: No ID specified
	exit 1
fi

if [ ! -e ${TMP}/prefix2collection.sed ]; then
	1>&2 echo $0: Generating SED filter for collections
	make-sed-filter
	if [ ! -e ${TMP}/prefix2collection.sed ]; then
		1>&2 echo $0: Failed to store SED file. Cannot continue.
		exit 1
	fi
fi

which xmlstarlet >/dev/null
if [ $? -gt 0 ]; then
	1>&2 echo $0: xmlstarlet not installed
	exit 1
fi



RUNDATE=`date +%Y-%m-%d`

######################################
#
# Make and move to temporary directory
#
######################################

ORIGDIR=`pwd`

mkdir -p "${TMP}/register-stac.$$"

cd "${TMP}/register-stac.$$"

######################################
#
# Get metadata from DHuS Database
#
######################################

curl -n -o node.xml "${HOST}odata/v1/Products(%27${ID}%27)/Nodes"
TITLE=`xmlstarlet sel -d -T -t -v "//_:entry/_:title" node.xml`
PREFIX=`xmlstarlet sel -d -T -t -v "//_:entry/_:id" node.xml`
PRODUCTURL=`echo "${PREFIX}" | sed 's/\\Nodes.*//'`
PLATFORM="${TITLE:0:2}"
COLLECTION=`echo $TITLE | sed -f ${TMP}/prefix2collection.sed`

1>&2 echo Getting metadata for $TITLE "(ID: ${ID})"
1>&2 echo Download prefix: ${PREFIX}
1>&2 echo Platform prefix: ${PLATFORM}
1>&2 echo Using colection: ${COLLECTION}

######################################
#
# Extract metadata files (manifests)
#
######################################


mkdir "${TITLE}"

# Get manifest

if [ "$PLATFORM" == "S1" -o "$PLATFORM" == "S2" ]; then
	MANIFEST="${TITLE}/manifest.safe"
	curl -n -o "${MANIFEST}" "${PREFIX}/Nodes(%27manifest.safe%27)/%24value"
elif [ "$PLATFORM" == "S3" -o "$PLATFORM" == "S3p" ]; then
	MANIFEST="${TITLE}/xfdumanifest.xml"
	curl -n -o "${MANIFEST}" "${PREFIX}/Nodes(%27xfdumanifest.xml%27)/%24value"
else
	MANIFEST="${TITLE}"
	rmdir "${TITLE}"
	curl -n -o "${MANIFEST}" "${PREFIX}/%24value"
fi

# download other metadata files line by line (Only for S1 and S2)
if [ "$PLATFORM" == "S1" -o "$PLATFORM" == "S2" ]; then
	cat "${MANIFEST}" | grep 'href=' | grep -E "/MTD_MSIL2A.xml|MTD_MSIL1C.xml|/MTD_TL.xml|annotation/s1a.*xml" | sed 's/.*href="//' | sed 's/".*//' |
	while read file; do
		1>&2 echo Downloading $file
		URL="${PREFIX}/Nodes(%27$(echo $file | sed "s|^\.*\/*||" | sed "s|\/|%27)/Nodes(%27|g")%27)/%24value"
	#	echo $URL
		mkdir -p "${TITLE}/$(dirname ${file})"
		curl -n -o "${TITLE}/${file}" "${URL}"
	done
fi

# create empty directiries stac-tools look into (only S1)
if [ "$PLATFORM" == "S1" ]; then
	mkdir -p "${TITLE}/annotation/calibration"
	mkdir -p "${TITLE}/measurement"
fi


find . 1>&2

######################################
#
# Generate JSON
#
######################################

if [ "$PLATFORM" == "S2" ]; then
	~/.local/bin/stac sentinel2 create-item "${TITLE}" ./
elif [ "$PLATFORM" == "S1" ]; then
	~/.local/bin/stac sentinel1 grd create-item "${TITLE}" ./
elif [ "$PLATFORM" == "S3" ]; then
	~/.local/bin/stac sentinel3 create-item "${TITLE}" ./
elif [ "$PLATFORM" == "S5" ]; then
	~/.local/bin/stac sentinel5p create-item "${TITLE}" ./
fi

######################################
#
# Doctor JSON
#
######################################

file=`ls *.json | head -n 1`
printf "\n" >> "$file" # Poor man's hack to make sure `read` gets all lines
cat "$file" | while IFS= read line; do
	if [[ "$line" =~ .*\"href\":.*\.(SAFE|SEN3|nc)[/\"].* ]]; then # TODO: Less fragile code
		echo Modifying line \"$line\"
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

curl -n -o output.json -X POST "${STACHOST}/collections/${COLLECTION[${PLATFORM}]}/items" -H 'Content-Type: application/json' -H 'Accept: application/json' --upload-file "new_${file}"

######################################
#
# Cleanup
#
######################################


#TODO: Add reaction to {"ErrorMessage":"Not Found","ErrorCode":404}

# TODO: "ErrorCode":409
# TODO: "ErrorCode":404

grep '"status":"success"' output.json >/dev/null
if [ $? -eq 0 ]; then
	echo "${ID}" >> "${SUCCPREFIX}${RUNDATE}.csv"
else
	echo "${ID}" >> "${ERRPREFIX}${RUNDATE}.csv"
#	DEBUG="1"
fi


cd "${ORIGDIR}"

if [ "$DEBUG" == "" ]; then
	rm -rf "${TMP}/register-stac.$$"
else
	1>&2 echo Artifacts in "${TMP}/register-stac.$$"
fi

