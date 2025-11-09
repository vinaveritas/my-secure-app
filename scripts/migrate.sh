#!/usr/bin/env bash
set -euo pipefail
DC="docker compose"
echo "[migrate] applying migrations/*.sql in order..."
for f in $(ls -1 migrations/*.sql 2>/dev/null | sort); do
  echo " - $f"
  $DC exec -T db psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-vinaveritas_db}" -f "/docker-entrypoint-initdb.d/placeholder.sql" >/dev/null 2>&1 || true
  $DC exec -T db psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-vinaveritas_db}" -f "/app/$f"
done
echo "[migrate] done."
