#!/bin/bash

# Defaults
SKIPSTOPPED=1
REMOTES="./.remote_syncers"
VARDIR="/var/tmp/report-syncers"
DRY=0
JISSUE="https://copernicus.serco.eu/jira-osf/rest/api/2/issue/CRDR-7/attachments"
XTRAARG=""

# Table formatting (Jira is default)
TABLEHEAD="||Id || Status || Label || Schedule || PageSize || FilterParam || ServiceLogin || URL || Instance ||"
TABLETAIL=""
TABROWSTART="|"
TABROWEND="|"
TABCOLSEP=" | "

while getopts "hl:w:dj:x:" opt; do
  case $opt in
        h)
                printf "Collect DHuS Synchronizer settings, compile into table and upload.\n\nUsage:\n
\t-l <str>\tPath to a file containing remote paths\n\t\t\t(Default \"${REMOTES}\")\n \
\t-w <str>\tPath to the working directory (Default \"${VARDIR}\")\n \
\t-d      \tDry run. Do everything but do not upload to Jira.\n \
\t-j <url>\tUpload URL (default \"${JISSUE}\")\n \
\t-x <str>\tAny extra arguments to be handed over to curl\n \
		\n"
                exit 0
                ;;
	c)
		STATSCRIPT=$OPTARG
                ;;
	d)
		DRY=1
                ;;
	o)
		XLS=$OPTARG
                ;;
	l)
		REMOTES=$OPTARG
                ;;
	w)
		VARDIR=$OPTARG
                ;;
	n)
		NDAYS=$OPTARG
                ;;
	t)
		TILL=$OPTARG
                ;;
	j)
		JISSUE=$OPTARG
                ;;
	x)
		XTRAARG=" $OPTARG "
                ;;
  esac
done

function check_binaries()
{
	for file in $@; do
		ret=`which $file 2> /dev/null`
		if [ -n "$ret" -a -x "$ret" ]; then
			echo $ret
	        else
			echo "command $file not found" >&2
			exit 1
	        fi
	done
}


##########################################
# Step 10: Test prerequisites

echo Checking prerequisites
check_binaries sed cat cp curl grep

##########################################
# Step 20: Atrribute constraints check

if [ ! -d "$VARDIR" ]; then
	mkdir -p "$VARDIR"
	if [ ! -d "$VARDIR" ]; then
		echo Working directory \"$VARDIR\" does not exist! >&2
		exit 1
	fi
fi

if [ ! -f "$REMOTES" ]; then
	echo Remote locations list in \"$REMOTES\" not found! >&2
	exit 1
fi


##########################################
# Step 30: Loop over sources

printf "$TABLEHEAD\n" > "$VARDIR/syncers.$$.md"

while read INSTANCE; do
	# Download synchronizers XML, put it all in one
        # line and then break into lines per entry
	curl -n "$INSTANCE" | sed 's/\r//g' | sed 's/<\/entry>/<\/entry>\n/g' | while read line; do

		# Extract attributes for table
		ID=`echo "$line" | sed 's/.*<d:Id>\(.*\)<\/d:Id>.*/\1/'`
		STATUS=`echo "$line" | sed 's/.*<d:Status>\(.*\)<\/d:Status>.*/\1/'`
		LABEL=`echo "$line" | sed 's/.*<d:Label>\(.*\)<\/d:Label>.*/\1/'`
		URL=`echo "$line" | sed 's/.*<d:ServiceUrl>\(.*\)<\/d:ServiceUrl>.*/\1/'`
		SCHEDULE=`echo "$line" | sed 's/.*<d:Schedule>\(.*\)<\/d:Schedule>.*/\1/'`
		PAGESIZE=`echo "$line" | sed 's/.*<d:PageSize>\(.*\)<\/d:PageSize>.*/\1/'`
		FILTERPARAM=`echo "$line" | sed 's/.*<d:FilterParam>\(.*\)<\/d:FilterParam>.*/\1/'`
		SERVICELOGIN=`echo "$line" | sed 's/.*<d:ServiceLogin>\(.*\)<\/d:ServiceLogin>.*/\1/'`
		INSTANCESHORT=`echo "$INSTANCE" | sed 's/\/[^/]*$//'`

		# Output formatted table
		if [ $SKIPSTOPPED -eq 0 -o "$STATUS" != "STOPPED" ]; then
			printf "$TABROWSTART$ID$TABCOLSEP$STATUS$TABCOLSEP$LABEL$TABCOLSEP$SCHEDULE$TABCOLSEP$PAGESIZE$TABCOLSEP$FILTERPARAM$TABCOLSEP$SERVICELOGIN$TABCOLSEP$URL$TABCOLSEP$INSTANCESHORT$TABROWEND\n" >> "$VARDIR/syncers.$$.md"
		fi

	done
done < ${REMOTES}

printf "$TABLETAIL\n" >> "$VARDIR/syncers.$$.md"

cat "$VARDIR/syncers.$$.md"

