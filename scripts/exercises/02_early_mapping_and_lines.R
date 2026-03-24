# Exercise 02 - Early Mapping And Line Building
#
# Prerequisite: complete Exercise 01 in the same route and tool combination.

# -------------------------------------------------------------------------
# Points route + sf / stars
# -------------------------------------------------------------------------

library(mapview)

# 1) Make a quick static plot of the imported points and reference polygons.
# TODO: use `plot()` with `east`, `ecodistricts`, and `sites`.

# 2) Make a quick interactive map.
# TODO: use `mapview(ecodistricts) + mapview(sites, zcol = "spNameEN")`.

# 3) Optional: export the interactive map as HTML.


# -------------------------------------------------------------------------
# Points route + terra
# -------------------------------------------------------------------------

library(mapview)

# 1) Make a quick static plot with `plot()` and `points()`.
# TODO

# 2) Make a quick interactive map.
# TODO

# 3) Optional: export the interactive map as HTML.


# -------------------------------------------------------------------------
# Lines route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(mapview)

# This is where the lines route diverges from the points route.
# 1) Rebuild movement lines from ordered telemetry points.
# TODO: group by `Logger.ID`, summarise with `do_union = FALSE`, and cast.

# 2) Make a quick static map of habitats, tracks, and telemetry points.
# TODO

# 3) Make a quick interactive map.
# TODO

# 4) Optional: export the interactive map as HTML.


# -------------------------------------------------------------------------
# Lines route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)
library(mapview)

# This is where the lines route diverges from the points route.
# 1) Rebuild movement lines from ordered telemetry points.
# TODO: build WKT lines by logger, then convert with `vect(..., geom = "wkt")`.

# 2) Make a quick static map of habitats, tracks, and telemetry points.
# TODO

# 3) Make a quick interactive map.
# TODO

# 4) Optional: export the interactive map as HTML.
