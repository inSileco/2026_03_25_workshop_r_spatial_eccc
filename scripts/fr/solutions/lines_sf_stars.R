# ============================================================
# PARCOURS 2
# LIGNES + sf / stars
# ============================================================

library(dplyr)
library(sf)
library(stars)
library(units)
library(mapview)

# ------------------------------------------------------------
# 0) Chemins et choix de l'étude
# ------------------------------------------------------------

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------
# 1) Importer les données tabulaires et vectorielles
# ------------------------------------------------------------

gps <- file.path(data_dir, "MinganTelemetrie", "gps5710.csv") |>
  read.csv()
east <- file.path(data_dir, "Basemap", "east.gpkg") |>
  st_read()
habitats <- file.path(
  data_dir,
  "MinganTelemetrie",
  "epipelagic_habitats.gpkg"
) |>
  st_read()


# ------------------------------------------------------------
# 2) Créer des points de télémétrie à partir des coordonnées du CSV
# ------------------------------------------------------------

gps <- gps |>
  select(-X, -n) |>
  mutate(
    Date_2 = as.POSIXct(Date_2, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  ) |>
  filter(Logger.ID %in% study_loggers) |>
  arrange(Logger.ID, Date_2)

gps_points <- gps |>
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)


# ------------------------------------------------------------
# 3) Reconstruire les lignes de déplacement à partir de points ordonnés
# ------------------------------------------------------------

tracks <- gps_points |>
  group_by(Logger.ID) |>
  summarise(do_union = FALSE) |>
  st_cast("LINESTRING") |>
  mutate(track_id = row_number()) |>
  select(track_id, Logger.ID)


# ------------------------------------------------------------
# 4) Harmoniser les projections vectorielles
# ------------------------------------------------------------

target_crs <- 32198
gps_points <- st_transform(gps_points, target_crs)
tracks <- st_transform(tracks, target_crs)
east <- st_transform(east, target_crs)
habitats <- st_transform(habitats, target_crs)


# ------------------------------------------------------------
# 5) Conserver les polygones terrestres et d'étude qui se chevauchent
# ------------------------------------------------------------

habitats <- st_crop(habitats, st_bbox(tracks))
qc <- east |>
  filter(NAME_1 == "Québec")


# ------------------------------------------------------------
# 6) Exploration rapide des vecteurs
# ------------------------------------------------------------

plot(st_geometry(habitats), border = "grey70", col = NA)
plot(st_geometry(tracks), lwd = 2, col = "tomato", add = TRUE)
plot(st_geometry(gps_points), pch = 16, cex = 0.5, col = "#00eaff55", add = TRUE)

mapview(habitats, zcol = "WINDMEAN") +
  mapview(tracks, zcol = "Logger.ID") +
  mapview(gps_points, zcol = "Logger.ID")


# ------------------------------------------------------------
# 7) Mesurer la longueur des trajets et la distance à la côte
# ------------------------------------------------------------

coast <- st_boundary(qc)

tracks <- tracks |>
  mutate(
    length_km = st_length(geometry),
    length_km = set_units(length_km, "km")
  )

gps_points <- gps_points |>
  mutate(
    coast_distance = st_distance(geometry, coast),
    coast_distance = set_units(coast_distance, "km")
  )

coast_summary <- gps_points |>
  st_drop_geometry() |>
  group_by(Logger.ID) |>
  summarise(
    mean_coast_distance_km = mean(coast_distance),
    .groups = "drop"
  )

tracks <- left_join(tracks, coast_summary, by = "Logger.ID")

mapview(tracks, zcol = "mean_coast_distance_km")
mapview(tracks, zcol = "length_km")


# ------------------------------------------------------------
# 8) Joindre les trajets aux habitats
# ------------------------------------------------------------

track_segments <- st_intersection(tracks, habitats) |>
  mutate(
    segment_km = st_length(geometry),
    segment_km = set_units(segment_km, "km")
  )


# ------------------------------------------------------------
# 9) Résumés à partir du chevauchement vectoriel
# ------------------------------------------------------------

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

print(habitat_summary)


# ------------------------------------------------------------
# 10) Importer les données raster
# ------------------------------------------------------------

bathymetry <- read_stars(file.path(data_dir, "MinganTelemetrie", "bathymetrie.tif"))


# ------------------------------------------------------------
# 11) Exploration rapide du raster
# ------------------------------------------------------------

plot(bathymetry, main = "Bathymetry")
mapview(bathymetry)


# ------------------------------------------------------------
# 12) Projeter et rogner le raster
# ------------------------------------------------------------

bathymetry <- st_warp(bathymetry, crs = st_crs(tracks))
bathymetry <- st_crop(bathymetry, st_bbox(tracks))

plot(bathymetry, main = "Bathymetry cropped to the telemetry area")
plot(st_geometry(coast), add = TRUE)
plot(st_geometry(tracks), lwd = 2, col = "tomato", add = TRUE)


# ------------------------------------------------------------
# 13) Extraire la bathymétrie le long des trajets et des segments
# ------------------------------------------------------------

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


# ------------------------------------------------------------
# 14) Résumés pour l'analyse
# ------------------------------------------------------------

track_summary <- tracks |>
  st_drop_geometry() |>
  select(
    track_id,
    Logger.ID,
    length_km,
    mean_coast_distance_km,
    mean_bathymetry,
    min_bathymetry
  ) |>
  left_join(habitat_summary, by = "Logger.ID") |>
  arrange(desc(length_km))

print(track_summary)


# ------------------------------------------------------------
# 15) Analyse avancée : GLM sur les segments de ligne
# ------------------------------------------------------------

segment_glm <- track_segments |>
  st_drop_geometry() |>
  mutate(segment_km_num = drop_units(segment_km))

segment_glm <- glm(
  segment_km_num ~ STEMMEAN + TIDEMAX + WINDMEAN + segment_bathymetry,
  data = segment_glm,
  family = Gamma(link = "log")
)

print(summary(segment_glm))


# ------------------------------------------------------------
# 16) Analyse avancée : KDE sur les points de télémétrie
# ------------------------------------------------------------

gps_xy <- st_coordinates(gps_points)
track_bbox <- st_bbox(tracks)

tracks_kde <- MASS::kde2d(
  gps_xy[, 1],
  gps_xy[, 2],
  n = 100,
  h = c(5000, 5000),
  lims = c(track_bbox["xmin"], track_bbox["xmax"], track_bbox["ymin"], track_bbox["ymax"])
)

tracks_kde <- st_as_stars(
  list(kde = tracks_kde$z),
  dimensions = st_dimensions(x = tracks_kde$x, y = tracks_kde$y)
) |>
  st_set_crs(target_crs)

tracks_kde <- tracks_kde[st_as_sfc(st_bbox(tracks))]
tracks_kde_plot <- tracks_kde
tracks_kde_plot[[1]] <- tracks_kde_plot[[1]] / max(tracks_kde_plot[[1]], na.rm = TRUE)

# Seuils pour la cartographie
# Continu
kde_breaks <- seq(0, 1, by = 0.1)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)
plot(st_geometry(gps_points))
plot(tracks_kde_plot, breaks = kde_breaks, col = kde_cols, add = TRUE)
plot(st_geometry(gps_points), pch = 16, cex = 0.4, col = "tomato", add = TRUE)

# Quantile
kde_vals <- as.vector(tracks_kde_plot[[1]])
kde_vals <- kde_vals[!is.na(kde_vals)]
kde_breaks <- quantile(kde_vals, probs = seq(0, 1, by = 0.1))
kde_breaks <- unique(kde_breaks)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)
plot(st_geometry(gps_points))
plot(tracks_kde_plot, breaks = kde_breaks, col = kde_cols, add = TRUE)
points(gps_points, lwd = 2, col = "tomato")

# ------------------------------------------------------------
# 17) Carte finale
# ------------------------------------------------------------

track_colors <- c(
  "#d73027",
  "#4575b4",
  "#1a9850",
  "#984ea3",
  "#ff7f00",
  "#4d4d4d"
)

plot(
  bathymetry,
  col = hcl.colors(25, "Blues 3", rev = TRUE),
  main = "Telemetry tracks, habitats, and bathymetry"
)
plot(st_geometry(habitats), border = "grey70", col = NA, add = TRUE)
plot(st_geometry(tracks), col = track_colors, lwd = 2, add = TRUE)
legend(
  "bottomleft",
  inset = 0.02,
  legend = tracks$Logger.ID,
  col = track_colors,
  lwd = 2,
  bg = "white",
  box.col = "grey60",
  title = "Logger"
)


# ------------------------------------------------------------
# 18) Exporter les résultats
# ------------------------------------------------------------

st_write(
  tracks,
  file.path(output_dir, "telemetry_tracks_sf.gpkg"),
  delete_dsn = TRUE,
  quiet = TRUE
)

write.csv(
  track_summary,
  file.path(output_dir, "telemetry_track_summary_sf.csv"),
  row.names = FALSE
)
