# ============================================================
# WORKFLOW 2
# LINES + terra
# ============================================================

library(dplyr)
library(terra)
library(mapview)

# ------------------------------------------------------------
# 0) Paths and study choices
# ------------------------------------------------------------

data_dir <- "data"
output_dir <- "outputs"
target_crs <- "EPSG:32198"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------
# 1) Import tabular and vector data
# ------------------------------------------------------------

gps <- file.path(data_dir, "MinganTelemetrie", "gps5710.csv") |> read.csv()
habitats <- file.path(
  data_dir,
  "MinganTelemetrie",
  "epipelagic_habitats.gpkg"
) |>
  vect()


# ------------------------------------------------------------
# 2) Create telemetry points from CSV coordinates
# ------------------------------------------------------------

gps <- gps |>
  select(-X, -n) |>
  mutate(
    Date_2 = as.POSIXct(Date_2, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  ) |>
  filter(Logger.ID %in% study_loggers) |>
  arrange(Logger.ID, Date_2)

gps_points <- vect(gps, geom = c("Longitude", "Latitude"), crs = "EPSG:4326")


# ------------------------------------------------------------
# 3) Rebuild movement lines from ordered points
# ------------------------------------------------------------

tracks_wkt <- gps |>
  group_by(Logger.ID) |>
  summarise(
    wkt = paste0(
      "LINESTRING (",
      paste(Longitude, Latitude, sep = " ", collapse = ", "),
      ")"
    ),
    .groups = "drop"
  ) |>
  mutate(track_id = row_number()) |>
  select(track_id, Logger.ID, wkt)

tracks <- vect(tracks_wkt, geom = "wkt", crs = "EPSG:4326")


# ------------------------------------------------------------
# 4) Harmonize vector projections
# ------------------------------------------------------------

gps_points <- project(gps_points, target_crs)
tracks <- project(tracks, target_crs)
habitats <- project(habitats, target_crs)


# ------------------------------------------------------------
# 5) Quick vector exploration
# ------------------------------------------------------------

plot(
  habitats,
  border = "grey70",
  col = NA,
  main = "Telemetry tracks and habitat polygons"
)
lines(tracks, lwd = 2, col = "tomato")
points(gps_points, pch = 16, cex = 0.3, col = "orange")


# ------------------------------------------------------------
# 6) Measure track length and intersect with habitats
# ------------------------------------------------------------

tracks$length_km <- perim(tracks) / 1000

track_segments <- intersect(tracks, habitats)
track_segments$segment_km <- perim(track_segments) / 1000


# ------------------------------------------------------------
# 7) Summaries from vector overlap
# ------------------------------------------------------------

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

print(habitat_summary)


# ------------------------------------------------------------
# 8) Advanced analysis: GLM on line segments
# ------------------------------------------------------------

segment_glm <- glm(
  segment_km ~ STEMMEAN + TIDEMAX + WINDMEAN,
  data = as.data.frame(track_segments),
  family = Gamma(link = "log")
)

print(summary(segment_glm))


# ------------------------------------------------------------
# 9) Advanced analysis: KDE on telemetry points
# ------------------------------------------------------------

gps_xy <- crds(gps_points)

tracks_kde <- MASS::kde2d(gps_xy[, 1], gps_xy[, 2], n = 100)

tracks_kde <- rast(
  t(tracks_kde$z),
  extent = ext(
    min(tracks_kde$x),
    max(tracks_kde$x),
    min(tracks_kde$y),
    max(tracks_kde$y)
  ),
  crs = target_crs
)

plot(tracks_kde, main = "Kernel density of telemetry points")
lines(tracks, lwd = 2, col = "tomato")


# ------------------------------------------------------------
# 10) Import raster data
# ------------------------------------------------------------

bathymetry <- rast(file.path(data_dir, "MinganTelemetrie", "bathymetrie.tif"))


# ------------------------------------------------------------
# 11) Quick raster exploration
# ------------------------------------------------------------

plot(bathymetry, main = "Bathymetry")


# ------------------------------------------------------------
# 12) Project and crop the raster
# ------------------------------------------------------------

bathymetry <- project(bathymetry, target_crs)
bathymetry[bathymetry > 0] <- NA

track_buffers <- buffer(tracks, width = 1000)
bathymetry_mingan <- crop(bathymetry, ext(track_buffers))

plot(bathymetry_mingan, main = "Bathymetry cropped to the telemetry area")


# ------------------------------------------------------------
# 13) Extract bathymetry along buffered tracks
# ------------------------------------------------------------

bathymetry_mean <- extract(
  bathymetry_mingan,
  track_buffers,
  fun = mean,
  na.rm = TRUE
)
bathymetry_min <- extract(
  bathymetry_mingan,
  track_buffers,
  fun = min,
  na.rm = TRUE
)


# ------------------------------------------------------------
# 14) Final summary
# ------------------------------------------------------------

track_summary <- as.data.frame(tracks) |>
  select(track_id, Logger.ID, length_km) |>
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

print(track_summary)


# ------------------------------------------------------------
# 15) Final map
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
  bathymetry_mingan,
  col = hcl.colors(25, "Blues 3", rev = TRUE),
  main = "Telemetry tracks, habitats, and bathymetry"
)
plot(habitats, border = "grey70", col = NA, add = TRUE)
lines(tracks, col = track_colors, lwd = 2)
legend(
  "bottomleft",
  legend = tracks$Logger.ID,
  col = track_colors,
  lwd = 2,
  bty = "n",
  title = "Logger"
)


# ------------------------------------------------------------
# 16) Export outputs
# ------------------------------------------------------------

writeVector(
  tracks,
  file.path(output_dir, "telemetry_tracks.gpkg"),
  overwrite = TRUE
)

write.csv(
  track_summary,
  file.path(output_dir, "telemetry_track_summary.csv"),
  row.names = FALSE
)
