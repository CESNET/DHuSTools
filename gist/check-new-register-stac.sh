#!/bin/bash
# This script is meant for being called regularly by cron

SCRIPTNAME="`basename -s .sh $0`"
LOCK="/var/tmp/$SCRIPTNAME.lock"
VARPREFIX="/var/tmp/stac-new-`date +%Y-%m-%d_%H:%M`"

if [ -e $LOCK ]; then
	1>&2 printf "Exitting: Lock file exists: $LOCK\n\"$SCRIPTNAME\" is only meant to be run once at a time.\n\n"
	exit 1
else
	touch $LOCK
	trap "rm \"$LOCK\"" EXIT
fi

bash ./gen_new_list.sh -e -v https://dhr1.cesnet.cz > "$VARPREFIX"

echo "Spoustim ./register-stac.sh"

#Vyvoreni .netrc2 pro overeni pres curl pro katalog
echo "machine $CATALOG" >> /root/.netrc2     && echo "login $LOGIN2" >> /root/.netrc2     && echo "password $PASSWORD2" >> /root/.netrc2

cat "$VARPREFIX" | while read id; do
	 ./register-stac.sh $id
done
echo "Dokoncil jsem script!"
