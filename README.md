# DHuSTools
Small tools developed to accompany ESA DHuS instances

## get\_totals.sh

Lists the number of products available at a remote DHuS instance for each day within a selected period. Type of temporal value (Sensing, Ingestion, Creation) may be selected. Alternatively the script may not list totals but full lists of products matching that period.

## make\_stats.sh

Intended to be run by `cron`. It does not produce the statistics itself but rather runs a supplied log scraping script (supplied to relay operators through Jira) and fills in an accompanying spreadsheet. Then it uploads the resulting statistics to Jira.

## gen\_l2\_list.sh

Generates a list of Sentinel2 L1C products in the target site that do not yet have a matching L2A product with atmospheric correction, produced with `Sen2cor`.

