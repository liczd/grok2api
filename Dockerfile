# 使用官方 uv 镜像作为构建阶段
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 同步依赖（利用缓存）
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# 安装 Playwright (在构建阶段完成)
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN uv run playwright install --with-deps chromium

# 最终运行阶段
FROM python:3.13-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright \
    # 关键配置：确保运行时产生的临时文件和缓存都在挂载卷内
    XDG_CACHE_HOME=/app/data/.cache \
    TMPDIR=/app/data/tmp

WORKDIR /app

# 从构建阶段复制环境和浏览器
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /opt/ms-playwright /opt/ms-playwright

# 安装运行时必要的系统库 (Playwright 依赖)
# 这里的技巧是利用已安装的 playwright 获取依赖列表并安装
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    librandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY config.defaults.toml /app/
COPY app /app/app
COPY main.py /app/main.py
COPY scripts /app/scripts

# 权限与目录预设
RUN mkdir -p /app/data /app/logs /app/data/tmp /app/data/.cache \
    && chmod +x /app/scripts/*.sh \
    && sed -i 's/\r$//' /app/scripts/*.sh

EXPOSE 8000

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]
