#!/usr/bin/env bash
# Rattrapage : applique l'état attendu à la fin d'une quête, pour pouvoir
# continuer le parcours si vous n'avez pas pu la terminer.
#
#   ./scripts/rattrapage.sh       liste les rattrapages disponibles
#   ./scripts/rattrapage.sh 04    applique le rattrapage de la quête 04
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ $# -ne 1 ]]; then
  echo "Rattrapages disponibles :"
  for f in rattrapage/*.sql; do
    echo "  $(basename "${f}" .sql | cut -d- -f1)   $(sed -n '1s/^-- //p' "${f}")"
  done
  echo
  echo "Usage : $0 NN"
  exit 1
fi

numero=$(printf "%02d" "$((10#$1))")
fichier=$(find rattrapage -maxdepth 1 -name "${numero}-*.sql" | head -1)

if [[ -z "${fichier}" ]]; then
  echo "Pas de rattrapage pour la quête ${numero} : elle ne laisse rien dont les suivantes ont besoin."
  exit 0
fi

echo "[rattrapage] Application de ${fichier}"
docker compose exec -T db psql -U postgres -d opsdb -X -v ON_ERROR_STOP=1 < "${fichier}"
echo "[rattrapage] Terminé."
