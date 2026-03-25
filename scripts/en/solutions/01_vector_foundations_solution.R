# Exercise 01 - Vector Foundations Solution

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

sites <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "sites.csv") |>
  read.csv() |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

east <- file.path(data_dir, "Basemap", "east.gpkg") |>
  st_read(quiet = TRUE) |>
  st_transform(4326)

ecodistricts <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "ecodistricts.gpkg") |>
  st_read(quiet = TRUE) |>
  st_transform(4326)

rco <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "rco.gpkg") |>
  st_read(quiet = TRUE) |>
  st_transform(4326)

st_crs(sites)
st_write(sites, file.path(output_dir, "sites_points_sf_ex01.gpkg"), delete_dsn = TRUE, quiet = TRUE)


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

sites <- file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "sites.csv") |>
  read.csv() |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species)

sites <- vect(sites, geom = c("longitude", "latitude"), crs = "EPSG:4326")
east <- vect(file.path(data_dir, "Basemap", "east.gpkg")) |> project("EPSG:4326")
ecodistricts <- vect(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "ecodistricts.gpkg")) |>
  project("EPSG:4326")
rco <- vect(file.path(data_dir, "SuiviOiseauxBoreauxQuebec", "rco.gpkg")) |>
  project("EPSG:4326")

crs(sites)
writeVector(sites, file.path(output_dir, "sites_points_terra_ex01.gpkg"), overwrite = TRUE)


# -------------------------------------------------------------------------
# Lines route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

gps <- file.path(data_dir, "MinganTelemetrie", "gps5710.csv") |>
  read.csv() |>
  select(-X, -n) |>
  mutate(Date_2 = as.POSIXct(Date_2, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")) |>
  filter(Logger.ID %in% study_loggers) |>
  arrange(Logger.ID, Date_2)

gps_points <- gps |>
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)

east <- file.path(data_dir, "Basemap", "east.gpkg") |>
  st_read(quiet = TRUE) |>
  st_transform(4326)

habitats <- file.path(data_dir, "MinganTelemetrie", "epipelagic_habitats.gpkg") |>
  st_read(quiet = TRUE) |>
  st_transform(4326)

st_crs(gps_points)
st_write(gps_points, file.path(output_dir, "gps_points_sf_ex01.gpkg"), delete_dsn = TRUE, quiet = TRUE)


# -------------------------------------------------------------------------
# Lines route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

gps <- file.path(data_dir, "MinganTelemetrie", "gps5710.csv") |>
  read.csv() |>
  select(-X, -n) |>
  mutate(Date_2 = as.POSIXct(Date_2, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")) |>
  filter(Logger.ID %in% study_loggers) |>
  arrange(Logger.ID, Date_2)

gps_points <- vect(gps, geom = c("Longitude", "Latitude"), crs = "EPSG:4326")
east <- vect(file.path(data_dir, "Basemap", "east.gpkg")) |> project("EPSG:4326")
habitats <- vect(file.path(data_dir, "MinganTelemetrie", "epipelagic_habitats.gpkg")) |>
  project("EPSG:4326")

crs(gps_points)
writeVector(gps_points, file.path(output_dir, "gps_points_terra_ex01.gpkg"), overwrite = TRUE)
