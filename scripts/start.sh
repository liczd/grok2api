#!/usr/bin/env sh
set -eu

HOST="${SERVER_HOST:-0.0.0.0}"
# Allow Zeabur's default PORT environment variable to override SERVER_PORT
PORT="${PORT:-${SERVER_PORT:-8000}}"
WORKERS="${SERVER_WORKERS:-1}"

LOG_LEVEL_LOWER="$(printf "%s" "${LOG_LEVEL:-INFO}" | tr '[:upper:]' '[:lower:]')"

exec uvicorn main:app --host "$HOST" --port "$PORT" --workers "$WORKERS" --log-level "$LOG_LEVEL_LOWER" --proxy-headers --forwarded-allow-ips='*'
