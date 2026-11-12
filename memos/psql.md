# Mémo psql

## Explorer

| Commande | Usage |
|---|---|
| `\l` | Lister les bases |
| `\c nom_base` | Se connecter à une autre base |
| `\dt` / `\dt+` | Lister les tables (avec leur taille) |
| `\d nom_table` | Décrire une table : colonnes, index, contraintes, triggers |
| `\d+ nom_table` | Idem, avec le stockage et les statistiques |
| `\di` / `\di+` | Lister les index (avec leur taille) |
| `\dv` | Lister les vues |
| `\df` | Lister les fonctions et procédures |
| `\dn` | Lister les schémas |
| `\du` | Lister les rôles |
| `\dx` | Lister les extensions installées |
| `\dp nom_table` | Afficher les droits sur une table |
| `\conninfo` | Afficher la connexion courante |

## Exécuter et afficher

| Commande | Usage |
|---|---|
| `\timing on` | Afficher le temps de chaque requête |
| `\x auto` | Affichage vertical quand la ligne est trop large |
| `\watch 2` | Relancer la dernière requête toutes les 2 secondes (Ctrl+C pour arrêter) |
| `\i fichier.sql` | Exécuter un fichier SQL |
| `\e` | Ouvrir la dernière requête dans un éditeur |
| `\gset` | Ranger le résultat d'une requête dans des variables psql |
| `\copy` | Import et export côté client, sur une seule ligne, sans point-virgule |
| `\! commande` | Lancer une commande shell |

## Aide

| Commande | Usage |
|---|---|
| `\?` | Toutes les méta-commandes |
| `\h CREATE INDEX` | La syntaxe d'une commande SQL |

## Un .psqlrc confortable

À placer dans `~/.psqlrc` sur la machine qui lance psql :

```
\set QUIET 1
\pset null '∅'
\x auto
\timing on
\set PROMPT1 '%n@%/%R%# '
\set HISTSIZE 5000
\unset QUIET
```

`\pset null` distingue une chaîne vide d'une vraie valeur NULL à l'affichage.
