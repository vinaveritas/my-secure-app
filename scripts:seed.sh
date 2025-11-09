#!/usr/bin/env bash
set -euo pipefail
DC="docker compose"

echo "[seed] applying seeds/*.sql in order..."
for f in $(ls -1 seeds/*.sql 2>/dev/null | sort); do
  echo " - $f"
  $DC exec -T db psql -v ON_ERROR_STOP=1 \
    -U "${POSTGRES_USER:-postgres}" \
    -d "${POSTGRES_DB:-vinaveritas_db}" \
    -f "/app/$f"
done
echo "[seed] done."
