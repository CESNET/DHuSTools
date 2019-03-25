#!/bin/bash

# Defaults
SKIPSTOPPED=1
SENDINCOMPLETE=0
REMOTES="./.remote_syncers"
VARDIR="/var/tmp/report-syncers"
DRY=0
JISSUE="https://copernicus.serco.eu/jira-osf/rest/api/2/issue/EDR-99/comment"
XTRAARG=""

# Table formatting (Jira is default, other formats perhaps later)
GREETINGLINE="Dear colleagues, we have updated our synchronizers as follows:\\\\n\\\\n" #This is fully optional. Put newlines in here if required
GOODBYELINE="\\\\nGenerated automatically with DHuSTools."  #This is fully optional. Put newlines in here if required
TABLEHEAD="||Label || Schedule || PageSize || FilterParam || ServiceLogin || URL || ID || Instance ||"
TABLETAIL=""
TABROWSTART="|"
TABROWEND="|"
TABCOLSEP=" | "

#Internal variables
INCOMPLETE=0

# Override defaults with config file content, if CFs exist
for CONF in "/etc/report-syncers.conf" "$HOME/.report-syncers.conf"; do
	if [ -f "$CONF" ]; then
		echo Reading configuration from "$CONF"
		source "$CONF"
	fi
done

#Expand tildes in paths if used
REMOTES="${REMOTES/#\~/$HOME}"
VARDIR="${VARDIR/#\~/$HOME}"

while getopts "hl:w:dj:x:c:" opt; do
  case $opt in
        h)
                printf "Collect DHuS Synchronizer settings, compile into table and upload.\n\nUsage:\n
\t-l <str>\tPath to a file containing remote paths\n\t\t\t(Default \"${REMOTES}\")\n \
\t-w <str>\tPath to the working directory (Default \"${VARDIR}\")\n \
\t-d      \tDry run. Do everything but do not upload to Jira.\n \
\t-j <url>\tUpload URL (default \"${JISSUE}\")\n \
\t-x <str>\tAny extra arguments to be handed over to curl\n \
\t-c <str>\tPath to configuration file to specify multiple options\n \
		\n"
                exit 0
                ;;
	d)
		DRY=1
                ;;
	l)
		REMOTES=$OPTARG
                ;;
	w)
		VARDIR=$OPTARG
                ;;
	j)
		JISSUE=$OPTARG
                ;;
	x)
		XTRAARG=" $OPTARG "
                ;;
	c)
		CONF="$OPTARG"
		if [ -f "$CONF" ]; then
			echo Reading configuration from "$CONF"
			source "$CONF"
		else
			echo "Specified configuration file $CONF not found" >&2
			exit 1
		fi
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
check_binaries sed cat cp curl grep echo diff

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


printf "{ \"body\": \"" > "$VARDIR/syncers.$$.md"

printf "$GREETINGLINE$TABLEHEAD\\\\n" >> "$VARDIR/syncers.$$.md"

while read INSTANCE; do
	# Download synchronizers XML
	RAWSYNC=`curl -n "$INSTANCE"`
	if [ $? -ne 0 ]; then # Download failed, the report won't be complete
		((INCOMPLETE++))
	fi

	# Put all output in one line and then break into lines per entry
	echo "${RAWSYNC}" | sed 's/\r//g' | sed 's/<\/entry>/<\/entry>\n/g' | while read line; do

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
			printf "$TABROWSTART$LABEL$TABCOLSEP$SCHEDULE$TABCOLSEP$PAGESIZE$TABCOLSEP$FILTERPARAM$TABCOLSEP$SERVICELOGIN$TABCOLSEP$URL$TABCOLSEP$ID$TABCOLSEP$INSTANCESHORT$TABROWEND\\\\n" >> "$VARDIR/syncers.$$.md"
		fi

	done
done < ${REMOTES}

printf "$TABLETAIL$GOODBYELINE" >> "$VARDIR/syncers.$$.md"

printf "\" }" >> "$VARDIR/syncers.$$.md"

##########################################
# Step 40: Check for changes and upload

cat "$VARDIR/syncers.$$.md"; printf "\n"

diff "$VARDIR/syncers.$$.md" "$VARDIR/syncers.md" >/dev/null 2>/dev/null
if [ $? -gt 0 ]; then

	TRULLYREPORT=1

	if [ $INCOMPLETE -gt 0 ]; then
		echo Failed contacting ${INCOMPLETE} endpoints
		if [ ${SENDINCOMPLETE} -eq 0 ]; then
			echo Skipping report upload
			TRULLYREPORT=0
		fi
	fi

	if [ $DRY -ne 0 ]; then
		echo Update detected but Dry Run has been forced.
		TRULLYREPORT=0
	fi

	if [ $TRULLYREPORT -eq 1 ]; then
		echo Update detected. Uploading...
		cp -f "$VARDIR/syncers.$$.md" "$VARDIR/syncers.md"
		curl -D- --netrc -X POST --data @$VARDIR/syncers.md -H "Content-Type: application/json" ${XTRAARG} "${JISSUE}"
	fi
fi

rm "$VARDIR/syncers.$$.md"


