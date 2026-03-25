# Manuel du participant

*english follows*

Ce dépôt contient le matériel d'exercices pratiques de l'atelier. L'objectif
est de vous aider à utiliser R comme un SIG pratique : importer des données
spatiales, les inspecter, les transformer, combiner des couches vectorielles
et raster, extraire des valeurs, construire des analyses simples et produire
des cartes.

Les exercices sont cumulatifs. Choisissez un parcours et un outil, puis
progressez dans les fichiers dans l'ordre.

## Ce Sur Quoi Vous Allez Travailler

Deux contextes d'étude sont utilisés dans l'atelier.

- Parcours points :
  des relevés d'observations d'oiseaux au Québec, avec des localisations
  ponctuelles, des écodistricts, des polygones de RCO et des rasters de
  température.
- Parcours lignes :
  des localisations de télémétrie et des trajets reconstruits, avec des
  polygones d'habitat et des rasters de bathymétrie.

Vous n'avez pas besoin de comprendre tous les détails des jeux de données avant
de commencer. Ce qui compte, c'est le rôle de chaque couche :

- points ou lignes : les observations ou les déplacements
- polygones : les unités de référence ou les zones d'étude
- rasters : les surfaces environnementales

## Choisissez Votre Parcours

Il existe deux parcours de travail.

- Parcours points :
  le parcours par défaut, plus simple; recommandé si vous voulez le chemin le
  plus clair à travers l'atelier.
- Parcours lignes :
  le parcours plus avancé; recommandé si vous êtes à l'aise avec un rythme un
  peu plus soutenu et voulez travailler avec la reconstruction de lignes et
  l'extraction le long de lignes.

Vous pouvez aussi faire les deux si le temps le permet.

## Choisissez Votre Outil

Il existe deux écosystèmes de paquets.

- `sf/stars` :
  utilisez `sf` pour les données vectorielles et `stars` pour les données
  raster.
- `terra` :
  utilisez `terra` pour les flux vectoriels et raster.

Restez dans un seul écosystème pendant un parcours. Les fichiers d'exercices
présentent clairement les deux options, mais vous n'avez qu'à compléter la
section correspondant à votre choix.

## Séquence Des Exercices

Parcourez les fichiers dans cet ordre.

1. `01_vector_foundations.R`
   Importer les données, créer des objets spatiaux, inspecter le CRS, exporter
   les résultats.
2. `02_early_mapping_and_lines.R`
   Cartographier rapidement les données; dans le parcours lignes, reconstruire
   les trajets à partir de points ordonnés.
3. `03_vector_operations.R`
   Restreindre, mesurer, joindre, intersecter et tamponner des données
   vectorielles.
4. `04_raster_foundations.R`
   Importer, inspecter, exporter et visualiser rapidement des rasters.
5. `05_raster_operations.R`
   Rogner, projeter, masquer et manipuler des rasters.
6. `06_integrated_workflows.R`
   Extraire des valeurs raster et construire des tableaux de synthèse.
7. `07_spatial_analytics_glm.R`
   Préparer des tableaux d'analyse et ajuster un GLM simple.
8. `08_spatial_analytics_kde.R`
   Exercice avancé optionnel sur l'estimation de densité par noyau.
9. `09_advanced_mapping.R`
   Exercice avancé optionnel sur des cartes de qualité publication.

## Parcours Recommandés

Si vous voulez un parcours simple à travers l'atelier :

- faites les exercices 1 à 7 dans le parcours points
- traitez les exercices 8 et 9 comme optionnels

Si vous voulez le parcours plus avancé :

- faites les exercices 1 à 7 dans le parcours lignes
- traitez les exercices 8 et 9 comme optionnels

Si vous avancez rapidement :

- complétez d'abord un parcours complet
- passez ensuite seulement à l'autre parcours

## Comment Utiliser Les Fichiers D'Exercices

- Ouvrez un seul fichier d'exercice à la fois.
- Repérez la section correspondant à votre parcours et à votre choix de
  paquet.
- Ignorez les autres sections.
- Complétez les étapes `TODO` directement dans le fichier ou dans votre propre
  copie de travail.
- Gardez les objets créés dans les exercices précédents disponibles, car les
  exercices suivants s'appuient sur eux.

Les fichiers sont conçus pour accompagner la progression de l'atelier, pas
pour un usage indépendant dans un ordre aléatoire.

## Ce Qui Est Essentiel Et Ce Qui Est Optionnel

Matériel essentiel de l'atelier :

- importation et inspection de vecteurs
- cartographie rapide
- gestion des CRS
- opérations vectorielles
- importation et opérations raster
- extraction raster
- synthèses simples et GLM

Matériel optionnel ou d'approfondissement :

- GLM avec pseudo-absences
- KDE
- cartographie avancée

Si vous prenez du retard, restez d'abord sur le parcours essentiel.

## Style De Travail Pendant L'Atelier

- Cartographiez tôt, même avec des tracés rapides et sommaires.
- Vérifiez le CRS avant de mesurer ou de superposer des couches.
- Gardez un flux de travail lisible et progressif.
- Demandez de l'aide lorsqu'un choix de parcours ou de paquet devient bloquant.

L'objectif n'est pas de terminer tous les exercices. L'objectif est de
comprendre suffisamment bien le flux de travail pour pouvoir le réutiliser
après l'atelier.

---

# Participant Manual

This repository contains the hands-on exercise material for the workshop. The goal
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
