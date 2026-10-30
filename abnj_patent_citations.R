# Patent citations of marine species, by where the species occur
#
# The MABPAT database (Zhivkoplias et al. 2024) lists the marine species whose
# sequences appear in bioprospecting patents. This script matches those to
# their spatial occurrence. For each species, it retrieves occurrence records from OBIS,
# classifies every record as inside or outside national jurisdiction, and
# computes the share of the species' records that fall in areas beyond
# national jurisdiction (ABNJ). Patent citations are then tabulated by that
# share. The outputs include the statistics quoted in the text and Fig. 2 of
# "Don't tax discovery to fund the High Seas Treaty".
#
# Inputs
#   data/obis_occurrences.csv   OBIS records as retrieved; shipped with the code,
#                               because a later retrieval would differ
#   data/MABPAT_dataset.csv     MABPAT v3 flat table; fetched from figshare on
#                               first run (file 46240417)
#   data/eez.gpkg               Marine Regions EEZ layer, version 12; fetched
#                               through the mregions2 package on first run
#   Natural Earth 1:50m countries, through the rnaturalearth package
#
# Outputs, in output/
#   species_provenance.csv      one row per species: citations, records, ABNJ share
#   statistics.csv              citations and their timing, split at five thresholds
#   species_mostly_abnj.csv     the species counted as recorded mostly in ABNJ
#   fig2_abnj_patents.png       Fig. 2

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(sf); library(httr); library(jsonlite)
  library(ggplot2); library(patchwork)
})
sf_use_s2(TRUE)
dir.create("data", showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

years     <- 2003:2020   # application years covered
cap       <- 300         # OBIS records requested per species
threshold <- 0.5         # ABNJ share at or above which a species is "recorded mostly in ABNJ"
colours   <- c(abnj = "#2a6f97", other = "grey60")


# 1. Patent citations ------------------------------------------------------------
#
# Each row of the MABPAT table is one sequence accession in one patent
# application, together with the species the sequence was matched to and a flag
# for whether MABPAT treats that sequence as coming from a marine species. The
# flag is applied row by row: a species can carry it on some accessions and not
# others.
#
# A citation is one application citing at least one marine-flagged sequence
# from one species. It is counted once per species and application, however
# many sequences the application discloses, and dated by the application year.

mabpat_file <- "data/MABPAT_dataset.csv"
if (!file.exists(mabpat_file)) {
  download.file("https://ndownloader.figshare.com/files/46240417", mabpat_file, mode = "wb")
  stopifnot(tools::md5sum(mabpat_file) == "d125b6fde64a39781c86e315b7f60267")
}
mabpat <- read_csv(mabpat_file, col_types = cols_only(
  Patent_application_number = col_character(),
  Year_of_application       = col_integer(),
  Species_name              = col_character(),
  Is_marine_species         = col_integer()))

marine <- mabpat |>
  filter(Is_marine_species == 1, !is.na(Species_name), Species_name != "")
marine_species <- unique(marine$Species_name)

citations <- marine |>
  filter(Year_of_application %in% years) |>
  distinct(species = Species_name,
           patent  = Patent_application_number,
           year    = Year_of_application)


# 2. Occurrence records ------------------------------------------------------------
#
# OBIS is queried by the species name exactly as MABPAT gives it. It returns the
# first `cap` georeferenced records it holds, in its own order; this is not a
# random sample of the species' range. Species that OBIS does not know, or holds
# no coordinates for, have no rows here and drop out of the analysis.

fetch_obis <- function(species) {
  url <- paste0("https://api.obis.org/v3/occurrence?scientificname=",
                URLencode(species, reserved = TRUE),
                "&size=", cap, "&fields=decimalLongitude,decimalLatitude")
  response <- GET(url, timeout(60))
  if (status_code(response) != 200) return(NULL)
  results <- fromJSON(content(response, as = "text", encoding = "UTF-8"))$results
  if (!is.data.frame(results) || nrow(results) == 0) return(NULL)
  tibble(species = species,
         lon     = as.numeric(results$decimalLongitude),
         lat     = as.numeric(results$decimalLatitude))
}

obis_file <- "data/obis_occurrences.csv"
if (!file.exists(obis_file)) {
  records <- bind_rows(lapply(marine_species, function(s) { Sys.sleep(0.1); fetch_obis(s) }))
  write_csv(records, obis_file)
}
records <- read_csv(obis_file, col_types = cols(species = col_character(),
                                                lon = col_double(),
                                                lat = col_double())) |>
  filter(is.finite(lon), is.finite(lat))


# 3. Jurisdiction of each record --------------------------------------------------
#
# A record lies in ABNJ when it falls inside no exclusive economic zone and not
# on land. Both tests run on the sphere; planar tests misplace points near the
# antimeridian. The land test eliminates records for
# mangroves, estuarine fish and crustaceans, and some freshwater species.

# As distributed, three EEZ polygons have edges that cross on the sphere, which
# the spherical intersection test rejects, so the layer is repaired once when
# it is fetched and stored repaired.
eez_file <- "data/eez.gpkg"
if (!file.exists(eez_file)) {
  if (!requireNamespace("mregions2", quietly = TRUE)) install.packages("mregions2", repos = "https://cloud.r-project.org")
  mregions2::mrp_get("eez") |> st_make_valid() |> st_write(eez_file, quiet = TRUE)
}
eez  <- st_read(eez_file, quiet = TRUE)
land <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf") |>
  st_union() |>
  st_make_valid()

points <- st_as_sf(records, coords = c("lon", "lat"), crs = 4326)
records$in_eez  <- lengths(st_intersects(points, eez))  > 0
records$in_land <- lengths(st_intersects(points, land)) > 0

provenance <- records |>
  group_by(species) |>
  summarise(records    = n(),
            share_abnj = mean(!in_eez & !in_land),
            .groups    = "drop")


# 4. Species table and statistics ------------------------------------------------
#
# The population is every marine species with at least one citation in the
# study years and at least one georeferenced OBIS record. `species` has one row
# per species; `cited` has one row per citation, carrying the species' ABNJ
# share so that citations can be split and timed.

species <- citations |>
  count(species, name = "citations") |>
  inner_join(provenance, by = "species") |>
  mutate(mostly_abnj = share_abnj >= threshold) |>
  arrange(desc(share_abnj))
write_csv(species, "output/species_provenance.csv")

cited <- citations |>
  inner_join(select(species, species, share_abnj), by = "species")

# Citations and their timing for the species at or above a given ABNJ share,
# against all other species. The text uses the split at one half; the other
# thresholds show how the result moves with the cut.
compare_at <- function(thr) {
  cited |>
    mutate(group = if_else(share_abnj >= thr, "abnj", "other")) |>
    group_by(group) |>
    summarise(species          = n_distinct(species),
              citations        = n(),
              median_year      = median(year),
              share_after_2015 = mean(year > 2015),
              .groups          = "drop") |>
    mutate(threshold = thr, share_of_citations = citations / sum(citations), .before = 1)
}
statistics <- bind_rows(lapply(c(0.9, 0.6, 0.5, 0.4, 0.2), compare_at))
write_csv(statistics, "output/statistics.csv")

last_cited <- cited |>
  group_by(species) |>
  summarise(last_citation = max(year), .groups = "drop")
species |>
  filter(mostly_abnj) |>
  left_join(last_cited, by = "species") |>
  arrange(desc(citations)) |>
  write_csv("output/species_mostly_abnj.csv")

cat(sprintf("%d species, %d citations, %d-%d\n", nrow(species), nrow(cited), min(years), max(years)))
print(as.data.frame(statistics), digits = 3)


# 5. Figure -------------------------------------------------------------------------

theme_set(theme_minimal(base_size = 10, base_family = "Helvetica") +
  theme(panel.grid.minor    = element_blank(),
        panel.grid.major.x  = element_blank(),
        plot.background     = element_rect(fill = "white", colour = NA),
        plot.title          = element_text(size = 9.5, face = "bold"),
        plot.title.position = "plot"))

# Panel A sums patent citations over species in bins of ten percentage points
# of ABNJ share and labels each bin with its number of species. Shares are
# rounded before binning so that a share of exactly 0.3 falls in the 30 bin
# rather than on a floating-point edge.
bins <- species |>
  mutate(decile = pmin(floor(round(share_abnj, 9) * 10), 9)) |>
  group_by(decile) |>
  summarise(species = n(), citations = sum(citations), .groups = "drop") |>
  right_join(tibble(decile = 0:9), by = "decile") |>
  mutate(across(c(species, citations), \(x) coalesce(x, 0L)),
         bin   = factor(decile, levels = 0:9, labels = c(seq(0, 80, 10), "90+")),
         group = if_else(decile >= threshold * 10, "abnj", "other"))

panel_a <- ggplot(bins, aes(bin, citations, fill = group)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = species), vjust = -0.4, size = 2.5, colour = "grey20") +
  scale_fill_manual(values = colours, guide = "none") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.18))) +
  labs(x     = "Share of occurrence records in ABNJ (%)",
       y     = "Patent citations (labels: species)",
       title = "A. Patent citations by species location") +
  theme(axis.text.x = element_text(size = 8))

# Panel B traces the cumulative share of citations by year for the species
# recorded mostly in ABNJ against all others.
totals <- species |>
  group_by(group = if_else(mostly_abnj, "abnj", "other")) |>
  summarise(species = n(), citations = sum(citations), .groups = "drop")
labels <- c(
  abnj  = with(filter(totals, group == "abnj"),
               sprintf("%d species recorded mostly in ABNJ (%d citations)", species, citations)),
  other = with(filter(totals, group == "other"),
               sprintf("%d other species (%s citations)", species, format(citations, big.mark = ","))))

timing <- cited |>
  mutate(group = if_else(share_abnj >= threshold, "abnj", "other")) |>
  count(group, year) |>
  group_by(group) |>
  arrange(year) |>
  mutate(cumulative_share = cumsum(n) / sum(n)) |>
  ungroup()

panel_b <- ggplot(timing, aes(year, cumulative_share, colour = group)) +
  geom_step(linewidth = 1) +
  geom_hline(yintercept = 0.5, linetype = "dotted", colour = "grey50") +
  scale_colour_manual(values = colours, labels = labels, name = NULL) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = seq(2004, 2020, 4)) +
  labs(x = NULL, y = "Cumulative share of citations",
       title = "B. Patent citation timing") +
  theme(legend.position    = "bottom",
        legend.direction   = "vertical",
        legend.text        = element_text(size = 8),
        legend.key.width   = unit(0.8, "cm"),
        legend.margin      = margin(t = -6),
        panel.grid.major.x = element_line(),
        plot.margin        = margin(4, 4, 4, 12))

figure <- (panel_a + panel_b + plot_layout(widths = c(1.15, 1))) &
  plot_annotation(theme = theme(plot.margin = margin(4, 6, 4, 4)))
ggsave("output/fig2_abnj_patents.png", figure, width = 7.2, height = 3.5, dpi = 300)
