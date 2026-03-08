FROM python:3.13-slim

# 1. 基础环境设置（不要在这里设置 TMPDIR）
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    UV_PROJECT_ENVIRONMENT=/app/.venv

ENV PATH="/app/.venv/bin:$PATH"

# 2. 安装系统依赖（此时使用系统默认的 /tmp，不会报错）
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata ca-certificates openssh-server vim nano sudo procps \
    libgtk-3-0 libasound2 libdbus-1-3 libx11-xcb1 libxcomposite1 \
    libxdamage1 libxext6 libxfixes3 libnss3 libatk1.0-0 \
    libatk-bridge2.0-0 libgbm1 libpangocairo-1.0-0 libpango-1.0-0 \
    libxkbcommon0 libxtst6 libdbus-glib-1-2 libxt6 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. 创建必要的持久化目录
RUN mkdir -p /app/data/tmp /app/data/.cache /app/data/ms-playwright /app/logs

# 4. 目录创建好之后，再设置指向持久化目录的环境变量（供运行时使用）
ENV TMPDIR=/app/data/tmp \
    PLAYWRIGHT_BROWSERS_PATH=/app/data/ms-playwright \
    XDG_CACHE_HOME=/app/data/.cache

# 5. 后续的业务逻辑构建...
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
RUN uv sync --frozen --no-dev --no-install-project

# 6.安装浏览器
RUN .venv/bin/python -m playwright install --with-deps chromium firefox
RUN .venv/bin/python -m camoufox fetch

COPY config.defaults.toml /app/config.defaults.toml
COPY app /app/app
COPY main.py /app/main.py
COPY scripts /app/scripts

RUN sed -i 's/\r$//' /app/scripts/*.sh || true \
    && chmod +x /app/scripts/*.sh || true

# 确保所有运行时需要的目录都存在
RUN mkdir -p /app/data /app/data/tmp /app/data/.cache /app/logs /app/data/ms-playwright \
    && mkdir -p /var/run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config

EXPOSE 8000 22222

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]