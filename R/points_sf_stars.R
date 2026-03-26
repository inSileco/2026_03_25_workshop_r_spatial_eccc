#' Bird observations workflow wrapped in a function
#'
#' This function keeps the original workshop workflow for points, but wraps it
#' into a reusable function. It filters the bird observations to one or more species,
#' joins environmental context, fits a simple GLM, computes a KDE, and saves a
#' static `tmap`.
#'
#' @param species_name Species name(s) to keep from `sites.csv`.
#' @param output_dir Folder where the static map will be saved.
#'
#' @return A list with the filtered point data, the GLM summary, the KDE output,
#'   and the saved map path.
#'
#' @examples
#' birds <- oiseaux_boreaux(
#'   species_name = c("White-throated Sparrow", "Swainson's Thrush")
#' )
#'
#' birds$points
#' birds$glm_summary
#' birds$kde
#' birds$map
#' @export
oiseaux_boreaux <- function(species_name, output_dir = tempdir()) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  sites <- read.csv(
    system.file(
      "exdata",
      "SuiviOiseauxBoreauxQuebec",
      "sites.csv",
      package = "workshop_r_spatial_eccc"
    )
  ) |>
    dplyr::filter(year >= 2022) |>
    dplyr::filter(spNameEN %in% species_name) |>
    sf::st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

  east <- sf::st_read(
    system.file("exdata", "Basemap", "east.gpkg", package = "workshop_r_spatial_eccc"),
    quiet = TRUE
  )
  ecodistricts <- sf::st_read(
    system.file(
      "exdata",
      "SuiviOiseauxBoreauxQuebec",
      "ecodistricts.gpkg",
      package = "workshop_r_spatial_eccc"
    ),
    quiet = TRUE
  )
  rco <- sf::st_read(
    system.file(
      "exdata",
      "SuiviOiseauxBoreauxQuebec",
      "rco.gpkg",
      package = "workshop_r_spatial_eccc"
    ),
    quiet = TRUE
  )

  sites <- sf::st_transform(sites, 4326)
  east <- sf::st_transform(east, 4326)
  ecodistricts <- sf::st_transform(ecodistricts, 4326)
  rco <- sf::st_transform(rco, 4326)

  sites <- sf::st_filter(sites, east)
  ecodistricts <- sf::st_filter(ecodistricts, east)
  rco <- sf::st_filter(rco, east)
  qc <- dplyr::filter(east, NAME_1 == "Québec")

  ecodistricts <- ecodistricts |>
    sf::st_transform(32198) |>
    dplyr::mutate(
      area = sf::st_area(geom),
      area = units::set_units(area, "km^2")
    ) |>
    sf::st_transform(4326)

  rco <- rco |>
    sf::st_transform(32198) |>
    dplyr::mutate(
      area = sf::st_area(geom),
      area = units::set_units(area, "km^2")
    ) |>
    sf::st_transform(4326)

  coast <- sf::st_transform(qc, 32198) |>
    sf::st_boundary()

  sites <- sites |>
    sf::st_transform(32198) |>
    dplyr::mutate(
      coast_distance = sf::st_distance(geometry, coast),
      coast_distance = units::set_units(coast_distance, "km")
    ) |>
    sf::st_transform(4326)

  sites <- sf::st_join(
    sites,
    ecodistricts |>
      dplyr::select(ECODISTRIC, Name, ecodistricts_area_km2 = area)
  )

  sites <- sf::st_join(
    sites,
    rco |>
      dplyr::select(name_en, name_fr, rco_area_km2 = area)
  )

  temperature <- stars::read_stars(
    system.file(
      "exdata",
      "SuiviOiseauxBoreauxQuebec",
      "temperature_avg_worldclim.tif",
      package = "workshop_r_spatial_eccc"
    )
  )

  temperature_qc <- sf::st_crop(temperature, sf::st_bbox(qc))

  temperature_values <- stars::st_extract(temperature_qc, sites)[[1]] |>
    as.data.frame()
  names(temperature_values)[1:2] <- c("tavg_january", "tavg_august")

  sites <- dplyr::bind_cols(
    sites,
    temperature_values[, c("tavg_january", "tavg_august")]
  )

  presence_points <- sites |>
    dplyr::select(spNameEN, coast_distance, tavg_january, tavg_august) |>
    dplyr::mutate(presence = 1)

  pseudoabsence_points <- sf::st_sample(qc, size = nrow(presence_points), exact = TRUE) |>
    sf::st_sf(presence = 0, geometry = _)

  pseudoabsence_points <- pseudoabsence_points |>
    sf::st_transform(32198) |>
    dplyr::mutate(
      coast_distance = sf::st_distance(geometry, coast),
      coast_distance = units::set_units(coast_distance, "km")
    ) |>
    sf::st_transform(4326)

  pseudoabsence_values <- stars::st_extract(temperature_qc, pseudoabsence_points)[[1]] |>
    as.data.frame()
  names(pseudoabsence_values)[1:2] <- c("tavg_january", "tavg_august")

  pseudoabsence_points <- dplyr::bind_cols(
    pseudoabsence_points,
    pseudoabsence_values[, c("tavg_january", "tavg_august")]
  )

  points_glm_data <- dplyr::bind_rows(
    presence_points,
    pseudoabsence_points |>
      dplyr::mutate(spNameEN = "Pseudo-absence") |>
      dplyr::select(spNameEN, presence, coast_distance, tavg_january, tavg_august)
  ) |>
    dplyr::mutate(coast_distance_km = units::drop_units(coast_distance))

  points_glm <- stats::glm(
    presence ~ tavg_january + tavg_august + coast_distance_km,
    data = points_glm_data,
    family = stats::binomial()
  )

  focal_points <- sf::st_transform(sites, 32198)
  focal_xy <- sf::st_coordinates(focal_points)
  qc_qc <- sf::st_transform(qc, 32198)
  qc_bbox <- sf::st_bbox(qc_qc)

  points_kde <- MASS::kde2d(
    focal_xy[, 1],
    focal_xy[, 2],
    n = 100,
    h = c(100000, 100000),
    lims = c(qc_bbox["xmin"], qc_bbox["xmax"], qc_bbox["ymin"], qc_bbox["ymax"])
  )

  points_kde <- stars::st_as_stars(
    list(kde = points_kde$z),
    dimensions = stars::st_dimensions(x = points_kde$x, y = points_kde$y)
  ) |>
    sf::st_set_crs(32198)

  points_kde <- points_kde[qc_qc]

  tmap::tmap_mode("plot")
  points_map_tm <- tmap::tm_shape(temperature_qc[[2]]) +
    tmap::tm_raster(
      style = "cont",
      palette = "-viridis",
      title = "August mean temperature"
    ) +
    tmap::tm_shape(qc) +
    tmap::tm_borders(col = "grey30") +
    tmap::tm_shape(sites) +
    tmap::tm_dots(col = "spNameEN", palette = "Set2", size = 0.05, title = "Species")

  map_file <- file.path(
    output_dir,
    paste0("oiseaux_boreaux_", gsub("[^A-Za-z0-9]+", "_", tolower(paste(species_name, collapse = "_"))), ".png")
  )

  tmap::tmap_save(points_map_tm, filename = map_file, width = 8, height = 6)

  list(
    points = sites,
    glm_summary = summary(points_glm),
    kde = points_kde,
    map = map_file
  )
}
