#!/usr/bin/env bash
# Ouvre psql dans le conteneur, connecté à la base opsdb.
# Les arguments sont transmis à psql : ./scripts/psql.sh -c "SELECT version();"
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec docker compose exec db psql -U postgres -d opsdb "$@"
