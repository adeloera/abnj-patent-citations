# Replication: patent citations of marine species by jurisdiction

Code and data behind the statistics and Fig. 2 of "Don't tax discovery to fund the High Seas Treaty". METHODS.md describes the data and method.

Run from this folder:

    Rscript abnj_patent_citations.R

The script needs R with the packages dplyr, readr, sf, s2, httr, jsonlite, ggplot2, patchwork and scales, and mregions2 if the High Seas layer has to be fetched. It runs in about a minute.

`data/` holds the OBIS occurrence records as retrieved for the MABPAT marine species. This input cannot be re-created exactly, because OBIS grows. The results in the paper are based on a pull on October 30, 2026. The other two inputs are fetched on first run: the MABPAT v3 table from figshare (file 46240417, checked against its MD5) and the Marine Regions High Seas polygon through the mregions2 package. The results in the paper use version 1 of that layer.

`output/` holds the species table, the statistics at several thresholds, the list of species recorded mostly in ABNJ, and the figure.
