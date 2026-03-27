# Exercice 09 - Corrigé Cartographie avancée

# -------------------------------------------------------------------------
# Parcours points + sf / stars
# -------------------------------------------------------------------------

library(ggplot2)
library(stars)
library(sf)

points_map <- ggplot() +
  geom_stars(data = temperature_qc[, , , 2], downsample = 8) +
  scale_fill_viridis_c(name = "August mean temperature") +
  geom_sf(data = qc, fill = NA, color = "grey30", linewidth = 0.4) +
  geom_sf(data = sites, aes(color = spNameEN), alpha = 0.7, size = 0.9) +
  labs(
    title = "Bird observations and summer temperature",
    subtitle = "Points workflow with sf + stars",
    color = "Species"
  ) +
  theme_minimal()

ggsave(file.path(output_dir, "points_sf_ex09_map.png"), points_map, width = 10, height = 7, dpi = 300)
st_write(sites, file.path(output_dir, "sites.gpkg"), delete_dsn = TRUE, quiet = TRUE)
write.csv(species_summary, file.path(output_dir, "sites_species_summary.csv"), row.names = FALSE)
write.csv(ecodistrict_summary, file.path(output_dir, "sites_ecodistrict_summary.csv"), row.names = FALSE)
write.csv(rco_summary, file.path(output_dir, "sites_rco_summary.csv"), row.names = FALSE)


# -------------------------------------------------------------------------
# Parcours points + terra
# -------------------------------------------------------------------------

library(tmap)

tmap_mode("plot")
points_map_tm <- tm_shape(temperature_qc[[2]]) +
  tm_raster(style = "cont", palette = "-viridis", title = "August mean temperature") +
  tm_shape(qc) +
  tm_borders(col = "grey30") +
  tm_shape(sites) +
  tm_dots(col = "spNameEN", palette = "Set2", size = 0.05, title = "Species")

tmap_save(points_map_tm, file.path(output_dir, "points_terra_ex09_map.png"), width = 10, height = 7, dpi = 300)
writeVector(sites, file.path(output_dir, "sites_terra.gpkg"), overwrite = TRUE)
write.csv(species_summary, file.path(output_dir, "sites_terra_species_summary.csv"), row.names = FALSE)
write.csv(ecodistrict_summary, file.path(output_dir, "sites_terra_ecodistrict_summary.csv"), row.names = FALSE)
write.csv(rco_summary, file.path(output_dir, "sites_terra_rco_summary.csv"), row.names = FALSE)


# -------------------------------------------------------------------------
# Parcours lignes + sf / stars
# -------------------------------------------------------------------------

library(ggplot2)
library(stars)
library(sf)

tracks_map <- ggplot() +
  geom_stars(data = bathymetry) +
  scale_fill_viridis_c(name = "Bathymetry") +
  geom_sf(data = habitats, fill = NA, color = "grey70", linewidth = 0.3) +
  geom_sf(data = tracks, aes(color = Logger.ID), linewidth = 0.9) +
  labs(
    title = "Telemetry tracks, habitats, and bathymetry",
    subtitle = "Lines workflow with sf + stars",
    color = "Logger"
  ) +
  theme_minimal()

ggsave(file.path(output_dir, "lines_sf_ex09_map.png"), tracks_map, width = 10, height = 7, dpi = 300)
st_write(tracks, file.path(output_dir, "telemetry_tracks_sf.gpkg"), delete_dsn = TRUE, quiet = TRUE)
write.csv(track_summary, file.path(output_dir, "telemetry_track_summary_sf.csv"), row.names = FALSE)


# -------------------------------------------------------------------------
# Parcours lignes + terra
# -------------------------------------------------------------------------

library(tmap)

tmap_mode("plot")
tracks_map_tm <- tm_shape(bathymetry) +
  tm_raster(style = "cont", palette = "-Blues", title = "Bathymetry") +
  tm_shape(habitats) +
  tm_borders(col = "grey70") +
  tm_shape(tracks) +
  tm_lines(col = "Logger.ID", lwd = 2, title.col = "Logger")

tmap_save(tracks_map_tm, file.path(output_dir, "lines_terra_ex09_map.png"), width = 10, height = 7, dpi = 300)
writeVector(tracks, file.path(output_dir, "telemetry_tracks.gpkg"), overwrite = TRUE)
write.csv(track_summary, file.path(output_dir, "telemetry_track_summary.csv"), row.names = FALSE)
