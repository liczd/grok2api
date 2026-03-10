#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DATA_DIR="$ROOT_DIR/data"
LOG_DIR="$ROOT_DIR/logs"
TMP_DIR="$DATA_DIR/tmp"
CACHE_DIR="$DATA_DIR/.cache"
DEFAULT_CONFIG="$ROOT_DIR/config.defaults.toml"

# 在挂载卷内创建必要的子目录
mkdir -p "$DATA_DIR" "$LOG_DIR" "$TMP_DIR" "$CACHE_DIR"

if [ ! -f "$DATA_DIR/config.toml" ]; then
  cp "$DEFAULT_CONFIG" "$DATA_DIR/config.toml"
fi

if [ ! -f "$DATA_DIR/token.json" ]; then
  echo "{}" > "$DATA_DIR/token.json"
fi

# 尝试赋予权限，失败时不阻塞启动
chmod -R 777 "$TMP_DIR" "$CACHE_DIR" 2>/dev/null || true
chmod 600 "$DATA_DIR/config.toml" "$DATA_DIR/token.json" 2>/dev/null || true
