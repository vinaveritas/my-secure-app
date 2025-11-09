#!/usr/bin/env bash
set -euo pipefail
mkdir -p backups
F="backups/backup_$(date +%Y%m%d_%H%M%S).sql"
echo "[backup] writing $F"
docker compose exec -T db pg_dump -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-vinaveritas_db}" > "$F"
echo "[backup] done."
