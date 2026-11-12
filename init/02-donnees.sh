#!/usr/bin/env bash
# Chargement des données d'opsdb. Exécuté au premier démarrage, après 01-schema.sql.
#
# MESURES fixe le nombre de lignes de la table mesure (1 000 000 par défaut).
# Pas de « set -u » : l'entrée de l'image source ce script quand il n'est pas
# exécutable (cas fréquent après un clonage sous Windows).
set -eo pipefail

MESURES="${MESURES:-1000000}"

lancer() {
  local nom="$1"
  local debut fin
  debut=$(date +%s)
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --quiet
  fin=$(date +%s)
  echo "[opsdb] ${nom} : $((fin - debut)) s"
}

echo "[opsdb] Chargement des données (MESURES=${MESURES})"

lancer "datacenters, serveurs, applications" <<EOSQL
    INSERT INTO datacenter (nom)
    VALUES ('Marseille'), ('Paris'), ('Lyon'), ('Lille'), ('Bordeaux');

    INSERT INTO serveur (nom, datacenter_id, specs)
    SELECT format('srv-%s', lpad(i::text, 4, '0')), 1 + i % 5,
           jsonb_build_object(
             'cpu',    (ARRAY[4, 8, 16, 32])[1 + i % 4],
             'ram_go', (ARRAY[16, 32, 64, 128])[1 + i % 4],
             'os',     (ARRAY['debian', 'ubuntu', 'rhel'])[1 + i % 3])
    FROM generate_series(1, 2000) AS i;

    INSERT INTO application (nom)
    SELECT 'app-' || i FROM generate_series(1, 150) AS i;
EOSQL

lancer "déploiements" <<EOSQL
    INSERT INTO deploiement (serveur_id, app_id, version, deploye_le)
    SELECT 1 + i % 2000, 1 + (i / 2000) % 150,
           format('%s.%s.%s', 1 + i % 3, i % 10, i % 7),
           now() - (i % 300) * interval '1 day'
    FROM generate_series(0, 49999) AS i;
EOSQL

lancer "dépendances" <<EOSQL
    INSERT INTO dependance
    VALUES (1, 2), (2, 3), (3, 4), (4, 5), (10, 11), (11, 12), (12, 13), (20, 21), (21, 22), (1, 30);
EOSQL

# ts croissant sur 90 jours : l'ordre physique suit le temps.
# La table n'a volontairement aucun index : l'atelier sur les plans
# d'exécution part de cette table nue.
lancer "mesures (${MESURES} lignes)" <<EOSQL
    INSERT INTO mesure
    SELECT 1 + (random() * 1999)::int,
           now() - interval '90 days' + i * (interval '90 days' / ${MESURES}),
           (ARRAY['cpu', 'ram', 'disque'])[1 + i % 3],
           round((random() * 100)::numeric, 2)
    FROM generate_series(1, ${MESURES}) AS i;
EOSQL

lancer "clé étrangère sur mesure" <<EOSQL
    ALTER TABLE mesure ADD FOREIGN KEY (serveur_id) REFERENCES serveur (id);
EOSQL

echo "[opsdb] Chargement terminé"
