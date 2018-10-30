#!/bin/bash

function check_binaries()
{
        for file in $@; do
                ret=`which $file 2> /dev/null`
                if [ ! -x "$ret" ]; then
                        echo "command $file not found" >&2
                        exit 1
                fi
        done
}

UPWD="-n"
GRANULEONLY=1

while getopts "hu:G" opt; do
  case $opt in
	h)
		printf "Download Sentinel product and compare the contents of the ZIP file to the manifest within.\n\n Usage:\n \
\t${argv[0]} [options] <product URL>\n \
\t${argv[0]} [options] <DHuS instance> <Product ID>\n \
\t${argv[0]} [options] <DHuS instance> <Product Name>\n \
\t-h      \tDisplay this help\n \
\t-u <str>\tuser:password to use accessing the remote site.\n \
\t-G      \tDo not grep the final output for 'GRANULE'.\n \
\t\t\tThis is passed directly to curl.\n\n"
		exit 0
		;;
	u)
		UPWD="-u \"$OPTARG\""
		;;
	G)
		GRANULEONLY=0
		;;
  esac
done

shift $(($OPTIND - 1))

if [ $# -eq 1 ]; then
	URL=$1
	>&2 echo Single download URL given: $URL
else
	PRIM=$1
	SEC=$2
	echo "$SEC" | egrep -x '[0-9a-z\-]*' > /dev/null
	if [ $? -eq 0 ]; then
		URL="https://$(echo $PRIM | sed 's/^[htps:]*\/\///' | sed 's/\\*$//')/odata/v1/Products('$SEC')/\$value"
		>&2 echo Assuming URL: $URL
	else
		HOST="https://$(echo $PRIM | sed 's/^[htps:]*\/\///' | sed 's/\\*$//')/"

		# Treating SEC as poduct name. Stripping suffix in case someone used it
		BN=`echo $SEC | sed 's/\.[^.]*$//'`

		#Have product name translated to ID
		ID=$(curl -s $UPWD ${HOST}odata/v1/Products?%24format=text/csv\&%24select=Id\&%24filter=Name%20eq%20%27$BN%27 | tail -n 1 | sed 's/\r//' )
		if [ $ID == 'Id' ]; then
			>&2 echo Product with name \"$SEC\" not found
			exit 1
		fi
		URL="${HOST}odata/v1/Products('$ID')/\$value"
		>&2 echo Assuming URL: $URL
	fi
fi

check_binaries sed unzip basename cat curl grep egrep diff

#Download the product file
FN=`curl $UPWD -JO "$URL" | egrep -o "'.*'" | sed "s/'//g"`

if [ "$FN" == "" ]; then
	>&2 echo Download failed
	exit 1
fi

BN=`basename -s .zip $FN`

>&2 echo Got file $FN, unzipping manifest

#Get full manifest path within thi ZIP file and then extract it
MAN=`unzip -Z1 $FN | grep manifest`
unzip -qq $FN $MAN
#Take only 'href="..."' sections from the manifest, which is in XML, and write them in a list
cat $MAN | egrep -o 'href="[^"]*"' | sed 's/^href="[./]*//' | sed 's/"$//' | sort > $BN.manifest.lst

#List all files in the ZIP, remove the leading directory name and remove directory names (leave only regular files)
unzip -Z1 $FN | sed "s/$BN\\.SAFE\///" | egrep -v "/$" | sort > $BN.real.lst

if [ $GRANULEONLY -eq 1 ]; then
	diff "$BN.manifest.lst" "$BN.real.lst" | grep 'GRANULE/'
else
	diff "$BN.manifest.lst" "$BN.real.lst"
fi

exit 0
