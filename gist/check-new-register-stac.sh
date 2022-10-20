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

./gen_new_list.sh https://dhr1.cesnet.cz > "$VARPREFIX"

cat "$VARPREFIX" | while read id; do
	./register-stac.sh $id
done

