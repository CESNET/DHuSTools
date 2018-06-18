#!/bin/bash

STATSCRIPT="./DataHubStats_TiB.sh"
XLS="./DHRNAME_report_referenceperiod_DataHubStats_v2.2.xlsx"
XLSPREFIX="CRDR"
REMOTES="./.remotes"
NDAYS=6
TILL=`date -d "yesterday" +%Y-%m-%d`
WRKD="/tmp"

while getopts "hc:o:l:n:f:w:t:" opt; do
  case $opt in
        h)
                printf "Collect, run and export DHuS Relay statistics\n\nUsage:\n
\t-c <str>\tPath to the statistics script\n\t\t\t(Default \"${STATSCRIPT}\")\n \
\t-o <str>\tPath to the output spreadsheet\n\t\t\t(Default \"${XLS}\")\n \
\t-l <str>\tPath to a file containing remote paths\n\t\t\t(Default \"${REMOTES}\")\n \
\t-w <str>\tPath to the working directory (Default \"${WRKD}\")\n \
\t-n <num>\tStart reporting period <num> days\n\t\t\tBEFORE the final date (Default ${NDAYS})\n \
\t-t <Y-M-D>\t\"Till\" Date (Default \"${TILL}\")\n \
		\n"
                exit 0
                ;;
	c)
		STATSCRIPT=$OPTARG
                ;;
	o)
		XLS=$OPTARG
                ;;
	l)
		REMOTES=$OPTARG
                ;;
	w)
		WRKD=$OPTARG
                ;;
	n)
		NDAYS=$OPTARG
                ;;
	t)
		TILL=$OPTARG
                ;;
  esac
done

function check_exec()
{
	local ret=`which $1 2> /dev/null`
	if [ -n "$ret" -a -x "$ret" ]; then
		return $TEST_OK
	else
		return $TEST_ERROR
	fi
}

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

FROM=`date -d "${TILL}-${NDAYS} days" +%Y-%m-%d`
WEEKTILL=`date -d "${TILL}" +%V`
WEEKFROM=`date -d "${FROM}" +%V`
if [ "${WEEKFROM}" == "${WEEKTILL}" ]; then
	WEEK="${WEEKTILL}"
else
	WEEK="${WEEKFROM}to${WEEKTILL}"
fi
YEAR=`date -d "${FROM}" +%Y`
XLSTARGET="${XLSPREFIX}_report_${FROM}_to_${TILL}_DataHubStats_v2.2.xlsx"


##########################################
# Step 02: Test prerequisites

echo Checking prerequisites
check_binaries sed libreoffice scp tar gzip basename date cat cp curl grep

if [ ! -f $HOME/.netrc ]; then
	echo File "$HOME/.netrc" not found. Upload to Jira would fail
	exit 1
fi

##########################################
# Step 03: Atrribute constraints check

if [ ! -d "$WRKD" ]; then
	mkdir -p "$WRKD"
	if [ ! -d "$WRKD" ]; then
		echo Working directory \"$WRKD\" does not exist! >&2
		exit 1
	fi
fi

if [ ! -f "$STATSCRIPT" ]; then
	echo Script \"$STATSCRIPT\" not found! >&2
	exit 1
fi

if [ ! -f "$XLS" ]; then
	echo Spreadsheet \"$XLS\" not found! >&2
	exit 1
fi

if [ ! -f "$REMOTES" ]; then
	echo Remote locations list in \"$REMOTES\" not found! >&2
	exit 1
fi


##########################################
# Step 06: Generate target days list

echo Compiling statistics between ${FROM} and ${TILL}.

for i in `seq 0 $NDAYS`; do
	LDAYS+=(`date -d "${TILL}-${i} days" +%Y-%m-%d`)
done

#for DATE in "${LDAYS[@]}"; do
#	echo $DATE
#done

##########################################
# Step 10: Download all logs

mkdir -p "$WRKD/logs.$$"
WRKLOGS="$WRKD/logs.$$"

while read remote; do
	remtok=(${remote//:/ })
	echo Downloading logs from ${remtok[0]} \(remote path ${remtok[1]}\)

	for DATE in "${LDAYS[@]}"; do
		scp $remote/dhus-${DATE}.log "${WRKLOGS}/dhus-${DATE}.log.${remtok[0]}"
		cat "${WRKLOGS}/dhus-${DATE}.log.${remtok[0]}" >> "${WRKLOGS}/dhus-${DATE}.log"
		rm "${WRKLOGS}/dhus-${DATE}.log.${remtok[0]}"
#		ssh ${remtok[0]} "cat ${remtok[1]}/dhus-${DATE}.log" >> "${WRKLOGS}/dhus-${DATE}.log"
	done

done < ${REMOTES}

##########################################
# Step 20: Combine logs



##########################################
# Step 30: Run Statistics

SAVEPWD=`pwd`
cp -v "${STATSCRIPT}" "${WRKLOGS}/"
cp -v "${XLS}" "${WRKLOGS}/${XLSTARGET}"
STATBASE=`basename "${STATSCRIPT}"`
XLSBASE=`basename "${XLSTARGET}"`
cd ${WRKLOGS}
echo Running ${STATSCRIPT} in ${WRKLOGS}
sed --in-place 's/^log_dir=.*$/log_dir=".\/"/' "./${STATBASE}"
${STATSCRIPT} "${FROM}" "${TILL}" "./"


##########################################
# Step 35: Convert to HTML :-(

echo Generating HTML
CSVS=("client_Bandwith_usage_report" "distributed_report" "retrieved_report")

for file in "${CSVS[@]}"
do
	printf "Making ${WRKLOGS}/${file}.html "
	echo "<table>" >> ${file}.html
	while read INPUT ; do
		echo "<tr><td>${INPUT//;/</td><td>}</td></tr>" >> ${file}.html
	done < ${file}_${FROM}_${TILL}.csv 
	echo "</table>" >> ${file}.html
	echo '[done]'
done

##########################################
# Step 40: Import into spreadsheet

MACROLOC="$HOME/.config/libreoffice/4/user/basic/Standard"
mkdir -p "$MACROLOC"

cat <<EOF > "$MACROLOC/CollGS.xba"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE script:module PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "module.dtd">
<script:module xmlns:script="http://openoffice.org/2000/script" script:name="Module1" script:language="StarBasic">REM  *****  BASIC  *****

Sub Main
Dim sheet As Object
Dim document As Object
Dim Dummy()

document = StarDesktop.loadComponentFromURL(&quot;file://${WRKLOGS}/${XLSBASE}&quot;, &quot;_blank&quot;, 0, Dummy)

sheet = thisComponent.getSheets.getByName(&quot;RetrieveStats&quot;)
sheet.link(&quot;file://${WRKLOGS}/retrieved_report.html&quot;, &quot;&quot;, &quot;&quot;, &quot;&quot;, com.sun.star.sheet.SheetLinkMode.NORMAL)

sheet = thisComponent.getSheets.getByName(&quot;DistributedStats&quot;)
sheet.link(&quot;file://${WRKLOGS}/distributed_report.html&quot;, &quot;&quot;, &quot;&quot;, &quot;&quot;, com.sun.star.sheet.SheetLinkMode.NORMAL)

sheet = thisComponent.getSheets.getByName(&quot;BandwidthStats&quot;)
sheet.link(&quot;file://${WRKLOGS}/client_Bandwith_usage_report.html&quot;, &quot;&quot;, &quot;&quot;, &quot;&quot;, com.sun.star.sheet.SheetLinkMode.NORMAL)

document.store()
document.close(True)

end sub

</script:module>
EOF

printf "Running LibreOffice to update the document at ${WRKLOGS}/${XLSBASE} "
libreoffice --invisible --nofirststartwizard --headless --norestore "macro:///Standard.CollGS.Main"
echo '[done]'

##########################################
# Step 45: Encrypt

mkdir "${YEAR}w${WEEK}_reports"

cp "${XLSBASE}" "${YEAR}w${WEEK}_reports/"
tar cvvf ./${YEAR}w${WEEK}_reports.tar ${YEAR}w${WEEK}_reports
gzip ${YEAR}w${WEEK}_reports.tar

##########################################
# Step 50: Upload to Jira

curl -D- --netrc -X POST -H "X-Atlassian-Token: nocheck" -F "file=@${WRKLOGS}/${YEAR}w${WEEK}_reports.tar.gz" https://copernicus.serco.eu/jira-osf/rest/api/2/issue/CRDR-7/attachments


##########################################
# Step 60: Cleanup

echo Removing temporary files from ${WRKLOGS}



