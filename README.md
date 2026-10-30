# Replication: patent citations of marine species by jurisdiction

Code and data behind the statistics and Fig. 2 of "Don't tax discovery to fund the High Seas Treaty". METHODS.md describes the data and method.

Run from this folder:

    Rscript abnj_patent_citations.R

The script needs R with the packages dplyr, readr, sf, s2, httr, jsonlite, ggplot2, patchwork, scales and rnaturalearth (with rnaturalearthdata), and mregions2 if the EEZ layer has to be fetched. It takes a few minutes, most of it in the point-in-polygon tests.

`data/` holds the OBIS occurrence records as retrieved for the MABPAT marine species. This is the one input that cannot be re-created exactly, because OBIS grows. The other two inputs are fetched on first run: the MABPAT v3 table from figshare (file 46240417, checked against its MD5) and the Marine Regions Exclusive Economic Zones layer through the mregions2 package. The results in the paper use EEZ version 12.

`output/` holds the species table, the statistics at several thresholds, the list of species recorded mostly in ABNJ, and the figure.
