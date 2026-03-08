FROM python:3.13-slim

# 1. 增加浏览器和临时目录的环境变量路径（关键）
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PLAYWRIGHT_BROWSERS_PATH=/app/data/ms-playwright \
    TMPDIR=/app/data/tmp \
    XDG_CACHE_HOME=/app/data/.cache

ENV PATH="/app/.venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata ca-certificates openssh-server vim nano sudo procps \
    libgtk-3-0 libasound2 libdbus-1-3 libx11-xcb1 libxcomposite1 \
    libxdamage1 libxext6 libxfixes3 libnss3 libatk1.0-0 \
    libatk-bridge2.0-0 libgbm1 libpangocairo-1.0-0 libpango-1.0-0 \
    libxkbcommon0 libxtst6 libdbus-glib-1-2 libxt6 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/

RUN uv sync --frozen --no-dev --no-install-project

# 2. 安装浏览器时指定路径（确保安装到 /app/data 下，以便持久化或预制）
RUN mkdir -p /app/data/ms-playwright && \
    .venv/bin/python -m playwright install --with-deps chromium firefox

# 3. 预取 Camoufox 时，通过环境变量告知路径
RUN mkdir -p /app/data/.cache && \
    .venv/bin/python -m camoufox fetch

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