FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    # 关键路径设置
    PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright \
    CAMOUFOX_DIR=/opt/camoufox-base

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata ca-certificates openssh-server sudo procps \
    libgtk-3-0 libasound2 libdbus-1-3 libnss3 libatk1.0-0 \
    libatk-bridge2.0-0 libgbm1 libpangocairo-1-0-0 libpango-1.0-0 \
    libxkbcommon0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 同步项目
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
RUN uv sync --frozen --no-dev --no-install-project

# 关键步骤：安装浏览器二进制文件到 /opt
# 这些是只读的，Claw.cloud 不会认为它们是运行时的“变更”
RUN .venv/bin/python -m playwright install --with-deps chromium firefox
# 强制 camoufox 安装到指定目录
RUN XDG_CACHE_HOME=$CAMOUFOX_DIR .venv/bin/python -m camoufox fetch

COPY . /app
RUN chmod +x /app/scripts/*.sh

# 设置运行时环境变量：将缓存和临时文件指向挂载卷
# 这样浏览器运行时产生的“变更”都会进入 /app/data，Claw 就不会报错了
ENV XDG_CACHE_HOME=/app/data/.browser_runtime \
    TMPDIR=/app/data/tmp

EXPOSE 8000 22222
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]