# Exercice 06 - Corrigé Flux de travail intégrés

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(stars)
library(sf)
library(units)

sites <- bind_cols(
  sites,
  st_extract(temperature_qc, sites)[[1]] |>
    as.data.frame() |>
    dplyr::rename(tavg_january = V1, tavg_august = V2)
)

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
  mutate(observations_per_km2 = n_observations / ecodistricts_area_km2) |>
  arrange(desc(n_observations))

rco_summary <- sites |>
  st_drop_geometry() |>
  filter(!is.na(name_en)) |>
  count(name_en, rco_area_km2, name = "n_observations") |>
  mutate(observations_per_km2 = n_observations / rco_area_km2) |>
  arrange(desc(n_observations))


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

temperature_values <- extract(temperature_qc, sites)
sites$tavg_january <- temperature_values$tavg_january
sites$tavg_august <- temperature_values$tavg_august

sites_table <- as.data.frame(sites)

species_summary <- sites_table |>
  group_by(spNameEN) |>
  summarise(
    n_observations = n(),
    mean_tavg_january = mean(tavg_january, na.rm = TRUE),
    mean_tavg_august = mean(tavg_august, na.rm = TRUE),
    mean_coast_distance_km = mean(coast_distance_km, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(n_observations))

ecodistrict_summary <- sites_table |>
  filter(!is.na(Name)) |>
  count(Name, ecodistricts_area_km2, name = "n_observations") |>
  mutate(observations_per_km2 = n_observations / ecodistricts_area_km2) |>
  arrange(desc(n_observations))

rco_summary <- sites_table |>
  filter(!is.na(name_en)) |>
  count(name_en, rco_area_km2, name = "n_observations") |>
  mutate(observations_per_km2 = n_observations / rco_area_km2) |>
  arrange(desc(n_observations))


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(stars)
library(sf)

bathymetry_mean <- st_extract(bathymetry, tracks, FUN = mean)
bathymetry_min <- st_extract(bathymetry, tracks, FUN = min)
segment_bathymetry <- st_extract(bathymetry, track_segments, FUN = mean)

tracks <- tracks |>
  mutate(
    mean_bathymetry = bathymetry_mean[[1]],
    min_bathymetry = bathymetry_min[[1]]
  )

track_segments <- track_segments |>
  mutate(segment_bathymetry = segment_bathymetry[[1]])

habitat_summary <- track_segments |>
  st_drop_geometry() |>
  group_by(Logger.ID) |>
  summarise(
    crossed_habitats = n(),
    total_km_in_habitats = sum(segment_km),
    mean_stemmean = weighted.mean(STEMMEAN, drop_units(segment_km)),
    mean_tidemax = weighted.mean(TIDEMAX, drop_units(segment_km)),
    mean_windmean = weighted.mean(WINDMEAN, drop_units(segment_km)),
    .groups = "drop"
  )

track_summary <- tracks |>
  st_drop_geometry() |>
  select(track_id, Logger.ID, length_km, mean_coast_distance_km, mean_bathymetry, min_bathymetry) |>
  left_join(habitat_summary, by = "Logger.ID") |>
  arrange(desc(length_km))


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

bathymetry_mean <- extract(bathymetry, track_buffers, fun = mean, na.rm = TRUE)
bathymetry_min <- extract(bathymetry, track_buffers, fun = min, na.rm = TRUE)
segment_bathymetry <- extract(bathymetry, track_segments, fun = mean, na.rm = TRUE) |>
  rename(segment_bathymetry = bathymetrie)

track_segments$segment_bathymetry <- segment_bathymetry$segment_bathymetry

habitat_summary <- as.data.frame(track_segments) |>
  group_by(Logger.ID) |>
  summarise(
    crossed_habitats = n(),
    total_km_in_habitats = sum(segment_km),
    mean_stemmean = weighted.mean(STEMMEAN, segment_km),
    mean_tidemax = weighted.mean(TIDEMAX, segment_km),
    mean_windmean = weighted.mean(WINDMEAN, segment_km),
    .groups = "drop"
  )

track_summary <- as.data.frame(tracks) |>
  select(track_id, Logger.ID, length_km, mean_coast_distance_km) |>
  left_join(
    bathymetry_mean |>
      rename(track_id = ID, mean_bathymetry = bathymetrie),
    by = "track_id"
  ) |>
  left_join(
    bathymetry_min |>
      rename(track_id = ID, min_bathymetry = bathymetrie),
    by = "track_id"
  ) |>
  left_join(habitat_summary, by = "Logger.ID") |>
  arrange(desc(length_km))
