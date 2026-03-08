#!/usr/bin/env sh
set -eu

DATA_DIR="/app/data"
DEFAULT_CONFIG="/app/config.defaults.toml"

# 确保目录存在
mkdir -p "$DATA_DIR"

# 仅在不存在配置文件时才拷贝，防止覆盖用户的自定义配置
if [ ! -f "$DATA_DIR/config.toml" ]; then
  echo "[Init] Initializing default config.toml"
  cp "$DEFAULT_CONFIG" "$DATA_DIR/config.toml"
fi

# 确保 Token 文件存在
if [ ! -f "$DATA_DIR/token.json" ]; then
  echo "{}" > "$DATA_DIR/token.json"
fi

# Claw.cloud 某些存储驱动不支持 chmod，增加容错
chmod 644 "$DATA_DIR/config.toml" 2>/dev/null || true