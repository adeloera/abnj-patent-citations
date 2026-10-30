
This document describes the data and method behind the statement in the text of "Don't tax discovery to fund the High Seas Treaty" that species recorded mostly in areas beyond national jurisdiction (ABNJ) account for 200 of 6,054 patent citations in 2003 to 2020, and behind Fig. 2. It also lists the sources for Fig. 1. The code and the data as used are deposited at [repository].

# Patent citations

Patent data come from MABPAT version 3 (*1*), a database of patent applications that disclose nucleotide sequences matched to marine species. I use the flat table distributed on figshare (file 46240417). Each row is one sequence accession in one patent application, with the species the sequence was matched to and a flag for whether MABPAT treats that sequence as coming from a marine species. I keep rows with the marine flag set, which gives 4,779 applications citing 1,639 marine species, filed between 1982 and 2022.

A patent citation is one application citing at least one marine-flagged sequence from one species. It is counted once per species and application, whatever the number of sequences, and dated by the year of application. The analysis covers applications filed from 2003 to 2020, which excludes the thin early years and the most recent years, where publication lags leave the database incomplete. In that window 1,578 species are cited at least once.

# Occurrence records

For each MABPAT marine species I retrieve georeferenced occurrence records from the Ocean Biodiversity Information System (OBIS) through its public API (version 3), querying the species name exactly as MABPAT gives it and requesting up to 300 records with coordinates. OBIS returns the first 300 records it holds in its own order, not a random sample. The records were retrieved in June 2026 and are archived with the code, since a later retrieval would return a different set as OBIS grows. OBIS holds records for 813 of the 1,639 marine species; the remainder, mostly microorganisms known from culture collections, drop out of the analysis. Combined with the citation window this leaves 774 species, which is the population in Fig. 2.

# Jurisdiction of each record

A record counts as lying in ABNJ when it falls inside no polygon of the Marine Regions Exclusive Economic Zones layer, version 12 (*2*), and not on land. The EEZ layer includes joint regimes and overlapping claims, all of which I treat as national jurisdiction. Land is the union of the Natural Earth 1:50m country polygons. Both point-in-polygon tests run on the sphere, using the s2 library through the sf package in R, because planar tests misplace points near the antimeridian.

The land test rules out records for mangroves, estuarine fish and crustaceans, and some freshwater species, whose coordinates often fall on land, outside every EEZ polygon, and would otherwise be counted as ABNJ. Marine Regions has no EEZ polygons south of 60 degrees south, so Southern Ocean records count as ABNJ, consistent with the Agreement's scope.

A species' ABNJ share is the fraction of its records that pass both tests. The main text calls a species "recorded mostly in ABNJ" when that share is at least one half. MABPAT itself carries a presence flag for ABNJ; 263 of the 774 species, holding 2,347 of the citations, are flagged present in ABNJ, because presence somewhere beyond national jurisdiction is common among widely distributed marine microorganisms. The share-based measure separates species whose records are concentrated beyond national jurisdiction from those that merely reach it.

# Statistics by threshold

The table gives the result at five thresholds. The text uses the row for one half. The share of citations beyond national jurisdiction rises as the threshold loosens but stays small, and at no threshold are those citations more recent than the rest.

| Species with ABNJ share | Species | Citations (share of 6,054) | Median year, these species | Median year, others | After 2015, these species | After 2015, others |
|---|---|---|---|---|---|---|
| at least 90% | 10 | 13 (0.2%) | 2009 | 2011 | 0% | 23% |
| at least 60% | 26 | 62 (1.0%) | 2011 | 2011 | 13% | 23% |
| at least 50% | 48 | 200 (3.3%) | 2010 | 2011 | 14% | 23% |
| at least 40% | 70 | 320 (5.3%) | 2010 | 2011 | 15% | 23% |
| at least 20% | 194 | 1024 (16.9%) | 2011 | 2011 | 20% | 23% |

At the threshold of one half there are 48 species with 200 citations; the other 726 species have 5,854. The median citation year is 2010 against 2011, and 14% of the ABNJ citations fall after 2015 against 23% for the other species. The 10 species with at least 90% of their records in ABNJ are hydrothermal-vent fauna, Antarctic krill, and deep-sea microorganisms with one or two records each: *Moritella abyssi*, *Alvinella pompejana*, *Bizionia algoritergicola*, *Maribacter stanieri*, *Prosthecochloris vibrioformis*, *Alvinella caudata*, *Euphausia superba*, *Bythograea thermydron*, *Metridia asymmetrica*, *Ventiella sulfuris*.

# Limitations

Three features of the data bear on the interpretation. First, OBIS sampling is much sparser in ABNJ than in coastal waters, so the ABNJ share of a species that occurs in both is biased downward; the classification is conservative in the direction of national jurisdiction, and the threshold table shows how far the conclusion depends on the cut. Second, the share measures where a species is recorded, not where the sample behind any particular patent was collected, which MABPAT does not record. Third, 13 of the 48 species recorded mostly in ABNJ have fewer than ten records, so their shares rest on few observations; the species in that group are listed, with their citation counts, in the deposited output.

# Sources for Fig. 1

The five largest-selling marine-derived drugs and their most recent reported annual sales, in millions of US dollars, are Adcetris (brentuximab vedotin, whose payload is a synthetic analogue of dolastatin from the sea hare *Dolabella auricularia*; 1,911 in 2024, Pfizer 1,089 and Takeda 822), Zepzelca (lurbinectedin, from the tunicate *Ecteinascidia turbinata*; 320 in 2024, Jazz Pharmaceuticals), Halaven (eribulin, from the sponge *Halichondria okadai*; 285 in 2023, Eisai), Yondelis (trabectedin, from *E. turbinata*; 130 in 2024, PharmaMar), and Prialt (ziconotide, from the cone snail *Conus magus*; about 25 in 2017). All five source organisms are shallow-water or coastal. The figures for 74 products with combined revenue of 400 to 650 million dollars a year, and the resulting yield of a 1% royalty, are from the European Commission study (*3*).

# References

1. E. Zhivkoplias, J.-B. Jouffray, P. Dunshirn, A. Pranindita, R. Blasiak, Growing prominence of deep-sea life in marine bioprospecting. *Nat. Sustain.* **7**, 1027–1037 (2024). Data: MABPAT v3, figshare, doi:10.6084/m9.figshare.24893070.
2. Flanders Marine Institute, Maritime Boundaries Geodatabase: Maritime Boundaries and Exclusive Economic Zones (200NM), version 12 (2023); https://www.marineregions.org/.
3. P. Oldham, J. Kindness, E. Davidson, A. Westmoreland, T. Vanagt, M. Jaspars, Study on Marine Genetic Resources' Market Value and State of the Art of Commercialisation of Related Products in the Context of the BBNJ Negotiations: Final Report (Publications Office of the European Union, Luxembourg, 2025).
