# 2026_03_25_workshop_r_spatial_eccc

Materiel pratique pour l'atelier ECCC sur les outils et analyses spatiales en R.

## Principe pedagogique

Le fil conducteur repose sur deux scripts paralleles:

- `scripts/01_points_sf_stars.R`: workflow centres sur des observations ponctuelles avec `sf` et `stars`
- `scripts/02_lines_terra.R`: workflow centres sur des trajectoires ou lignes de mouvement avec `terra`

Les deux scripts doivent repondre a une question analytique tres proche:

- ou sont les oiseaux par rapport aux unites spatiales de reference
- quelles conditions environnementales sont associees aux observations ou deplacements
- comment resumer et communiquer ces resultats avec des cartes et tableaux simples

L'objectif n'est pas une symetrie parfaite des operations, mais une symetrie de structure:

1. importer
2. verifier et transformer les CRS
3. manipuler les geometres et attributs
4. visualiser rapidement
5. croiser avec des polygones
6. lire et manipuler des rasters
7. extraire de l'information environnementale
8. calculer une metrique spatiale
9. produire un resume analytique
10. produire une figure finale et exporter les resultats

## Utilisation dans l'atelier

Chaque script complet doit ensuite etre fragmente en petits exercices.

### Jour 1

- import/export des donnees spatiales
- creation d'objets spatiaux
- inspection des geometres et des CRS
- transformations et manipulations de base
- visualisation rapide avec `plot()` et `mapview()`
- introduction aux rasters avec lecture, projection, decoupage et affichage

### Jour 2

- croisement vectoriel plus pousse
- extraction raster sur points, polygones ou lignes
- calculs de distance, longueur, aire ou proportion
- syntheses spatiales par unite d'analyse
- analyse simple, par exemple un modele lineaire ou une densite
- visualisation finale plus propre et plus interpretable

## Decoupage recommande en exercices

### Script 1: points avec `sf` et `stars`

- Exercice 1: importer les observations ponctuelles et les polygones de reference
- Exercice 2: inspecter les CRS, transformer et filtrer les donnees
- Exercice 3: faire une jointure spatiale points-vers-polygones
- Exercice 4: lire un raster, le recadrer et l'afficher
- Exercice 5: extraire des valeurs raster aux points
- Exercice 6: calculer une distance ou creer des buffers
- Exercice 7: resumer les observations par polygone ou par espece
- Exercice 8: produire une carte finale et exporter un tableau

### Script 2: lignes avec `terra`

- Exercice 1: importer des lignes de deplacement et les couches de contexte
- Exercice 2: inspecter les CRS, transformer et filtrer les trajectoires
- Exercice 3: croiser les lignes avec des polygones
- Exercice 4: lire un raster, le recadrer, le masquer et l'afficher
- Exercice 5: extraire des valeurs raster le long des lignes ou de buffers de lignes
- Exercice 6: calculer des longueurs, distances ou proportions par unite
- Exercice 7: resumer les trajectoires par individu, annee ou polygone
- Exercice 8: produire une carte finale et exporter un tableau

## Fichiers de travail

- [scripts/script.R](/Users/davidbeauchesne/DB/inSileco/spatial/2026_03_25_workshop_r_spatial_eccc/scripts/script.R): index leger qui pointe vers les deux workflows
- [scripts/01_points_sf_stars.R](/Users/davidbeauchesne/DB/inSileco/spatial/2026_03_25_workshop_r_spatial_eccc/scripts/01_points_sf_stars.R): squelette complet pour le workflow points
- [scripts/02_lines_terra.R](/Users/davidbeauchesne/DB/inSileco/spatial/2026_03_25_workshop_r_spatial_eccc/scripts/02_lines_terra.R): squelette complet pour le workflow lignes

## Note sur les donnees

Le choix final des jeux de donnees peut encore changer. Les scripts sont donc ecrits comme des squelettes analytiques:

- les objets a importer sont identifies par role analytique
- les sections de code sont deja ordonnees
- les endroits ou inserer les jeux de donnees finaux sont indiques clairement

Quand les donnees finales seront confirmees, on pourra transformer ces squelettes en scripts d'instructeur puis en versions a trous pour les participants.
