#!/usr/bin/env sh
set -eu

HOST="${SERVER_HOST:-0.0.0.0}"
PORT="${PORT:-${SERVER_PORT:-8000}}"
WORKERS="${SERVER_WORKERS:-1}"
LOG_LEVEL_LOWER="$(printf "%s" "${LOG_LEVEL:-INFO}" | tr '[:upper:]' '[:lower:]')"

# 启动 SSH
/usr/sbin/sshd

echo "[Start] Launching Uvicorn in Headless mode..."
# 直接执行，不再使用 xvfb-run
exec uvicorn main:app \
    --host "$HOST" \
    --port "$PORT" \
    --workers "$WORKERS" \
    --log-level "$LOG_LEVEL_LOWER" \
    --proxy-headers \
    --forwarded-allow-ips='*'