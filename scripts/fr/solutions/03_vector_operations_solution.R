# Exercice 03 - Corrigé Opérations vectorielles

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

sites <- st_filter(sites, east)
ecodistricts <- st_filter(ecodistricts, east)
rco <- st_filter(rco, east)
qc <- east |>
  filter(NAME_1 == "Québec")

ecodistricts <- ecodistricts |>
  st_transform(32198) |>
  mutate(area = set_units(st_area(geom), "km^2")) |>
  st_transform(4326)

rco <- rco |>
  st_transform(32198) |>
  mutate(area = set_units(st_area(geom), "km^2")) |>
  st_transform(4326)

coast <- st_transform(qc, 32198) |>
  st_boundary()

sites <- sites |>
  st_transform(32198) |>
  mutate(coast_distance = set_units(st_distance(geometry, coast), "km")) |>
  st_transform(4326)

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

site_buffers <- st_buffer(st_transform(sites, 32198), dist = 10000)
buffer_ecodistricts <- st_intersection(site_buffers, st_transform(ecodistricts, 32198))


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

sites <- crop(sites, east)
qc <- east[east$NAME_1 == "Québec", ]

target_crs <- "EPSG:32198"
ecodistricts_qc <- project(ecodistricts, target_crs)
rco_qc <- project(rco, target_crs)
qc_qc <- project(qc, target_crs)
sites_qc <- project(sites, target_crs)
coast_qc <- as.lines(qc_qc)

ecodistricts$ecodistricts_area_km2 <- expanse(ecodistricts_qc, unit = "km")
rco$rco_area_km2 <- expanse(rco_qc, unit = "km")
sites$coast_distance_km <- distance(sites_qc, coast_qc)[, 1] / 1000

ecodistrict_values <- extract(ecodistricts, sites)
sites$ECODISTRIC <- ecodistrict_values$ECODISTRIC
sites$Name <- ecodistrict_values$Name
sites$ecodistricts_area_km2 <- ecodistrict_values$ecodistricts_area_km2

rco_values <- extract(rco, sites)
sites$name_en <- rco_values$name_en
sites$name_fr <- rco_values$name_fr
sites$rco_area_km2 <- rco_values$rco_area_km2

site_buffers <- buffer(project(sites, target_crs), width = 10000)
buffer_ecodistricts <- intersect(site_buffers, ecodistricts_qc)


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

target_crs <- 32198
gps_points <- st_transform(gps_points, target_crs)
tracks <- st_transform(tracks, target_crs)
east <- st_transform(east, target_crs)
habitats <- st_transform(habitats, target_crs)

habitats <- st_crop(habitats, st_bbox(tracks))
qc <- east |>
  filter(NAME_1 == "Québec")
coast <- st_boundary(qc)

tracks <- tracks |>
  mutate(length_km = set_units(st_length(geometry), "km"))

gps_points <- gps_points |>
  mutate(coast_distance = set_units(st_distance(geometry, coast), "km"))

coast_summary <- gps_points |>
  st_drop_geometry() |>
  group_by(Logger.ID) |>
  summarise(mean_coast_distance_km = mean(coast_distance), .groups = "drop")

tracks <- left_join(tracks, coast_summary, by = "Logger.ID")
track_segments <- st_intersection(tracks, habitats) |>
  mutate(segment_km = set_units(st_length(geometry), "km"))

track_buffers <- st_buffer(tracks, dist = 1000)


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

target_crs <- "EPSG:32198"
gps_points <- project(gps_points, target_crs)
tracks <- project(tracks, target_crs)
east <- project(east, target_crs)
habitats <- project(habitats, target_crs)

habitats <- crop(habitats, ext(tracks))
qc <- east[east$NAME_1 == "Québec", ]
coast <- as.lines(qc)

tracks$length_km <- perim(tracks) / 1000
gps_points$coast_distance_km <- distance(gps_points, coast)[, 1] / 1000

coast_summary <- as.data.frame(gps_points) |>
  group_by(Logger.ID) |>
  summarise(mean_coast_distance_km = mean(coast_distance_km), .groups = "drop")

tracks <- merge(tracks, coast_summary, by = "Logger.ID")
track_segments <- intersect(tracks, habitats)
track_segments$segment_km <- perim(track_segments) / 1000

track_buffers <- buffer(tracks, width = 1000)
