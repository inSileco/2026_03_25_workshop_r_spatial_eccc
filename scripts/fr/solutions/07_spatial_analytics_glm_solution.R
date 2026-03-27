# Exercice 07 - Corrigé Analyse spatiale avec GLM

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

points_glm_data <- sites |>
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
  data = points_glm_data,
  family = poisson()
)

summary(points_glm)

# Extension avancée optionnelle : GLM de pseudo-absences.
presence_points <- sites |>
  filter(spNameEN == "White-throated Sparrow") |>
  select(spNameEN, coast_distance, tavg_january, tavg_august) |>
  mutate(presence = 1)

pseudoabsence_points <- st_sample(qc, size = nrow(presence_points), exact = TRUE) |>
  st_sf(presence = 0, geometry = _)

pseudoabsence_points <- pseudoabsence_points |>
  st_transform(32198) |>
  mutate(coast_distance = set_units(st_distance(geometry, coast), "km")) |>
  st_transform(4326)

pseudoabsence_points <- bind_cols(
  pseudoabsence_points,
  st_extract(temperature_qc, pseudoabsence_points)[[1]] |>
    as.data.frame() |>
    dplyr::rename(tavg_january = V1, tavg_august = V2)
)

points_pa_data <- bind_rows(
  presence_points,
  pseudoabsence_points |>
    mutate(spNameEN = "Pseudo-absence") |>
    select(spNameEN, presence, coast_distance, tavg_january, tavg_august)
) |>
  mutate(coast_distance_km = drop_units(coast_distance))

points_glm_pa <- glm(
  presence ~ tavg_january + tavg_august + coast_distance_km,
  data = points_pa_data,
  family = binomial()
)


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(dplyr)

points_glm_data <- sites_table |>
  filter(!is.na(Name)) |>
  group_by(Name, ecodistricts_area_km2) |>
  summarise(
    n_observations = n(),
    mean_tavg_august = mean(tavg_august, na.rm = TRUE),
    mean_coast_distance_km = mean(coast_distance_km, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(log_area_km2 = log(ecodistricts_area_km2))

points_glm <- glm(
  n_observations ~ mean_tavg_august + mean_coast_distance_km + offset(log_area_km2),
  data = points_glm_data,
  family = poisson()
)

summary(points_glm)

# Extension avancée optionnelle : GLM de pseudo-absences.
presence_points <- sites[sites$spNameEN == "White-throated Sparrow", ]
presence_glm <- as.data.frame(presence_points)[, c(
  "spNameEN", "coast_distance_km", "tavg_january", "tavg_august"
)]
presence_glm$presence <- 1

pseudoabsence_points <- spatSample(qc, nrow(presence_points), method = "random")
pseudoabsence_points <- project(pseudoabsence_points, target_crs)
pseudoabsence_points$coast_distance_km <- distance(pseudoabsence_points, coast_qc)[, 1] / 1000
pseudoabsence_points <- project(pseudoabsence_points, "EPSG:4326")

pseudoabsence_values <- extract(temperature_qc, pseudoabsence_points)
pseudoabsence_glm <- as.data.frame(pseudoabsence_points)[, "coast_distance_km", drop = FALSE]
pseudoabsence_glm$tavg_january <- pseudoabsence_values$tavg_january
pseudoabsence_glm$tavg_august <- pseudoabsence_values$tavg_august
pseudoabsence_glm$spNameEN <- "Pseudo-absence"
pseudoabsence_glm$presence <- 0

points_pa_data <- bind_rows(
  presence_glm,
  pseudoabsence_glm[, c("spNameEN", "coast_distance_km", "tavg_january", "tavg_august", "presence")]
)

points_glm_pa <- glm(
  presence ~ tavg_january + tavg_august + coast_distance_km,
  data = points_pa_data,
  family = binomial()
)


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

segment_glm_data <- track_segments |>
  st_drop_geometry() |>
  mutate(segment_km_num = drop_units(segment_km))

segment_glm <- glm(
  segment_km_num ~ STEMMEAN + TIDEMAX + WINDMEAN + segment_bathymetry,
  data = segment_glm_data,
  family = Gamma(link = "log")
)

summary(segment_glm)


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)

segment_glm <- glm(
  segment_km ~ STEMMEAN + TIDEMAX + WINDMEAN + segment_bathymetry,
  data = as.data.frame(track_segments),
  family = Gamma(link = "log")
)

summary(segment_glm)
