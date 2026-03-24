# Participant Manual

This folder contains the hands-on exercise material for the workshop. The goal
is to help you use R as a practical GIS: import spatial data, inspect it,
transform it, combine vector and raster layers, extract values, build simple
analyses, and make maps.

The exercises are cumulative. Pick one route and one tool, then move through
the files in order.

## What You Will Work With

Two study contexts are used in the workshop.

- Points route:
  bird observation records in Quebec, with point locations, ecodistricts, RCO
  polygons, and temperature rasters.
- Lines route:
  telemetry locations and reconstructed tracks, with habitat polygons and
  bathymetry rasters.

You do not need to understand every detail of the datasets before starting.
What matters is the role of each layer:

- points or lines: the observations or movements
- polygons: reference units or study areas
- rasters: environmental surfaces

## Choose Your Route

There are two workflow routes.

- Points route:
  the simpler default route; recommended if you want the clearest path through
  the workshop.
- Lines route:
  the more advanced route; recommended if you are comfortable moving a bit
  faster and want to work with line reconstruction and line-based extraction.

You can also do both if time allows.

## Choose Your Tool

There are two package ecosystems.

- `sf/stars`:
  use `sf` for vector data and `stars` for raster data.
- `terra`:
  use `terra` for both vector and raster workflows.

Stay in one ecosystem while working through a route. The exercise files show
both options clearly, but you only need to complete the section that matches
your choice.

## Exercise Sequence

Work through the files in this order.

1. `01_vector_foundations.R`
   Import data, create spatial objects, inspect CRS, export outputs.
2. `02_early_mapping_and_lines.R`
   Map data quickly; in the lines route, rebuild tracks from ordered points.
3. `03_vector_operations.R`
   Subset, measure, join, intersect, and buffer vector data.
4. `04_raster_foundations.R`
   Import, inspect, export, and quickly visualize rasters.
5. `05_raster_operations.R`
   Crop, project, mask, and manipulate rasters.
6. `06_integrated_workflows.R`
   Extract raster values and build summary tables.
7. `07_spatial_analytics_glm.R`
   Prepare analysis tables and fit a simple GLM.
8. `08_spatial_analytics_kde.R`
   Optional advanced exercise on kernel density estimation.
9. `09_advanced_mapping.R`
   Optional advanced exercise on communication-quality maps.

## Recommended Paths

If you want a straightforward route through the workshop:

- do Exercises 1 to 7 in the points route
- treat Exercises 8 and 9 as optional

If you want the more advanced route:

- do Exercises 1 to 7 in the lines route
- treat Exercises 8 and 9 as optional

If you work quickly:

- complete one full route first
- only then switch to the other route

## How To Use The Exercise Files

- Open one exercise file at a time.
- Find the section for your route and your package choice.
- Ignore the other sections.
- Complete the `TODO` steps directly in the file or in your own working copy.
- Keep objects from earlier exercises available, because later exercises build
  on them.

The files are written to support workshop progression, not independent use in a
random order.

## What Is Core And What Is Optional

Core workshop material:

- vector import and inspection
- quick mapping
- CRS handling
- vector operations
- raster import and operations
- raster extraction
- simple summaries and GLMs

Optional or stretch material:

- pseudo-absence GLM work
- KDE
- advanced mapping

If you fall behind, stay with the core path first.

## Working Style During The Workshop

- Map early, even with quick rough plots.
- Check CRS before measuring or overlaying.
- Keep your workflow readable and stepwise.
- Ask for help when a route or package choice becomes a blocker.

The objective is not to finish every exercise. The objective is to understand
the workflow well enough to reuse it after the workshop.
