# ============================================================
# PARCOURS 1
# POINTS + terra
# ============================================================

library(dplyr)
library(terra)
library(MASS)
library(mapview)

# ------------------------------------------------------------
# 0) Chemins et choix de l'étude
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
# 1) Importer les données tabulaires et vectorielles
# ------------------------------------------------------------

sites <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "sites.csv") |>
  read.csv()
east <- vect(file.path(data_dir, "Basemap", "east.gpkg"))
ecodistricts <- vect(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "ecodistricts.gpkg"))
rco <- vect(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "rco.gpkg"))

east <- makeValid(east)
ecodistricts <- makeValid(ecodistricts)
rco <- makeValid(rco)


# ------------------------------------------------------------
# 2) Créer des points à partir des coordonnées du CSV
# ------------------------------------------------------------

sites <- sites |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species)

sites <- vect(sites, geom = c("longitude", "latitude"), crs = "EPSG:4326")


# ------------------------------------------------------------
# 3) Harmoniser les projections vectorielles
# ------------------------------------------------------------

sites <- project(sites, "EPSG:4326")
east <- project(east, "EPSG:4326")
ecodistricts <- project(ecodistricts, "EPSG:4326")
rco <- project(rco, "EPSG:4326")


# ------------------------------------------------------------
# 4) Conserver les polygones terrestres et d'étude qui se chevauchent
# ------------------------------------------------------------

sites <- crop(sites, east)
qc <- east[east$NAME_1 == "Québec", ]


# ------------------------------------------------------------
# 5) Exploration rapide des vecteurs
# ------------------------------------------------------------

plot(east, col = "grey95", border = "grey40")
plot(ecodistricts, border = "#35ad8f", add = TRUE)
points(sites, pch = 16, cex = 0.5, col = "tomato")

mapview(ecodistricts) +
  mapview(sites, zcol = "spNameEN")


# ------------------------------------------------------------
# 6) Mesurer l'aire des polygones et la distance des points à la côte
# ------------------------------------------------------------
target_crs <- "EPSG:32198"
ecodistricts_qc <- project(ecodistricts, target_crs)
rco_qc <- project(rco, target_crs)
qc_qc <- project(qc, target_crs)
sites_qc <- project(sites, target_crs)
coast_qc <- as.lines(qc_qc)

ecodistricts$ecodistricts_area_km2 <- expanse(ecodistricts_qc, unit = "km")
rco$rco_area_km2 <- expanse(rco_qc, unit = "km")
sites$coast_distance_km <- distance(sites_qc, coast_qc)[, 1] / 1000

mapview(ecodistricts, zcol = "ecodistricts_area_km2")
mapview(sites, zcol = "coast_distance_km")


# ------------------------------------------------------------
# 7) Joindre les points aux polygones
# ------------------------------------------------------------

ecodistrict_values <- extract(ecodistricts, sites)
sites$ECODISTRIC <- ecodistrict_values$ECODISTRIC
sites$Name <- ecodistrict_values$Name
sites$ecodistricts_area_km2 <- ecodistrict_values$ecodistricts_area_km2

rco_values <- extract(rco, sites)
sites$name_en <- rco_values$name_en
sites$name_fr <- rco_values$name_fr
sites$rco_area_km2 <- rco_values$rco_area_km2


# ------------------------------------------------------------
# 8) Importer les données raster
# ------------------------------------------------------------

temperature <- rast(
  file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "temperature_avg_worldclim.tif")
)
names(temperature) <- c("tavg_january", "tavg_august")


# ------------------------------------------------------------
# 9) Exploration rapide du raster
# ------------------------------------------------------------

plot(temperature[[1]], main = "January mean temperature")
plot(east, border = "#040404", col = NA, add = TRUE)

mapview(temperature[[1]])


# ------------------------------------------------------------
# 10) Rogner le raster au Québec
# ------------------------------------------------------------

temperature <- crop(temperature, qc)

plot(temperature[[1]], main = "Temperature cropped to Quebec")
plot(qc, border = "#000000", col = NA, add = TRUE)


# ------------------------------------------------------------
# 11) Extraire les valeurs raster aux points
# ------------------------------------------------------------

temperature_values <- extract(temperature, sites)
sites$tavg_january <- temperature_values$tavg_january
sites$tavg_august <- temperature_values$tavg_august

mapview(sites, zcol = "tavg_january")


# ------------------------------------------------------------
# 12) Résumés pour l'analyse
# ------------------------------------------------------------

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

print(species_summary)
print(head(ecodistrict_summary, 10))
print(head(rco_summary, 10))


# ------------------------------------------------------------
# 13) GLM simple : comptes par écodistrict
# ------------------------------------------------------------

points_glm <- sites_table |>
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
  data = points_glm,
  family = poisson()
)

print(summary(points_glm))


# ------------------------------------------------------------
# 14) Analyse avancée : GLM avec pseudo-absences
# ------------------------------------------------------------

presence_points <- sites[sites$spNameEN == focal_species, ]
presence_glm <- as.data.frame(presence_points)[, c(
  "spNameEN", "coast_distance_km", "tavg_january", "tavg_august"
)]
presence_glm$presence <- 1

pseudoabsence_points <- spatSample(qc, nrow(presence_points), method = "random")
pseudoabsence_points <- project(pseudoabsence_points, target_crs)
pseudoabsence_points$coast_distance_km <- distance(pseudoabsence_points, coast_qc)[, 1] / 1000
pseudoabsence_points <- project(pseudoabsence_points, "EPSG:4326")

pseudoabsence_values <- extract(temperature, pseudoabsence_points)
pseudoabsence_glm <- as.data.frame(pseudoabsence_points)[, "coast_distance_km", drop = FALSE]
pseudoabsence_glm$tavg_january <- pseudoabsence_values$tavg_january
pseudoabsence_glm$tavg_august <- pseudoabsence_values$tavg_august
pseudoabsence_glm$spNameEN <- "Pseudo-absence"
pseudoabsence_glm$presence <- 0

points_glm_data <- bind_rows(
  presence_glm,
  pseudoabsence_glm[, c("spNameEN", "coast_distance_km", "tavg_january", "tavg_august", "presence")]
)

points_glm <- glm(
  presence ~ tavg_january + tavg_august + coast_distance_km,
  data = points_glm_data,
  family = binomial()
)

print(summary(points_glm))


# ------------------------------------------------------------
# 15) Analyse avancée : KDE sur les points d'observation
# ------------------------------------------------------------

focal_points <- sites[sites$spNameEN == focal_species, ]
focal_points <- project(focal_points, target_crs)
focal_xy <- crds(focal_points)
qc_bbox <- ext(qc_qc)

points_kde <- MASS::kde2d(
  focal_xy[, 1],
  focal_xy[, 2],
  n = 100,
  h = c(100000, 100000),
  lims = c(qc_bbox$xmin, qc_bbox$xmax, qc_bbox$ymin, qc_bbox$ymax)
)

points_kde <- rast(
  t(points_kde$z)[nrow(t(points_kde$z)):1, ],
  extent = ext(min(points_kde$x), max(points_kde$x), min(points_kde$y), max(points_kde$y)),
  crs = target_crs
)

points_kde <- mask(points_kde, qc_qc)
points_kde_plot <- points_kde / global(points_kde, "max", na.rm = TRUE)[1, 1]

# Seuils pour la cartographie
kde_breaks <- seq(0, 1, by = 0.1)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)

plot(qc_qc, border = "grey20", col = NA)
plot(points_kde_plot, breaks = kde_breaks, col = kde_cols, add = TRUE)
points(focal_points, pch = 16, cex = 0.6, col = "#c60d0d")
plot(qc_qc, border = "#d7d7d7", col = NA, add = TRUE)

# ------------------------------------------------------------
# 16) Carte finale
# ------------------------------------------------------------

species_cols <- c(
  "White-throated Sparrow" = "#1b9e77",
  "Ruby-crowned Kinglet" = "#d95f02",
  "Swainson's Thrush" = "#7570b3",
  "Dark-eyed Junco" = "#e7298a"
)

plot(
  temperature[[2]],
  col = hcl.colors(30, "Temps", rev = TRUE),
  main = "Bird observations and summer temperature"
)
plot(qc, border = "grey30", col = NA, add = TRUE)
points(
  sites,
  pch = 16,
  cex = 0.5,
  col = species_cols[sites$spNameEN]
)
legend(
  "bottomleft",
  legend = names(species_cols),
  col = species_cols,
  pch = 16,
  bty = "n",
  title = "Species"
)


# ------------------------------------------------------------
# 17) Exporter les résultats
# ------------------------------------------------------------

writeVector(
  sites,
  file.path(output_dir, "sites_terra.gpkg"),
  overwrite = TRUE
)

write.csv(
  species_summary,
  file.path(output_dir, "sites_terra_species_summary.csv"),
  row.names = FALSE
)

write.csv(
  ecodistrict_summary,
  file.path(output_dir, "sites_terra_ecodistrict_summary.csv"),
  row.names = FALSE
)

write.csv(
  rco_summary,
  file.path(output_dir, "sites_terra_rco_summary.csv"),
  row.names = FALSE
)
