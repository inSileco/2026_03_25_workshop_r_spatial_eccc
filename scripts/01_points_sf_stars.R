# ============================================================
# WORKFLOW 1
# POINTS + sf / stars
# ============================================================

library(dplyr)
library(sf)
library(stars)
library(ggplot2)

# ------------------------------------------------------------
# 0) Paths and study choices
# ------------------------------------------------------------

data_dir <- "data"
output_dir <- "outputs"
target_crs <- 32198

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

sites <- read.csv(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "sites.csv"))
east <- st_read(file.path(data_dir, "Basemap", "east.gpkg"))
ecodistricts <- st_read(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "ecodistricts.gpkg"))
rco <- st_read(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "rco.gpkg"))


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

ecodistricts_qc <- st_transform(ecodistricts, target_crs)
rco_qc <- st_transform(rco, target_crs)
sites_qc <- st_transform(sites, target_crs)
coast_qc <- st_boundary(st_transform(qc, target_crs))

ecodistricts$ecodistricts_area_km2 <- as.numeric(st_area(ecodistricts_qc)) / 1e6
rco$rco_area_km2 <- as.numeric(st_area(rco_qc)) / 1e6

sites$coast_distance_km <- as.numeric(st_distance(sites_qc, coast_qc)) / 1000

mapview::mapview(ecodistricts, zcol = "ecodistricts_area_km2")
mapview::mapview(sites, zcol = "coast_distance_km")


# ------------------------------------------------------------
# 7) Join the points to polygons
# ------------------------------------------------------------

sites <- st_join(
  sites,
  ecodistricts |>
    select(ECODISTRIC, Name, ecodistricts_area_km2)
)

sites <- st_join(
  sites,
  rco |>
    select(name_en, name_fr, rco_area_km2)
)


# ------------------------------------------------------------
# 8) Import raster data
# ------------------------------------------------------------

temperature <- read_stars(
  file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "temperature_avg_worldclim.tif")
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

temperature_qc <- st_crop(temperature, st_bbox(qc))

plot(st_geometry(qc), border = "grey20")
plot(temperature_qc[, , , 1], add = TRUE)
plot(st_geometry(qc), border = "grey20", col = "#2c716844", add = TRUE)


# ------------------------------------------------------------
# 11) Extract raster values at points
# ------------------------------------------------------------

temperature_values <- st_extract(temperature_qc, sites)[[1]] |>
  as.data.frame()

names(temperature_values) <- c("tavg_january", "tavg_august")

sites <- bind_cols(sites, temperature_values)

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
    mean_coast_distance_km = mean(coast_distance_km, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_observations))

ecodistrict_summary <- sites |>
  st_drop_geometry() |>
  filter(!is.na(Name)) |>
  count(Name, ecodistricts_area_km2, name = "n_observations") |>
  mutate(observations_per_1000_km2 = 1000 * n_observations / ecodistricts_area_km2) |>
  arrange(desc(n_observations))

print(species_summary)
print(head(ecodistrict_summary, 10))


# ------------------------------------------------------------
# 13) Final map
# ------------------------------------------------------------

points_map <- ggplot() +
  geom_stars(data = temperature_qc[, , , 2], downsample = 8) +
  scale_fill_viridis_c(name = "August mean temperature") +
  geom_sf(data = qc, fill = NA, color = "grey30", linewidth = 0.4) +
  geom_sf(data = sites, aes(color = spNameEN), alpha = 0.7, size = 0.9) +
  labs(
    title = "Bird observations and summer temperature",
    subtitle = "sf + stars workflow built from a CSV of coordinates",
    color = "Species"
  ) +
  theme_minimal()

print(points_map)


# ------------------------------------------------------------
# 14) Export outputs
# ------------------------------------------------------------

st_write(
  sites,
  file.path(output_dir, "points_with_context.gpkg"),
  delete_dsn = TRUE,
  quiet = TRUE
)

write.csv(
  species_summary,
  file.path(output_dir, "points_species_summary.csv"),
  row.names = FALSE
)

write.csv(
  ecodistrict_summary,
  file.path(output_dir, "points_ecodistrict_summary.csv"),
  row.names = FALSE
)
