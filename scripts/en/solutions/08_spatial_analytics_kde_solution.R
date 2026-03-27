# Exercise 08 - Spatial Analytics With KDE Solution

# -------------------------------------------------------------------------
# Points route + sf / stars
# -------------------------------------------------------------------------

library(sf)
library(stars)

focal_points <- sites |>
  filter(spNameEN == "White-throated Sparrow") |>
  st_transform(32198)

focal_xy <- st_coordinates(focal_points)
qc_qc <- st_transform(qc, 32198)
qc_bbox <- st_bbox(qc_qc)

points_kde <- MASS::kde2d(
  focal_xy[, 1],
  focal_xy[, 2],
  n = 100,
  h = c(100000, 100000),
  lims = c(qc_bbox["xmin"], qc_bbox["xmax"], qc_bbox["ymin"], qc_bbox["ymax"])
)

points_kde <- st_as_stars(
  list(kde = points_kde$z),
  dimensions = st_dimensions(x = points_kde$x, y = points_kde$y)
) |>
  st_set_crs(32198)

points_kde <- points_kde[qc_qc]
points_kde_plot <- points_kde
points_kde_plot[[1]] <- points_kde_plot[[1]] / max(points_kde_plot[[1]], na.rm = TRUE)


# -------------------------------------------------------------------------
# Points route + terra
# -------------------------------------------------------------------------

library(terra)

focal_points <- sites[sites$spNameEN == "White-throated Sparrow", ]
focal_points <- project(focal_points, target_crs)
focal_xy <- crds(focal_points)
qc_bbox <- ext(qc_qc)

points_kde <- MASS::kde2d(
  focal_xy[, 1],
  focal_xy[, 2],
  n = 100,
  h = c(100000, 100000),
  lims = c(qc_bbox$xmin, qc_bbox$xmax, qc_bbox$ymin, qc_bbox$ymax)
)

points_kde <- rast(
  t(points_kde$z)[nrow(t(points_kde$z)):1, ],
  extent = ext(min(points_kde$x), max(points_kde$x), min(points_kde$y), max(points_kde$y)),
  crs = target_crs
)

points_kde <- mask(points_kde, qc_qc)
points_kde_plot <- points_kde / global(points_kde, "max", na.rm = TRUE)[1, 1]


# -------------------------------------------------------------------------
# Lines route + sf / stars
# -------------------------------------------------------------------------

library(sf)
library(stars)

gps_xy <- st_coordinates(gps_points)
track_bbox <- st_bbox(tracks)

tracks_kde <- MASS::kde2d(
  gps_xy[, 1],
  gps_xy[, 2],
  n = 100,
  h = c(5000, 5000),
  lims = c(track_bbox["xmin"], track_bbox["xmax"], track_bbox["ymin"], track_bbox["ymax"])
)

tracks_kde <- st_as_stars(
  list(kde = tracks_kde$z),
  dimensions = st_dimensions(x = tracks_kde$x, y = tracks_kde$y)
) |>
  st_set_crs(target_crs)

tracks_kde <- tracks_kde[st_as_sfc(st_bbox(tracks))]
tracks_kde_plot <- tracks_kde
tracks_kde_plot[[1]] <- tracks_kde_plot[[1]] / max(tracks_kde_plot[[1]], na.rm = TRUE)


# -------------------------------------------------------------------------
# Lines route + terra
# -------------------------------------------------------------------------

library(terra)

gps_xy <- crds(gps_points)

tracks_kde <- MASS::kde2d(gps_xy[, 1], gps_xy[, 2], n = 100, h = c(5000, 5000))

tracks_kde <- rast(
  t(tracks_kde$z)[nrow(t(tracks_kde$z)):1, ],
  extent = ext(
    min(tracks_kde$x),
    max(tracks_kde$x),
    min(tracks_kde$y),
    max(tracks_kde$y)
  ),
  crs = target_crs
)

tracks_kde_plot <- tracks_kde / global(tracks_kde, "max", na.rm = TRUE)[1, 1]
