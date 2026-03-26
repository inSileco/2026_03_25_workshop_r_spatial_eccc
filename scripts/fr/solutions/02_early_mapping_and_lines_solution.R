# Exercice 02 - Corrigé Premières cartes et création de lignes

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(mapview)

plot(st_geometry(east), col = "grey95", border = "grey40")
plot(st_geometry(ecodistricts), border = "#35ad8f", add = TRUE)
plot(st_geometry(sites), pch = 16, cex = 0.5, col = "tomato", add = TRUE)

points_map <- mapview(ecodistricts) + mapview(sites, zcol = "spNameEN")
points_map


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(mapview)

plot(east, col = "grey95", border = "grey40")
plot(ecodistricts, border = "#35ad8f", add = TRUE)
points(sites, pch = 16, cex = 0.5, col = "tomato")

points_map <- mapview(ecodistricts) + mapview(sites, zcol = "spNameEN")
points_map


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(mapview)

tracks <- gps_points |>
  group_by(Logger.ID) |>
  summarise(do_union = FALSE) |>
  st_cast("LINESTRING") |>
  mutate(track_id = row_number()) |>
  select(track_id, Logger.ID)

plot(st_geometry(habitats), border = "grey70", col = NA)
plot(st_geometry(tracks), lwd = 2, col = "tomato", add = TRUE)
plot(st_geometry(gps_points), pch = 16, cex = 0.5, col = "#00eaff55", add = TRUE)

lines_map <- mapview(habitats, zcol = "WINDMEAN") +
  mapview(tracks, zcol = "Logger.ID") +
  mapview(gps_points, zcol = "Logger.ID")
lines_map


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)
library(mapview)

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

plot(habitats, border = "grey70", col = NA, main = "Telemetry points and tracks")
lines(tracks, lwd = 2, col = "tomato")
points(gps_points, pch = 16, cex = 1, col = "#00eaff55")

lines_map <- mapview(habitats, zcol = "WINDMEAN") +
  mapview(tracks, zcol = "Logger.ID") +
  mapview(gps_points, zcol = "Logger.ID")
lines_map
