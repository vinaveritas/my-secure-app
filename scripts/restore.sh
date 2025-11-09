#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "usage: ./scripts/restore.sh backups/backup_xxx.sql"
  exit 1
fi
echo "[restore] from $FILE"
cat "$FILE" | docker compose exec -T db psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-vinaveritas_db}"
echo "[restore] done."
