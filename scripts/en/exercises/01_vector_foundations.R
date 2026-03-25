# Exercise 01 - Vector Foundations
#
# Choose one route and one tool only.
# This file is workshop-specific and follows the Exercise 1 position in the
# slide deck.

# -------------------------------------------------------------------------
# Points route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)

data_dir <- "data"
output_dir <- "outputs"

study_species <- c(
  "White-throated Sparrow",
  "Ruby-crowned Kinglet",
  "Swainson's Thrush",
  "Dark-eyed Junco"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Import the CSV and vector layers.
sites <- NULL
east <- NULL
ecodistricts <- NULL
rco <- NULL

# 2) Filter the table and create point geometry from longitude / latitude.
sites <- sites |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species)

# TODO: convert `sites` to an sf point object with EPSG:4326.

# 3) Inspect CRS and harmonize all vector layers to EPSG:4326.
# TODO: check `st_crs()` and transform objects where needed.

# 4) Export the point output.
# TODO: write the point layer to a GeoPackage in `outputs/`.


# -------------------------------------------------------------------------
# Points route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

data_dir <- "data"
output_dir <- "outputs"

study_species <- c(
  "White-throated Sparrow",
  "Ruby-crowned Kinglet",
  "Swainson's Thrush",
  "Dark-eyed Junco"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Import the CSV and vector layers.
sites <- NULL
east <- NULL
ecodistricts <- NULL
rco <- NULL

# 2) Filter the table and create a SpatVector from longitude / latitude.
# TODO: keep the target species from 2022 onward, then convert the table.

# 3) Inspect CRS and harmonize all layers to EPSG:4326.
# TODO: use `crs()` and `project()`.

# 4) Export the point output.
# TODO: write the point layer to a GeoPackage in `outputs/`.


# -------------------------------------------------------------------------
# Lines route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Import telemetry points and context layers.
gps <- NULL
east <- NULL
habitats <- NULL

# 2) Parse time, filter the target loggers, and keep points ordered in time.
# TODO: convert `Date_2` to POSIXct, filter `Logger.ID`, and arrange rows.

# 3) Create telemetry points from longitude / latitude.
# TODO: build `gps_points` as an sf point object with EPSG:4326.

# 4) Inspect CRS and harmonize layers to EPSG:4326.
# TODO: use `st_crs()` and `st_transform()`.

# 5) Export the telemetry points.
# TODO: write the points to `outputs/gps_points_sf.gpkg`.


# -------------------------------------------------------------------------
# Lines route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Import telemetry points and context layers.
gps <- NULL
east <- NULL
habitats <- NULL

# 2) Parse time, filter the target loggers, and order the records.
# TODO: convert `Date_2`, filter `Logger.ID`, and arrange by logger then time.

# 3) Create telemetry points from longitude / latitude.
# TODO: build `gps_points` with `vect(..., geom = c(\"Longitude\", \"Latitude\"))`.

# 4) Inspect CRS and harmonize layers to EPSG:4326.
# TODO: use `crs()` and `project()`.

# 5) Export the telemetry points.
# TODO: write the points to `outputs/gps_points_terra.gpkg`.
