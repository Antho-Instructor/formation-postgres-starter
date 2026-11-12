#!/usr/bin/env bash
# Supprime le serveur et toutes ses données, puis recharge une base opsdb neuve.
# Option -y : pas de confirmation (utile en script).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ "${1:-}" != "-y" ]]; then
  read -r -p "Toutes vos modifications dans la base seront perdues. Continuer ? [o/N] " reponse
  if [[ "${reponse}" != "o" && "${reponse}" != "O" ]]; then
    echo "Annulé."
    exit 0
  fi
fi

echo "[reset] Suppression de l'environnement, volume compris..."
docker compose down -v

echo "[reset] Reconstruction et chargement..."
debut=$(date +%s)
docker compose up -d --build --wait --wait-timeout 1800
fin=$(date +%s)

echo "[reset] Base opsdb prête en $((fin - debut)) s. Connexion : ./scripts/psql.sh"
