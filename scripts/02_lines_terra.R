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

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------
# 1) Import tabular and vector data
# ------------------------------------------------------------

gps <- file.path(data_dir, "MinganTelemetrie", "gps5710.csv") |> read.csv()
east <- vect(file.path(data_dir, "Basemap", "east.gpkg"))
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

target_crs <- "EPSG:32198"
gps_points <- project(gps_points, target_crs)
tracks <- project(tracks, target_crs)
east <- project(east, target_crs)
habitats <- project(habitats, target_crs)


# ------------------------------------------------------------
# 4) Keep the overlapping land and study polygons
# ------------------------------------------------------------

habitats <- crop(habitats, ext(tracks))
qc <- east[east$NAME_1 == "Québec", ]


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
points(gps_points, pch = 16, cex = 1, col = "#00eaff55")

mapview(habitats, zcol = "WINDMEAN") +
  mapview(tracks, zcol = "Logger.ID") +
  mapview(gps_points, zcol = "Logger.ID")

# ------------------------------------------------------------
# 6) Measure track length and distance to coast
# ------------------------------------------------------------

coast <- as.lines(qc)

tracks$length_km <- perim(tracks) / 1000
gps_points$coast_distance_km <- distance(gps_points, coast)[, 1] / 1000

coast_summary <- as.data.frame(gps_points) |>
  group_by(Logger.ID) |>
  summarise(
    mean_coast_distance_km = mean(coast_distance_km),
    .groups = "drop"
  )

tracks <- merge(tracks, coast_summary, by = "Logger.ID")

mapview(tracks, zcol = "mean_coast_distance_km")
mapview(tracks, zcol = "length_km")

# ------------------------------------------------------------
# 7) Join the tracks to habitats
# ------------------------------------------------------------

track_segments <- intersect(tracks, habitats)
track_segments$segment_km <- perim(track_segments) / 1000



# ------------------------------------------------------------
# 8) Summaries from vector overlap
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
# 9) Import raster data
# ------------------------------------------------------------

bathymetry <- rast(file.path(data_dir, "MinganTelemetrie", "bathymetrie.tif"))


# ------------------------------------------------------------
# 10) Quick raster exploration
# ------------------------------------------------------------

plot(bathymetry, main = "Bathymetry")
mapview(bathymetry)

# ------------------------------------------------------------
# 11) Project and crop the raster
# ------------------------------------------------------------

bathymetry <- project(bathymetry, target_crs)

track_buffers <- buffer(tracks, width = 1000)
bathymetry <- crop(bathymetry, ext(track_buffers))

plot(bathymetry, main = "Bathymetry cropped to the telemetry area")
plot(coast, add = TRUE)
lines(tracks, lwd = 2, col = "tomato")


# ------------------------------------------------------------
# 12) Extract bathymetry along tracks and segments
# ------------------------------------------------------------

bathymetry_mean <- extract(
  bathymetry,
  track_buffers,
  fun = mean,
  na.rm = TRUE
)
bathymetry_min <- extract(
  bathymetry,
  track_buffers,
  fun = min,
  na.rm = TRUE
)

segment_bathymetry <- extract(
  bathymetry,
  track_segments,
  fun = mean,
  na.rm = TRUE
) |>
  rename(segment_bathymetry = bathymetrie)

track_segments$segment_bathymetry <- segment_bathymetry$segment_bathymetry


# ------------------------------------------------------------
# 13) Summaries for analysis
# ------------------------------------------------------------

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

print(track_summary)


# ------------------------------------------------------------
# 14) Advanced analysis: GLM on line segments
# ------------------------------------------------------------

segment_glm <- glm(
  segment_km ~ STEMMEAN + TIDEMAX + WINDMEAN + segment_bathymetry,
  data = as.data.frame(track_segments),
  family = Gamma(link = "log")
)

print(summary(segment_glm))


# ------------------------------------------------------------
# 15) Advanced analysis: KDE on telemetry points
# ------------------------------------------------------------

gps_xy <- crds(gps_points)

tracks_kde <- MASS::kde2d(gps_xy[, 1], gps_xy[, 2], n = 100)

tracks_kde <- rast(
  t(tracks_kde$z)[nrow(t(tracks_kde$z)):1, ],
  extent = ext(
    min(tracks_kde$x),
    max(tracks_kde$x),
    min(tracks_kde$y),
    max(tracks_kde$y)
  ),
  crs = target_crs
)

tracks_kde_plot <- tracks_kde / global(tracks_kde, "max", na.rm = TRUE)[1, 1]

# Breaks for plotting
# Continuous
kde_breaks <- seq(0, 1, by = 0.1)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)
plot(tracks_kde_plot, breaks = kde_breaks, col = kde_cols)
points(gps_points, lwd = 2, col = "tomato")

# Quantile
kde_vals <- values(tracks_kde_plot, mat = FALSE)
kde_vals <- kde_vals[!is.na(kde_vals)]
kde_breaks <- quantile(kde_vals, probs = seq(0, 1, by = 0.1))
kde_breaks <- unique(kde_breaks)
kde_cols <- viridis::viridis(length(kde_breaks) - 1)
plot(tracks_kde_plot, breaks = kde_breaks, col = kde_cols)
points(gps_points, lwd = 2, col = "tomato")


# ------------------------------------------------------------
# 16) Final map
# ------------------------------------------------------------

track_colors <- c(
  "#d73027",
  "#4575b4",
  "#1a9850",
  "#984ea3",
  "#ff7f00",
  "#4d4d4d"
)
track_labels <- as.data.frame(tracks)$Logger.ID

plot(
  bathymetry,
  col = hcl.colors(25, "Blues 3", rev = TRUE),
  main = "Telemetry tracks, habitats, and bathymetry"
)
plot(habitats, border = "grey70", col = NA, add = TRUE)
lines(tracks, col = track_colors, lwd = 2)


# ------------------------------------------------------------
# 17) Export outputs
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
