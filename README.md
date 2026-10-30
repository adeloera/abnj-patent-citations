# Replication: patent citations of marine species by jurisdiction

Code and data behind the statistics and Fig. 2 of "Don't tax discovery to fund the High Seas Treaty". METHODS.md describes the data and method.

Run from this folder:

    Rscript abnj_patent_citations.R

The script needs R with the packages dplyr, readr, sf, s2, httr, jsonlite, ggplot2, patchwork and scales, and mregions2 if the High Seas layer has to be fetched. It runs in about a minute.

`data/` holds the OBIS occurrence records as retrieved for the MABPAT marine species, from a pull on October 30, 2026 (this input cannot be re-created exactly, because OBIS grows), and the Marine Regions High Seas polygon, version 1, rebuilt for spherical geometry as described in METHODS.md. The MABPAT v3 table is fetched from figshare on first run (file 46240417, checked against its MD5). If the High Seas file is missing the script fetches the layer through the mregions2 package.

`output/` holds the species table, the statistics at several thresholds, the list of species recorded mostly in ABNJ, and the figure.
