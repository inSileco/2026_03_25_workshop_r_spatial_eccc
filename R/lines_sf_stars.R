#' Telemetry workflow wrapped in a function
#'
#' This function keeps the original workshop workflow for lines, but wraps it
#' into a reusable function. It filters the telemetry data to one or more loggers,
#' rebuilds the track, joins environmental context, fits a simple GLM, computes
#' a KDE, and saves a static `tmap`.
#'
#' @param logger_id Logger ID(s) to keep from `gps5710.csv`.
#' @param output_dir Folder where the static map will be saved.
#'
#' @return A list with the filtered line data, the GLM summary, the KDE output,
#'   and the saved map path.
#'
#' @examples
#' mingan_tracks <- mingan(
#'   logger_id = c("CEN01", "CEN02")
#' )
#'
#' mingan_tracks$lines
#' mingan_tracks$glm_summary
#' mingan_tracks$kde
#' mingan_tracks$map
#' @export
mingan <- function(logger_id, output_dir = tempdir()) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  gps <- read.csv(
    system.file(
      "exdata",
      "MinganTelemetrie",
      "gps5710.csv",
      package = "workshop_r_spatial_eccc"
    )
  ) |>
    dplyr::select(-X, -n) |>
    dplyr::mutate(
      Date_2 = as.POSIXct(Date_2, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
    ) |>
    dplyr::filter(Logger.ID %in% logger_id) |>
    dplyr::arrange(Logger.ID, Date_2)

  east <- sf::st_read(
    system.file("exdata", "Basemap", "east.gpkg", package = "workshop_r_spatial_eccc"),
    quiet = TRUE
  )
  habitats <- sf::st_read(
    system.file(
      "exdata",
      "MinganTelemetrie",
      "epipelagic_habitats.gpkg",
      package = "workshop_r_spatial_eccc"
    ),
    quiet = TRUE
  )

  gps_points <- gps |>
    sf::st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326, remove = FALSE)

  tracks <- gps_points |>
    dplyr::group_by(Logger.ID) |>
    dplyr::summarise(do_union = FALSE) |>
    sf::st_cast("LINESTRING") |>
    dplyr::mutate(track_id = dplyr::row_number()) |>
    dplyr::select(track_id, Logger.ID)

  target_crs <- 32198
  gps_points <- sf::st_transform(gps_points, target_crs)
  tracks <- sf::st_transform(tracks, target_crs)
  east <- sf::st_transform(east, target_crs)
  habitats <- sf::st_transform(habitats, target_crs)

  habitats <- sf::st_crop(habitats, sf::st_bbox(tracks))
  qc <- dplyr::filter(east, NAME_1 == "Québec")
  coast <- sf::st_boundary(qc)

  tracks <- tracks |>
    dplyr::mutate(
      length_km = sf::st_length(geometry),
      length_km = units::set_units(length_km, "km")
    )

  gps_points <- gps_points |>
    dplyr::mutate(
      coast_distance = sf::st_distance(geometry, coast),
      coast_distance = units::set_units(coast_distance, "km")
    )

  coast_summary <- gps_points |>
    sf::st_drop_geometry() |>
    dplyr::group_by(Logger.ID) |>
    dplyr::summarise(
      mean_coast_distance_km = mean(coast_distance),
      .groups = "drop"
    )

  tracks <- dplyr::left_join(tracks, coast_summary, by = "Logger.ID")

  track_segments <- sf::st_intersection(tracks, habitats) |>
    dplyr::mutate(
      segment_km = sf::st_length(geometry),
      segment_km = units::set_units(segment_km, "km")
    )

  habitat_summary <- track_segments |>
    sf::st_drop_geometry() |>
    dplyr::group_by(Logger.ID) |>
    dplyr::summarise(
      crossed_habitats = dplyr::n(),
      total_km_in_habitats = sum(segment_km),
      mean_stemmean = stats::weighted.mean(STEMMEAN, units::drop_units(segment_km)),
      mean_tidemax = stats::weighted.mean(TIDEMAX, units::drop_units(segment_km)),
      mean_windmean = stats::weighted.mean(WINDMEAN, units::drop_units(segment_km)),
      .groups = "drop"
    )

  bathymetry <- stars::read_stars(
    system.file(
      "exdata",
      "MinganTelemetrie",
      "bathymetrie.tif",
      package = "workshop_r_spatial_eccc"
    )
  )
  bathymetry <- stars::st_warp(bathymetry, crs = sf::st_crs(tracks))
  bathymetry <- sf::st_crop(bathymetry, sf::st_bbox(tracks))

  bathymetry_mean <- stars::st_extract(bathymetry, tracks, FUN = mean)
  bathymetry_min <- stars::st_extract(bathymetry, tracks, FUN = min)
  segment_bathymetry <- stars::st_extract(bathymetry, track_segments, FUN = mean)

  tracks <- tracks |>
    dplyr::mutate(
      mean_bathymetry = bathymetry_mean[[1]],
      min_bathymetry = bathymetry_min[[1]]
    ) |>
    dplyr::left_join(habitat_summary, by = "Logger.ID")

  track_segments <- track_segments |>
    dplyr::mutate(segment_bathymetry = segment_bathymetry[[1]])

  segment_glm_data <- track_segments |>
    sf::st_drop_geometry() |>
    dplyr::mutate(segment_km_num = units::drop_units(segment_km))

  segment_glm <- stats::glm(
    segment_km_num ~ STEMMEAN + TIDEMAX + WINDMEAN + segment_bathymetry,
    data = segment_glm_data,
    family = stats::Gamma(link = "log")
  )

  gps_xy <- sf::st_coordinates(gps_points)
  track_bbox <- sf::st_bbox(tracks)

  tracks_kde <- MASS::kde2d(
    gps_xy[, 1],
    gps_xy[, 2],
    n = 100,
    h = c(5000, 5000),
    lims = c(track_bbox["xmin"], track_bbox["xmax"], track_bbox["ymin"], track_bbox["ymax"])
  )

  tracks_kde <- stars::st_as_stars(
    list(kde = tracks_kde$z),
    dimensions = stars::st_dimensions(x = tracks_kde$x, y = tracks_kde$y)
  ) |>
    sf::st_set_crs(target_crs)

  tracks_kde <- tracks_kde[sf::st_as_sfc(sf::st_bbox(tracks))]

  tmap::tmap_mode("plot")
  lines_map_tm <- tmap::tm_shape(bathymetry) +
    tmap::tm_raster(style = "cont", palette = "-Blues", title = "Bathymetry") +
    tmap::tm_shape(habitats) +
    tmap::tm_borders(col = "grey70") +
    tmap::tm_shape(tracks) +
    tmap::tm_lines(col = "#d95f02", lwd = 2) +
    tmap::tm_shape(gps_points) +
    tmap::tm_dots(col = "#1b9e77", size = 0.03)

  map_file <- file.path(
    output_dir,
    paste0("mingan_", gsub("[^A-Za-z0-9]+", "_", tolower(paste(logger_id, collapse = "_"))), ".png")
  )

  tmap::tmap_save(lines_map_tm, filename = map_file, width = 8, height = 6)

  list(
    lines = tracks,
    segments = track_segments,
    glm_summary = summary(segment_glm),
    kde = tracks_kde,
    map = map_file
  )
}
