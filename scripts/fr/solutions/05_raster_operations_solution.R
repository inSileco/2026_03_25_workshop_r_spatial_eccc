# Exercice 05 - Corrigé Opérations raster

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(stars)
library(sf)

temperature_qc <- st_crop(temperature, st_bbox(qc))
temperature_qc_proj <- st_warp(temperature_qc, crs = st_crs(st_transform(qc, 32198)))
temperature_mean <- st_apply(temperature_qc, c("x", "y"), mean)
names(temperature_mean) <- "tavg_mean"

plot(st_geometry(qc), border = "grey20")
plot(temperature_qc[, , , 1], add = TRUE)
plot(st_geometry(qc), border = "grey20", col = "#2c716844", add = TRUE)


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(terra)

temperature_qc <- crop(temperature, qc)
temperature_qc_proj <- project(temperature_qc, "EPSG:32198")
temperature_qc_mask <- mask(temperature_qc, qc)
temperature_mean <- app(temperature_qc, mean)
names(temperature_mean) <- "tavg_mean"

plot(temperature_qc[[1]], main = "Temperature cropped to Quebec")
plot(qc, border = "#000000", col = NA, add = TRUE)


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(stars)
library(sf)

bathymetry <- st_warp(bathymetry, crs = st_crs(tracks))
bathymetry <- st_crop(bathymetry, st_bbox(tracks))
bathymetry_abs <- abs(bathymetry)

plot(bathymetry, main = "Bathymetry cropped to the telemetry area")
plot(st_geometry(coast), add = TRUE)
plot(st_geometry(tracks), lwd = 2, col = "tomato", add = TRUE)


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(terra)

bathymetry <- project(bathymetry, target_crs)
track_buffers <- buffer(tracks, width = 1000)
bathymetry <- crop(bathymetry, ext(track_buffers))
bathymetry_mask <- mask(bathymetry, track_buffers)
bathymetry_abs <- abs(bathymetry)

plot(bathymetry, main = "Bathymetry cropped to the telemetry area")
plot(coast, add = TRUE)
lines(tracks, lwd = 2, col = "tomato")
