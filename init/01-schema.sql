-- Base d'exercice opsdb : le parc informatique d'une entreprise.
-- Exécuté automatiquement au premier démarrage du conteneur, dans la base opsdb.
-- Les tables incident et audit_log sont créées plus tard, pendant les ateliers.

CREATE TABLE datacenter (
  id  int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom text NOT NULL UNIQUE
);
CREATE TABLE serveur (
  id            int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom           text NOT NULL UNIQUE,
  datacenter_id int  NOT NULL REFERENCES datacenter,
  specs         jsonb NOT NULL DEFAULT '{}'
);
CREATE TABLE application (
  id  int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom text NOT NULL UNIQUE
);
CREATE TABLE deploiement (
  serveur_id int  NOT NULL REFERENCES serveur,
  app_id     int  NOT NULL REFERENCES application,
  version    text NOT NULL,
  deploye_le timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (serveur_id, app_id)
);
CREATE TABLE dependance (
  app_id    int NOT NULL REFERENCES application,
  depend_de int NOT NULL REFERENCES application,
  PRIMARY KEY (app_id, depend_de)
);
CREATE TABLE mesure (
  serveur_id int NOT NULL,
  ts         timestamptz NOT NULL,
  metrique   text NOT NULL,
  valeur     double precision NOT NULL
);
