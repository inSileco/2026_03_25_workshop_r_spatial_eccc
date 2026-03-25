# Exercise 03 - Vector Operations
#
# Prerequisite: complete Exercise 02 in the same route and tool combination.

# -------------------------------------------------------------------------
# Points route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

# 1) Subset to the overlapping land and Quebec study area.
# TODO: keep overlapping sites, ecodistricts, and RCO polygons, then create `qc`.

# 2) Measure ecodistrict area and site distance to the coast in a projected CRS.
# TODO

# 3) Join point observations to ecodistricts and RCO polygons.
# TODO

# 4) Optional extension: buffer the sites and intersect the buffers with the
#    ecodistrict polygons.


# -------------------------------------------------------------------------
# Points route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

# 1) Subset to the overlapping land and Quebec study area.
# TODO

# 2) Measure ecodistrict area and site distance to the coast in EPSG:32198.
# TODO

# 3) Join point observations to ecodistricts and RCO polygons.
# TODO

# 4) Optional extension: build site buffers and intersect them with ecodistricts.


# -------------------------------------------------------------------------
# Lines route + sf / stars
# -------------------------------------------------------------------------

library(dplyr)
library(sf)
library(units)

# This is where the lines route diverges strongly from the points route.
# 1) Transform the telemetry workflow to a projected CRS for measurement.
# TODO: project `gps_points`, `tracks`, `east`, and `habitats` to EPSG:32198.

# 2) Subset habitats to the telemetry study envelope and create `qc`.
# TODO

# 3) Measure track length and mean point-to-coast distance.
# TODO

# 4) Intersect tracks with habitat polygons to create segments.
# TODO

# 5) Optional extension: buffer tracks for later raster extraction.


# -------------------------------------------------------------------------
# Lines route + terra
# -------------------------------------------------------------------------

library(dplyr)
library(terra)

# 1) Transform the telemetry workflow to EPSG:32198.
# TODO

# 2) Subset habitats to the telemetry study envelope and create `qc`.
# TODO

# 3) Measure track length and mean point-to-coast distance.
# TODO

# 4) Intersect tracks with habitat polygons to create segments.
# TODO

# 5) Optional extension: buffer tracks for later raster extraction.
