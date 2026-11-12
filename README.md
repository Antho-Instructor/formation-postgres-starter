# Formation PostgreSQL · Développement

Votre environnement de travail pour les deux jours : un serveur PostgreSQL 18 dans Docker, avec la base d'exercice **opsdb** déjà chargée. Les énoncés des ateliers sont sur la plateforme de la formation ; ce dépôt contient l'environnement, des mémos et un filet de sécurité.

## Prérequis

- Docker Desktop (Windows, macOS) ou Docker Engine avec le plugin Compose (Linux) : la commande est `docker compose`, pas l'ancien `docker-compose`.
- 4 Go de RAM et 3 Go d'espace disque libres.
- Le port 5432 libre sur votre poste. Sinon, voir « Problèmes courants ».

## Démarrer

```bash
docker compose up -d --wait
```

Le premier démarrage construit l'image puis charge la base : comptez 2 à 3 minutes. Les démarrages suivants sont immédiats, car les données sont conservées dans un volume Docker.

Vérifiez ensuite que tout est prêt (Linux, macOS ou Git Bash sous Windows) :

```bash
./scripts/verifier.sh
```

## Se connecter

**Avec psql, dans le conteneur** (rien à installer sur votre poste) :

```bash
docker compose exec db psql -U postgres -d opsdb
```

Le raccourci `./scripts/psql.sh` fait la même chose.

**Avec un outil installé sur votre poste** (psql, DBeaver, pgAdmin, l'extension de votre éditeur) :

| Paramètre | Valeur |
|---|---|
| Hôte | `localhost` |
| Port | `5432` |
| Base | `opsdb` |
| Utilisateur | `postgres` |
| Mot de passe | `formation` |

Soit, en une ligne : `postgresql://postgres:formation@localhost:5432/opsdb`

## La base opsdb

Elle simule le parc informatique d'une entreprise. Vous êtes l'équipe qui le gère.

| Table | Lignes | Contenu |
|---|---|---|
| `datacenter` | 5 | Marseille, Paris, Lyon, Lille, Bordeaux |
| `serveur` | 2 000 | Nom, datacenter, caractéristiques en JSONB (`cpu`, `ram_go`, `os`) |
| `application` | 150 | Les applications du parc |
| `deploiement` | 50 000 | Quelle version de quelle application tourne sur quel serveur |
| `dependance` | 10 | Quelle application dépend de quelle autre |
| `mesure` | 1 000 000 | Supervision sur 90 jours : CPU, RAM, disque. Aucun index, volontairement |

Les tables `incident` et `audit_log` s'ajouteront pendant les ateliers.

### Changer le volume de mesures

Le nombre de lignes de `mesure` se règle avec la variable `MESURES`, lue au premier démarrage uniquement. Copiez `.env.example` en `.env`, modifiez la valeur, puis repartez de zéro :

| `MESURES` | Usage |
|---|---|
| `200000` | Poste très peu puissant |
| `1000000` | Valeur par défaut, celle des ateliers |
| `10000000` | Pour sentir vraiment l'effet des index : chargement de 30 s à 2 min |

## Ce que contient le dépôt

```
formation_postgres_base/
├── compose.yaml        le serveur PostgreSQL 18
├── docker/Dockerfile   l'image officielle, avec PL/Python en plus
├── init/               le chargement d'opsdb au premier démarrage
├── memos/              aide-mémoires : psql, EXPLAIN, PL/pgSQL
├── rattrapage/         l'état attendu après certaines quêtes
├── scripts/            psql, vérification, remise à zéro, rattrapage
└── travail/            vos fichiers, partagés avec le conteneur
```

## Les mémos

- [memos/psql.md](memos/psql.md) : les méta-commandes et un `.psqlrc` confortable.
- [memos/explain.md](memos/explain.md) : lire un plan d'exécution et choisir un index.
- [memos/plpgsql.md](memos/plpgsql.md) : la syntaxe PL/pgSQL, la volatilité, les triggers.

## Votre dossier de travail

Le dossier `travail/` est partagé avec le conteneur, où il apparaît sous `/travail`. Rangez-y vos scripts et relancez-les depuis psql avec `\i /travail/mon-script.sql`.

## Les scripts

```bash
./scripts/psql.sh          # ouvre psql sur opsdb
./scripts/verifier.sh      # vérifie l'environnement : version, données, extensions
./scripts/reset.sh         # repart d'une base neuve (demande confirmation)
./scripts/rattrapage.sh    # liste les rattrapages disponibles
./scripts/rattrapage.sh 04 # applique le rattrapage de la quête 04
```

Sous Windows sans Git Bash, les commandes `docker compose` de ce README suffisent.

## Le rattrapage

Une seule quête laisse un état dont les suivantes ont besoin : la **quête 04** crée la table `incident`, utilisée par les quêtes 08 et 09. Si vous n'avez pas pu la terminer :

```bash
./scripts/rattrapage.sh 04
```

Ou, sans bash : `docker compose exec -T db psql -U postgres -d opsdb < rattrapage/04-incident.sql`

## Repartir de zéro

```bash
docker compose down -v
docker compose up -d --wait
```

## Arrêter

```bash
docker compose stop     # arrête le serveur, garde les données
docker compose down -v  # supprime le serveur et les données
```

## Problèmes courants

**Le port 5432 est déjà utilisé.** Un autre PostgreSQL tourne sur votre poste. Copiez `.env.example` en `.env`, mettez `PG_PORT=5433`, puis relancez `docker compose up -d --wait`. Utilisez ce port dans vos outils.

**Les tables n'existent pas.** Le chargement ne s'exécute qu'au tout premier démarrage, sur un volume vide. Si un démarrage a été interrompu, repartez de zéro.

**La base semble vide ou étrange après une mise à jour de l'image.** Le volume a été créé par une autre version majeure de PostgreSQL, dont le format sur disque n'est pas compatible. Repartez de zéro.

**`could not resize shared memory segment`.** La mémoire partagée du conteneur est insuffisante pour une requête parallèle. Elle est fixée à 256 Mo dans `compose.yaml` (`shm_size`) : augmentez-la.

**La construction de l'image échoue derrière un proxy d'entreprise.** Docker doit connaître le proxy pour télécharger l'image et le paquet PL/Python. Configurez-le dans Docker Desktop (Settings, Resources, Proxies) ou signalez-le à votre formateur.

**Voir ce que fait le serveur :**

```bash
docker compose logs -f db
```

Le chargement initial affiche la durée de chaque étape, préfixée par `[opsdb]`.
