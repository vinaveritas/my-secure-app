#!/usr/bin/env bash
set -euo pipefail
DC="docker compose"

echo "[migrate] applying migrations/*.sql in order..."
for f in $(ls -1 migrations/*.sql 2>/dev/null | sort); do
  echo " - $f"
  # Run psql inside the DB container; file path must be /app/... (mounted)
  $DC exec -T db psql -v ON_ERROR_STOP=1 \
    -U "${POSTGRES_USER:-postgres}" \
    -d "${POSTGRES_DB:-vinaveritas_db}" \
    -f "/app/$f"
done
echo "[migrate] done."
