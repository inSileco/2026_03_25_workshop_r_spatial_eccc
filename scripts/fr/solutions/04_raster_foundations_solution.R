# Exercice 04 - Corrigé Fondements des rasters

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(stars)
library(mapview)

temperature <- read_stars(
  file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "temperature_avg_worldclim.tif")
)

temperature
write_stars(temperature, file.path(output_dir, "temperature_points_sf_ex04.tif"))

plot(st_geometry(east), border = "#35ad8f")
plot(temperature[, , , 1], add = TRUE)
plot(st_geometry(east), border = "#35ad8f", add = TRUE)

mapview(temperature[, , , 1])


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(terra)
library(mapview)

temperature <- rast(
  file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "temperature_avg_worldclim.tif")
)
names(temperature) <- c("tavg_january", "tavg_august")

temperature
writeRaster(temperature, file.path(output_dir, "temperature_points_terra_ex04.tif"), overwrite = TRUE)

plot(temperature[[1]], main = "January mean temperature")
plot(east, border = "#040404", col = NA, add = TRUE)

mapview(temperature[[1]])


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(stars)
library(mapview)

bathymetry <- read_stars(file.path(data_dir, "MinganTelemetrie", "bathymetrie.tif"))

bathymetry
write_stars(bathymetry, file.path(output_dir, "bathymetry_lines_sf_ex04.tif"))

plot(bathymetry, main = "Bathymetry")
mapview(bathymetry)


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(terra)
library(mapview)

bathymetry <- rast(file.path(data_dir, "MinganTelemetrie", "bathymetrie.tif"))

bathymetry
writeRaster(bathymetry, file.path(output_dir, "bathymetry_lines_terra_ex04.tif"), overwrite = TRUE)

plot(bathymetry, main = "Bathymetry")
mapview(bathymetry)
