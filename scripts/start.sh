#!/usr/bin/env sh
set -eu

HOST="${SERVER_HOST:-0.0.0.0}"
PORT="${PORT:-${SERVER_PORT:-8000}}"
WORKERS="${SERVER_WORKERS:-1}"
LOG_LEVEL_LOWER="$(printf "%s" "${LOG_LEVEL:-INFO}" | tr '[:upper:]' '[:lower:]')"

# 启动 SSH
/usr/sbin/sshd

# 使用 xvfb-run 启动应用，为浏览器提供虚拟显示环境
# -s "-screen 0 1280x1024x24" 是设置虚拟显示器参数
echo "[Start] Launching Uvicorn with Xvfb..."
exec xvfb-run -a --server-args="-screen 0 1280x1024x24 -ac +extension GLX +render -noreset" \
    uvicorn main:app \
    --host "$HOST" \
    --port "$PORT" \
    --workers "$WORKERS" \
    --log-level "$LOG_LEVEL_LOWER" \
    --proxy-headers \
    --forwarded-allow-ips='*'