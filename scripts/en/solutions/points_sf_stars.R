# ============================================================
# WORKFLOW 1
# POINTS + sf / stars
# ============================================================

library(dplyr)
library(sf)
library(stars)
library(ggplot2)
library(units)
library(mapview)

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
focal_species <- "White-throated Sparrow"

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

mapview(ecodistricts) +
  mapview(sites, zcol = "spNameEN")


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

mapview(ecodistricts, zcol = "area")
mapview(sites, zcol = "coast_distance")


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

mapview(temperature[, , , 1])


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

mapview(sites, zcol = "tavg_january")


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
# 13) Easy GLM: counts by ecodistrict
# ------------------------------------------------------------

points_glm <- sites |>
  st_drop_geometry() |>
  filter(!is.na(Name)) |>
  group_by(Name, ecodistricts_area_km2) |>
  summarise(
    n_observations = n(),
    mean_tavg_august = mean(tavg_august, na.rm = TRUE),
    mean_coast_distance_km = mean(drop_units(coast_distance), na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(log_area_km2 = log(drop_units(ecodistricts_area_km2)))

points_glm <- glm(
  n_observations ~ mean_tavg_august + mean_coast_distance_km + offset(log_area_km2),
  data = points_glm,
  family = poisson()
)

print(summary(points_glm))


# ------------------------------------------------------------
# 14) Advanced analysis: GLM with pseudo-absences
# ------------------------------------------------------------

presence_points <- sites |>
  filter(spNameEN == focal_species) |>
  select(spNameEN, coast_distance, tavg_january, tavg_august) |>
  mutate(presence = 1)

pseudoabsence_points <- st_sample(qc, size = nrow(presence_points), exact = TRUE) |>
  st_sf(presence = 0, geometry = _)

pseudoabsence_points <- pseudoabsence_points |>
  st_transform(32198) |>
  mutate(
    coast_distance = st_distance(geometry, coast),
    coast_distance = set_units(coast_distance, "km")
  ) |>
  st_transform(4326)

pseudoabsence_points <- bind_cols(
  pseudoabsence_points,
  st_extract(temperature, pseudoabsence_points)[[1]] |>
    as.data.frame() |>
    dplyr::rename(tavg_january = V1, tavg_august = V2)
)

points_glm_data <- bind_rows(
  presence_points,
  pseudoabsence_points |>
    mutate(spNameEN = "Pseudo-absence") |>
    select(spNameEN, presence, coast_distance, tavg_january, tavg_august)
) |>
  mutate(coast_distance_km = drop_units(coast_distance))

points_glm <- glm(
  presence ~ tavg_january + tavg_august + coast_distance_km,
  data = points_glm_data,
  family = binomial()
)

print(summary(points_glm))


# ------------------------------------------------------------
# 15) Advanced analysis: KDE on observation points
# ------------------------------------------------------------

focal_points <- sites |>
  filter(spNameEN == focal_species) |>
  st_transform(32198)

focal_xy <- st_coordinates(focal_points)
qc_qc <- st_transform(qc, 32198)
qc_bbox <- st_bbox(qc_qc)

points_kde <- MASS::kde2d(
  focal_xy[, 1],
  focal_xy[, 2],
  n = 100,
  h = c(100000, 100000),
  lims = c(qc_bbox["xmin"], qc_bbox["xmax"], qc_bbox["ymin"], qc_bbox["ymax"])
)

points_kde <- st_as_stars(
  list(kde = points_kde$z),
  dimensions = st_dimensions(x = points_kde$x, y = points_kde$y)
) |>
  st_set_crs(32198)

points_kde <- points_kde[qc_qc]
points_kde_plot <- points_kde
points_kde_plot[[1]] <- points_kde_plot[[1]] / max(points_kde_plot[[1]], na.rm = TRUE)

# Breaks for plotting
kde_breaks <- seq(0, 1, by = 0.1)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)

plot(st_geometry(qc_qc), border = "grey20")
plot(points_kde_plot, breaks = kde_breaks, col = kde_cols, add = TRUE)
plot(st_geometry(focal_points), border = "#c60d0d", add = TRUE)
plot(qc_qc, border = "#383838", col = NA, add = TRUE)

# ------------------------------------------------------------
# 16) Final map
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
# 17) Export outputs
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
