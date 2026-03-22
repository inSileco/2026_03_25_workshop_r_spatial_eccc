# ============================================================
# WORKFLOW 1
# POINTS + sf / stars
# ============================================================

library(dplyr)
library(sf)
library(stars)
library(ggplot2)
library(units)

# ------------------------------------------------------------
# 0) Paths and study choices
# ------------------------------------------------------------

data_dir <- "data"
output_dir <- "outputs"

study_species <- c(
  "White-throated Sparrow",
  "Ruby-crowned Kinglet",
  "Swainson's Thrush",
  "Dark-eyed Junco"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------
# 1) Import tabular and vector data
# ------------------------------------------------------------

sites <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "sites.csv") |>
  read.csv()
east <- file.path(data_dir, "Basemap", "east.gpkg") |>
  st_read()
ecodistricts <- file.path(
  data_dir,
  "SuiviOiseauxBoreauxQuebec",
  "ecodistricts.gpkg"
) |>
  st_read()
rco <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "rco.gpkg") |>
  st_read()


# ------------------------------------------------------------
# 2) Create points from CSV coordinates
# ------------------------------------------------------------

sites <- sites |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)


# ------------------------------------------------------------
# 3) Harmonize vector projections
# ------------------------------------------------------------

sites <- st_transform(sites, 4326)
east <- st_transform(east, 4326)
ecodistricts <- st_transform(ecodistricts, 4326)
rco <- st_transform(rco, 4326)


# ------------------------------------------------------------
# 4) Keep the overlapping land and study polygons
# ------------------------------------------------------------

sites <- st_filter(sites, east)
ecodistricts <- st_filter(ecodistricts, east)
rco <- st_filter(rco, east)
qc <- east |>
  filter(NAME_1 == "Québec")


# ------------------------------------------------------------
# 5) Quick vector exploration
# ------------------------------------------------------------

plot(st_geometry(east), col = "grey95", border = "grey40")
plot(st_geometry(ecodistricts), border = "#35ad8f", add = TRUE)
plot(st_geometry(sites), pch = 16, cex = 0.5, col = "tomato", add = TRUE)

mapview::mapview(ecodistricts) +
  mapview::mapview(sites, zcol = "spNameEN")


# ------------------------------------------------------------
# 6) Measure polygon area and point-to-coast distance
# ------------------------------------------------------------

# Area of polygons
ecodistricts <- ecodistricts |>
  st_transform(32198) |>
  mutate(
    area = st_area(geom),
    area = set_units(area, "km^2")
  ) |>
  st_transform(4326)

rco <- rco |>
  st_transform(32198) |>
  mutate(
    area = st_area(geom),
    area = set_units(area, "km^2")
  ) |>
  st_transform(4326)

# Distance of points to coast
coast <- st_transform(qc, 32198) |>
  st_boundary()
sites <- sites |>
  st_transform(32198) |>
  mutate(
    coast_distance = st_distance(geometry, coast),
    coast_distance = set_units(coast_distance, "km")
  ) |>
  st_transform(4326)

mapview::mapview(ecodistricts, zcol = "area")
mapview::mapview(sites, zcol = "coast_distance")


# ------------------------------------------------------------
# 7) Join the points to polygons
# ------------------------------------------------------------

sites <- st_join(
  sites,
  ecodistricts |>
    select(ECODISTRIC, Name, ecodistricts_area_km2 = area)
)

sites <- st_join(
  sites,
  rco |>
    select(name_en, name_fr, rco_area_km2 = area)
)


# ------------------------------------------------------------
# 8) Import raster data
# ------------------------------------------------------------

temperature <- read_stars(
  file.path(
    data_dir,
    "SuiviOiseauxBoreauxQuebec",
    "temperature_avg_worldclim.tif"
  )
)


# ------------------------------------------------------------
# 9) Quick raster exploration
# ------------------------------------------------------------

plot(st_geometry(east), border = "#35ad8f")
plot(temperature[, , , 1], add = TRUE)
plot(st_geometry(east), border = "#35ad8f", add = TRUE)

mapview::mapview(temperature[, , , 1])


# ------------------------------------------------------------
# 10) Crop the raster to Quebec
# ------------------------------------------------------------

temperature <- st_crop(temperature, st_bbox(qc))

plot(st_geometry(qc), border = "grey20")
plot(temperature[, , , 1], add = TRUE)
plot(st_geometry(qc), border = "grey20", col = "#2c716844", add = TRUE)


# ------------------------------------------------------------
# 11) Extract raster values at points
# ------------------------------------------------------------

sites <- bind_cols(
  sites,
  st_extract(temperature, sites)[[1]] |>
    as.data.frame() |>
    dplyr::rename(tavg_january = V1, tavg_august = V2)
)

mapview::mapview(sites, zcol = "tavg_january")


# ------------------------------------------------------------
# 12) Summaries for analysis
# ------------------------------------------------------------

species_summary <- sites |>
  st_drop_geometry() |>
  group_by(spNameEN) |>
  summarise(
    n_observations = n(),
    mean_tavg_january = mean(tavg_january, na.rm = TRUE),
    mean_tavg_august = mean(tavg_august, na.rm = TRUE),
    mean_coast_distance_km = mean(coast_distance, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_observations))

ecodistrict_summary <- sites |>
  st_drop_geometry() |>
  filter(!is.na(Name)) |>
  count(Name, ecodistricts_area_km2, name = "n_observations") |>
  mutate(
    observations_per_km2 = n_observations / ecodistricts_area_km2
  ) |>
  arrange(desc(n_observations))

rco_summary <- sites |>
  st_drop_geometry() |>
  filter(!is.na(name_en)) |>
  count(name_en, rco_area_km2, name = "n_observations") |>
  mutate(
    observations_per_km2 = n_observations / rco_area_km2
  ) |>
  arrange(desc(n_observations))

print(species_summary)
print(head(ecodistrict_summary, 10))
print(head(rco_summary, 10))


# ------------------------------------------------------------
# 13) Final map
# ------------------------------------------------------------

points_map <- ggplot() +
  geom_stars(data = temperature[, , , 2], downsample = 8) +
  scale_fill_viridis_c(name = "August mean temperature") +
  geom_sf(data = qc, fill = NA, color = "grey30", linewidth = 0.4) +
  geom_sf(data = sites, aes(color = spNameEN), alpha = 0.7, size = 0.9) +
  labs(
    title = "Bird observations and summer temperature",
    subtitle = "sf + stars workflow built from a CSV of coordinates",
    color = "Species"
  ) +
  theme_minimal()

points_map


# ------------------------------------------------------------
# 14) Export outputs
# ------------------------------------------------------------

st_write(
  sites,
  file.path(output_dir, "sites.gpkg"),
  delete_dsn = TRUE,
  quiet = TRUE
)

write.csv(
  species_summary,
  file.path(output_dir, "sites_species_summary.csv"),
  row.names = FALSE
)

write.csv(
  ecodistrict_summary,
  file.path(output_dir, "sites_ecodistrict_summary.csv"),
  row.names = FALSE
)

write.csv(
  rco_summary,
  file.path(output_dir, "sites_rco_summary.csv"),
  row.names = FALSE
)
