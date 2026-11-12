# Mémo EXPLAIN

## Lancer un plan

```sql
EXPLAIN SELECT ...;                               -- plan estimé, sans exécuter
EXPLAIN ANALYZE SELECT ...;                       -- exécute, ajoute les temps et lignes réels
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;            -- ajoute les pages lues (par défaut depuis la 18)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT ...; -- à coller dans explain.dalibo.com
```

`EXPLAIN ANALYZE` exécute vraiment la requête. Sur un `UPDATE` ou un `DELETE`, encadrez-le :

```sql
BEGIN;
EXPLAIN ANALYZE DELETE FROM mesure WHERE ts < now() - interval '80 days';
ROLLBACK;
```

## Lire un nœud

Le plan est un arbre : les nœuds les plus indentés s'exécutent en premier, leurs lignes remontent vers le parent.

```
Nœud  (cost=démarrage..total rows=estimées width=octets)
      (actual time=démarrage..total rows=réelles loops=exécutions)
```

- **cost** : une unité arbitraire, pas des millisecondes. Sert à comparer des plans entre eux.
- **rows** estimé contre **rows** réel : un gros écart signale des statistiques périmées ou des colonnes corrélées (`ANALYZE`, `CREATE STATISTICS`).
- **loops** : nombre d'exécutions du nœud. Les temps affichés sont par exécution : multipliez par `loops`.
- **Rows Removed by Filter** : lignes lues pour rien. Un grand nombre sur une grande table appelle un index.

## Les nœuds courants

| Nœud | Signification |
|---|---|
| `Seq Scan` | Lecture complète de la table. Normal sur une petite table ou un filtre peu sélectif |
| `Parallel Seq Scan` + `Gather` | Lecture complète, partagée entre plusieurs processus |
| `Index Scan` | Parcours de l'index, puis lecture de la table pour chaque ligne |
| `Index Only Scan` | Tout est dans l'index. Surveillez `Heap Fetches` |
| `Bitmap Index Scan` + `Bitmap Heap Scan` | Liste les pages à lire, puis les lit dans l'ordre du disque |
| `Nested Loop` | Pour chaque ligne d'un côté, cherche dans l'autre. Bien si le premier côté est petit |
| `Hash Join` | Table de hachage sur un côté, puis lecture de l'autre. Bien pour de gros volumes |
| `Merge Join` | Fusion de deux entrées déjà triées |
| `Sort` | Tri. `external merge` dans `Sort Method` = tri sur disque, `work_mem` trop petit |
| `HashAggregate` / `GroupAggregate` | Calcul d'agrégats |

## Buffers

```
Buffers: shared hit=120 read=34
```

- **hit** : pages trouvées dans le cache de PostgreSQL (`shared_buffers`).
- **read** : pages demandées au système de fichiers.
- Comparez les Buffers avant et après un index : c'est plus stable que le temps, qui dépend du cache.

## Heap Fetches

```
Index Only Scan using ...  Heap Fetches: 128
```

Lignes pour lesquelles l'index n'a pas suffi : la carte de visibilité ne garantissait pas que la ligne était visible par tous. Un `VACUUM` fait en général tomber ce nombre à zéro.

## Quel index ?

| Besoin | Index |
|---|---|
| Égalité, plage, tri | B-tree (par défaut) |
| Plusieurs colonnes | B-tree multicolonne : égalité d'abord, plage ensuite |
| `jsonb` avec `@>`, tableaux | GIN |
| Grande table dont l'ordre physique suit la valeur (horodatage d'insertion) | BRIN |
| Intervalles, chevauchements, géométrie | GiST |
| Une partie seulement des lignes | Index partiel : `CREATE INDEX ... WHERE ...` |
| Éviter la lecture de la table | Index couvrant : `CREATE INDEX ... INCLUDE (...)` |
