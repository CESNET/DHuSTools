# DHuSTools
Small tools developed to accompany ESA DHuS instances.

## get\_totals.sh

Lists the number of products available at a remote DHuS instance for each day within a selected period. Type of temporal value (Sensing, Ingestion, Creation) may be selected. Alternatively the script may not list totals but full lists of products matching that period.

## make\_stats.sh

Intended to be run by `cron`. It does not produce the statistics itself but rather runs a supplied log scraping script (supplied to relay operators through Jira) and fills in an accompanying spreadsheet. Then it uploads the resulting statistics to Jira.

## gen\_l2\_list.sh

Generates a list of Sentinel2 L1C products in the target site that do not yet have a matching L2A product with atmospheric correction, produced with `Sen2cor`.

## gen\_new\_list.sh

Generates a list of all product IDs that have appeared on a specified DHuS endpoint since a given timestamp. Useful for all application where reaction to new products is required.

## format\_dhus\_log.sh

Reads log files written by DHuS and produces a chart showing download speeds from various identified sources over time.

## check-manifest.sh

Downloads a given product and compares the manifest to the actual contents of the ZIP file.

## report-syncers.sh

Iterate over multiple instances of DHuS, collect synchronizer settings, compile a comprehensive table of active synchronizers and upload it as a comment to a specified Jira ticket. This script is intended for regular execution by `cron`, only uploading when synchronizer configuration changes to keep Jira users notified of the most recent configuration used in a relay site.

## estimate-footprint.sh

Accept footprint, iterate over past months and see what capacity it would take to store data for that footprint. The script produces a CSV by months, suitable for further processing with spreadsheet pivot tables. This is to easily determine what capacity it takes to support a user group interested in a specific geographical area.

# Gist

The `gist` folder contains short snippets of code, that illustrate some frequently performed actions. They are intended as examples, often can be pasted into your console, but there is no attribute handling, checks, cleanup, et cetera.

# Contributing

Contributions are welcome. Fork this repository on GitHub and open a pull request with your contribution. You are also welcome to open Issues for discussion and/or suggestions.
