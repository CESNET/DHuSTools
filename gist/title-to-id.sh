#!/bin/bash
# This simple gist translates a products title into a corresponding ID
# and returns the URL to download that product
# It has a default DHuS endpoint hard-coded but
# you can override it with argument #2
# The script assumes you have your credentials in .netrc

TITLE=$1
HOST=$2
if [ "$HOST" == "" ]; then
	HOST="https://dhr1.cesnet.cz"
fi

BN=`echo $TITLE | sed 's/\.[^.]*$//'` # this strips extensions such as .ZIP or .SAFE

ID=$(curl -s -n --silent ${HOST}/odata/v1/Products?%24format=text/csv\&%24select=Id\&%24filter=Name%20eq%20%27$BN%27 | tail -n 1 | sed 's/\r//' )
if [ "$ID" == 'Id' -o "$ID" == "" ]; then
	>&2 echo Product with name \"$BN\" not found
exit 1
fi
URL="${HOST}/odata/v1/Products('$ID')/\$value"
echo $URL

