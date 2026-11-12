#!/usr/bin/env bash
# Vérifie que l'environnement est prêt pour la formation.
# À lancer après le premier démarrage, ou quand quelque chose semble anormal.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echec=0

requete() {
  docker compose exec -T db psql -U postgres -d opsdb -X -tA -c "$1"
}

ok()     { echo "  [OK]     $1"; }
erreur() { echo "  [ERREUR] $1"; echec=1; }

echo "Vérification de l'environnement"

if ! docker compose exec -T db pg_isready -h 127.0.0.1 -U postgres -d opsdb > /dev/null 2>&1; then
  echo "  [ERREUR] Le serveur ne répond pas. Lancez : docker compose up -d --wait"
  exit 1
fi
ok "le serveur répond"

version=$(requete "SHOW server_version;")
if [[ "${version}" == 18* ]]; then ok "PostgreSQL ${version}"; else erreur "version ${version}, 18 attendue"; fi

serveurs=$(requete "SELECT count(*) FROM serveur;" 2>/dev/null || echo 0)
if [[ "${serveurs}" == "2000" ]]; then ok "2000 serveurs"; else erreur "${serveurs} serveurs, 2000 attendus : rechargez avec ./scripts/reset.sh"; fi

mesures=$(requete "SELECT count(*) FROM mesure;" 2>/dev/null || echo 0)
if [[ "${mesures}" -gt 0 ]]; then ok "${mesures} mesures"; else erreur "table mesure vide ou absente"; fi

precharge=$(requete "SHOW shared_preload_libraries;")
if [[ "${precharge}" == *pg_stat_statements* ]]; then ok "pg_stat_statements chargé au démarrage"; else erreur "pg_stat_statements n'est pas préchargé"; fi

for ext in plpython3u btree_gist pg_stat_statements; do
  dispo=$(requete "SELECT count(*) FROM pg_available_extensions WHERE name = '${ext}';")
  if [[ "${dispo}" == "1" ]]; then ok "extension ${ext} disponible"; else erreur "extension ${ext} introuvable"; fi
done

shm=$(docker compose exec -T db sh -c "df -h /dev/shm | tail -1 | awk '{print \$2}'")
ok "mémoire partagée /dev/shm : ${shm}"

echo
if [[ "${echec}" -eq 0 ]]; then
  echo "Environnement prêt."
else
  echo "Au moins une vérification a échoué."
  exit 1
fi
