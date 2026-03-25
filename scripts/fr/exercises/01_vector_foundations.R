# Exercice 01 - Fondements des vecteurs
#
# Choisir un seul parcours et un seul outil.
# Ce fichier est propre à l'atelier et correspond à la position de l'exercice 1 dans le
# diaporama.

# -------------------------------------------------------------------------
# Parcours points + sf / stars
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

# 1) Importer le CSV et les couches vectorielles.
sites <- NULL
east <- NULL
ecodistricts <- NULL
rco <- NULL

# 2) Filtrer le tableau et créer une géométrie ponctuelle à partir de la longitude / latitude.
sites <- sites |>
  filter(year >= 2022) |>
  filter(spNameEN %in% study_species)

# TODO : convertir `sites` en objet ponctuel sf avec EPSG:4326.

# 3) Inspecter le SCR et harmoniser toutes les couches vectorielles vers EPSG:4326.
# TODO : vérifier `st_crs()` et transformer les objets au besoin.

# 4) Exporter la couche de points.
# TODO : écrire la couche de points dans un GeoPackage sous `outputs/`.


# -------------------------------------------------------------------------
# Parcours points + terra
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

# 1) Importer le CSV et les couches vectorielles.
sites <- NULL
east <- NULL
ecodistricts <- NULL
rco <- NULL

# 2) Filtrer le tableau et créer un SpatVector à partir de la longitude / latitude.
# TODO : conserver les espèces cibles à partir de 2022, puis convertir le tableau.

# 3) Inspecter le SCR et harmoniser toutes les couches vers EPSG:4326.
# TODO : utiliser `crs()` et `project()`.

# 4) Exporter la couche de points.
# TODO : écrire la couche de points dans un GeoPackage sous `outputs/`.


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Importer les points de télémétrie et les couches de contexte.
gps <- NULL
east <- NULL
habitats <- NULL

# 2) Analyser le temps, filtrer les enregistreurs cibles et conserver les points ordonnés dans le temps.
# TODO : convertir `Date_2` en POSIXct, filtrer `Logger.ID` et ordonner les lignes.

# 3) Créer des points de télémétrie à partir de la longitude / latitude.
# TODO : créer `gps_points` comme objet ponctuel sf avec EPSG:4326.

# 4) Inspecter le SCR et harmoniser les couches vers EPSG:4326.
# TODO : utiliser `st_crs()` et `st_transform()`.

# 5) Exporter les points de télémétrie.
# TODO : écrire les points dans `outputs/gps_points_sf.gpkg`.


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

data_dir <- "data"
output_dir <- "outputs"

study_loggers <- c("CEN01", "CEN02", "CEN06", "GUI20", "KIA07", "LEK01")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1) Importer les points de télémétrie et les couches de contexte.
gps <- NULL
east <- NULL
habitats <- NULL

# 2) Analyser le temps, filtrer les enregistreurs cibles et ordonner les enregistrements.
# TODO : convertir `Date_2`, filtrer `Logger.ID` et ordonner par enregistreur puis par temps.

# 3) Créer des points de télémétrie à partir de la longitude / latitude.
# TODO : créer `gps_points` avec `vect(..., geom = c(\"Longitude\", \"Latitude\"))`.

# 4) Inspecter le SCR et harmoniser les couches vers EPSG:4326.
# TODO : utiliser `crs()` et `project()`.

# 5) Exporter les points de télémétrie.
# TODO : écrire les points dans `outputs/gps_points_terra.gpkg`.
