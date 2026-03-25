# Exercice 02 - Premières cartes et création de lignes
#
# Prérequis : terminer l'exercice 01 dans le même parcours et la même combinaison d'outils.

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(mapview)

# 1) Faire un tracé statique rapide des points importés et des polygones de référence.
# TODO : utiliser `plot()` avec `east`, `ecodistricts` et `sites`.

# 2) Faire une carte interactive rapide.
# TODO : utiliser `mapview(ecodistricts) + mapview(sites, zcol = "spNameEN")`.

# 3) Optionnel : exporter la carte interactive en HTML.


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(mapview)

# 1) Faire un tracé statique rapide avec `plot()` et `points()`.
# TODO

# 2) Faire une carte interactive rapide.
# TODO

# 3) Optionnel : exporter la carte interactive en HTML.


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(mapview)

# C'est ici que le parcours lignes diverge du parcours points.
# 1) Reconstruire les lignes de déplacement à partir de points de télémétrie ordonnés.
# TODO : regrouper par `Logger.ID`, résumer avec `do_union = FALSE` et convertir.

# 2) Faire une carte statique rapide des habitats, des trajets et des points de télémétrie.
# TODO

# 3) Faire une carte interactive rapide.
# TODO

# 4) Optionnel : exporter la carte interactive en HTML.


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)
library(mapview)

# C'est ici que le parcours lignes diverge du parcours points.
# 1) Reconstruire les lignes de déplacement à partir de points de télémétrie ordonnés.
# TODO : construire des lignes WKT par enregistreur, puis convertir avec `vect(..., geom = "wkt")`.

# 2) Faire une carte statique rapide des habitats, des trajets et des points de télémétrie.
# TODO

# 3) Faire une carte interactive rapide.
# TODO

# 4) Optionnel : exporter la carte interactive en HTML.
