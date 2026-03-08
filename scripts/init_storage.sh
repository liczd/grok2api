#!/usr/bin/env sh
set -eu

# 强制指向持久化目录
DATA_DIR="/app/data"
LOG_DIR="/app/logs"
TMP_DIR="$DATA_DIR/tmp"
DEFAULT_CONFIG="/app/config.defaults.toml"

# 确保目录存在
mkdir -p "$DATA_DIR" "$LOG_DIR" "$TMP_DIR"

# 处理配置文件：仅在不存在时拷贝
if [ ! -f "$DATA_DIR/config.toml" ]; then
  echo "[Init] Copying default config to $DATA_DIR/config.toml"
  cp "$DEFAULT_CONFIG" "$DATA_DIR/config.toml"
fi

# 处理 Token 文件
if [ ! -f "$DATA_DIR/token.json" ]; then
  echo "{}" > "$DATA_DIR/token.json"
fi

# 关键：浏览器缓存重定向 (如果 /root/.cache 没挂载卷，我们将其软链接到持久化目录)
if [ ! -d "/root/.cache" ]; then
    mkdir -p "$DATA_DIR/.cache"
    ln -s "$DATA_DIR/.cache" "/root/.cache"
fi

# 修改权限时增加容错，部分云盘不支持 chmod
chmod 600 "$DATA_DIR/config.toml" "$DATA_DIR/token.json" || echo "Warning: Could not set permissions"