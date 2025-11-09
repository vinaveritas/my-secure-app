#!/usr/bin/env bash
set -euo pipefail
# simple health ping (expects app running on host 3000)
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT:-3000}/healthz || true)
echo "[ci] /healthz -> $code"
[ "$code" = "200" ] || exit 1
echo "[ci] ok"
