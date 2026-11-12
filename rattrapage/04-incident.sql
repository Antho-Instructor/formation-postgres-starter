-- Rattrapage de la quête 04 : crée la table incident et charge son historique.
-- À utiliser seulement si vous n'avez pas pu terminer la quête 04 :
-- les quêtes 08 et 09 ont besoin de cette table.
-- Attention : une table incident existante est supprimée et remplacée.

\echo 'Rattrapage : table incident...'

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS incident CASCADE;
DROP TYPE IF EXISTS gravite_incident CASCADE;

CREATE TYPE gravite_incident AS ENUM ('mineure', 'majeure', 'critique');

CREATE TABLE incident (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  serveur_id  int NOT NULL REFERENCES serveur,
  gravite     gravite_incident NOT NULL,
  description text NOT NULL,
  periode     tstzrange NOT NULL,
  CONSTRAINT incident_periode_valide
    CHECK (NOT isempty(periode) AND NOT lower_inf(periode)),
  CONSTRAINT incident_sans_chevauchement
    EXCLUDE USING gist (serveur_id WITH =, periode WITH &&)
);

INSERT INTO incident (serveur_id, gravite, description, periode)
SELECT s.id,
       (ARRAY['mineure', 'majeure', 'critique']::gravite_incident[])[1 + (s.id + n) % 3],
       'Incident n°' || n || ' sur ' || s.nom,
       tstzrange(d.debut, d.debut + make_interval(mins => 15 + ((s.id * n) % 600)))
FROM serveur s
CROSS JOIN generate_series(1, 10) AS n
CROSS JOIN LATERAL (
  SELECT timestamptz '2025-11-01'
         + (n * 36 + s.id % 30) * interval '1 day'
         + (s.id % 24) * interval '1 hour' AS debut
) d;

ANALYZE incident;

\echo 'Table incident prête.'
