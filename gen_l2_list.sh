#!/bin/bash

NETRCOPT="-n"

while getopts "hn:" opt; do
  case $opt in
        h)
                printf "Generate a list of L1 products (Sentinel2) that do not have a matching L2A product.\n\nUsage:\n
\t-h      \tDisplay this help\n \
\t-n <str>\tpath to an altarnative .netrc file (default ~/.netrc)\n \
\n\n"
                exit 0
                ;;
        n)
		NETRCOPT="--netrc-file ${OPTARG}"
                ;;
  esac
done

shift $(($OPTIND - 1))
URL=$1


