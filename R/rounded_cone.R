#' Create a rounded cone polygon from a point
#'
#' Builds a cone-shaped polygon from a single point using a range, a bearing,
#' and an opening angle. The cone has curved sides and a rounded cap.
#'
#' @param pt A single point as an `sf` or `sfc_POINT` object.
#' @param range_m Cone length in map units.
#' @param bearing_deg Bearing in degrees.
#' @param opening_deg Opening angle in degrees.
#' @param n_side Number of points used to draw each side.
#' @param n_cap Number of points used to draw the rounded cap.
#' @param side_power Controls how quickly the cone widens.
#'
#' @return An `sfc_POLYGON` object.
#'
#' @examples
#' pt <- sf::st_sfc(sf::st_point(c(0, 0)), crs = 32198)
#'
#' cone <- make_rounded_cone(
#'   pt = pt,
#'   range_m = 1000,
#'   bearing_deg = 45,
#'   opening_deg = 30
#' )
#'
#' plot(cone)
#' plot(pt, add = TRUE, pch = 16)
#' @export
make_rounded_cone <- function(
  pt,
  range_m,
  bearing_deg,
  opening_deg,
  n_side = 40,
  n_cap = 40,
  side_power = 0.7
) {
  geom <- if (inherits(pt, "sfc_POINT")) pt else sf::st_geometry(pt)
  stopifnot(length(geom) == 1)

  crs <- sf::st_crs(geom)
  xy <- sf::st_coordinates(geom)[1, c("X", "Y")]

  half_w <- range_m * tan((opening_deg / 2) * pi / 180)

  t <- seq(0, 1, length.out = n_side)

  y_side <- range_m * t
  x_left <- -half_w * (t^side_power)
  x_right <- half_w * (t^side_power)

  theta <- seq(pi, 0, length.out = n_cap)
  x_cap <- half_w * cos(theta)
  y_cap <- range_m + half_w * sin(theta)

  coords_local <- rbind(
    c(0, 0),
    cbind(x_left[-1], y_side[-1]),
    cbind(x_cap, y_cap),
    cbind(rev(x_right[-1]), rev(y_side[-1])),
    c(0, 0)
  )

  a <- bearing_deg * pi / 180
  rot <- matrix(
    c(cos(a), -sin(a),
      sin(a), cos(a)),
    nrow = 2,
    byrow = TRUE
  )

  coords_rot <- coords_local %*% rot

  coords_final <- cbind(
    coords_rot[, 1] + xy[1],
    coords_rot[, 2] + xy[2]
  )

  sf::st_sfc(sf::st_polygon(list(coords_final)), crs = crs)
}
