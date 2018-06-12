#!/bin/bash

STATSCRIPT="./DataHubStats_TiB.sh"
XLS="./DHRNAME_report_referenceperiod_DataHubStats_v2.2.xlsx"
REMOTES="./.remotes"
NDAYS=6
TILL=`date -d "yesterday" +%Y-%m-%d`
WRKD="/tmp"

while getopts "hc:o:l:n:f:w:" opt; do
  case $opt in
        h)
                printf "Collect, run and export DHuS Relay statistics\n\nUsage:\n
\t-c <str>\tPath to the statistics script\n\t\t\t(Default \"${STATSCRIPT}\")\n \
\t-o <str>\tPath to the output spreadsheet\n\t\t\t(Default \"${XLS}\")\n \
\t-l <str>\tPath to a file containing remote paths\n\t\t\t(Default \"${REMOTES}\")\n \
\t-w <str>\tPath to the working directory (Default \"${WRKD}\")\n \
\t-n <num>\tStart reporting period <num> days\n\t\t\tbefore the final date (Default ${NDAYS})\n \
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
	n)
		NDAYS=$OPTARG
                ;;
	t)
		TILL=$OPTARG
                ;;
  esac
done

FROM=`date -d "yesterday-${NDAYS} days" +%Y-%m-%d`

echo Compiling statistics between ${FROM} and ${TILL}.

##########################################
# Step 10: Download all logs

while read remote; do
	remtok=(${remote//:/ })
	echo Downloading logs from ${remtok[0]} \(remote path ${remtok[1]}\)

done < ${REMOTES}

##########################################
# Step 20: Combine logs



##########################################
# Step 30: Run Statistics



##########################################
# Step 40: Import into spreadsheet



##########################################
# Step 50: Upload to Jira





