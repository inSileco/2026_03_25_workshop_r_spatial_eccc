# Exercice 03 - Opérations vectorielles
#
# Prérequis : terminer l'exercice 02 dans le même parcours et la même combinaison d'outils.

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

# 1) Restreindre à la zone terrestre chevauchante et à la zone d'étude du Québec.
# TODO : conserver les sites, écodistricts et polygones RCO qui se chevauchent, puis créer `qc`.

# 2) Mesurer l'aire des écodistricts et la distance des sites à la côte dans un SCR projeté.
# TODO

# 3) Joindre les observations ponctuelles aux écodistricts et aux polygones des RCO.
# TODO

# 4) Extension optionnelle : tamponner les sites et intersecter les tampons avec les
#    polygones d'écodistricts.


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

# 1) Restreindre à la zone terrestre chevauchante et à la zone d'étude du Québec.
# TODO

# 2) Mesurer l'aire des écodistricts et la distance des sites à la côte dans EPSG:32198.
# TODO

# 3) Joindre les observations ponctuelles aux écodistricts et aux polygones des RCO.
# TODO

# 4) Extension optionnelle : créer des tampons autour des sites et les intersecter avec les écodistricts.


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

# C'est ici que le parcours lignes diverge nettement du parcours points.
# 1) Transformer le flux de télémétrie vers un SCR projeté pour les mesures.
# TODO : projeter `gps_points`, `tracks`, `east` et `habitats` vers EPSG:32198.

# 2) Restreindre les habitats à l'enveloppe d'étude de télémétrie et créer `qc`.
# TODO

# 3) Mesurer la longueur des trajets et la distance moyenne des points à la côte.
# TODO

# 4) Intersecter les trajets avec les polygones d'habitat pour créer des segments.
# TODO

# 5) Extension optionnelle : tamponner les trajets pour une extraction raster ultérieure.


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

# 1) Transformer le flux de télémétrie vers EPSG:32198.
# TODO

# 2) Restreindre les habitats à l'enveloppe d'étude de télémétrie et créer `qc`.
# TODO

# 3) Mesurer la longueur des trajets et la distance moyenne des points à la côte.
# TODO

# 4) Intersecter les trajets avec les polygones d'habitat pour créer des segments.
# TODO

# 5) Extension optionnelle : tamponner les trajets pour une extraction raster ultérieure.
