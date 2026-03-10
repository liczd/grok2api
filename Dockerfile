# 阶段一：构建阶段 (使用 uv 官方镜像)
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    # 强制指定浏览器下载路径到构建目录，方便复制
    PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright \
    CAMOUFOX_BROWSER_PATH=/opt/camoufox

WORKDIR /app

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && rm -rf /var/lib/apt/lists/*

# 同步依赖 (利用 uv 缓存)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# 预安装 Playwright 浏览器 (Chromium)
RUN uv run playwright install chromium

# 预安装 Camoufox 浏览器
RUN mkdir -p /opt/camoufox && \
    XDG_CACHE_HOME=/opt/camoufox uv run camoufox fetch

# 阶段二：运行阶段
FROM python:3.13-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright \
    CAMOUFOX_BROWSER_PATH=/opt/camoufox \
    # 关键：适配 Claw Cloud 只读文件系统，重定向所有写入操作到挂载卷
    XDG_CACHE_HOME=/app/data/.cache \
    TMPDIR=/app/data/tmp \
    PYTHONPATH=/app

WORKDIR /app

# 从构建阶段复制环境和浏览器
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /opt/ms-playwright /opt/ms-playwright
COPY --from=builder /opt/camoufox /opt/camoufox

# 安装运行时必要的系统库 (修正了 librandr2 -> libxrandr2)
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
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# 复制项目代码
COPY config.defaults.toml /app/
COPY app /app/app
COPY main.py /app/main.py
COPY scripts /app/scripts

# 目录权限预设 (在构建镜像时创建好挂载点)
RUN mkdir -p /app/data /app/logs /app/data/tmp /app/data/.cache \
    && chmod -R 777 /app/data /app/logs \
    && chmod +x /app/scripts/*.sh \
    && sed -i 's/\r$//' /app/scripts/*.sh

EXPOSE 8000

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]
