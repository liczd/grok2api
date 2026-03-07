FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    UV_PROJECT_ENVIRONMENT=/app/.venv

ENV PATH="/app/.venv/bin:$PATH"

RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata ca-certificates openssh-server vim nano sudo procps \
    && rm -rf /var/lib/apt/lists/*

# 安装浏览器运行所需的系统依赖
RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libasound2 \
    libdbus-1-3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgbm1 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libxkbcommon0 \
    libxtst6 \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv via the official Docker image (recommended approach, no pip needed)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock /app/

RUN uv sync --frozen --no-dev --no-install-project

# Pre-install Playwright Chromium + OS deps to make auto-register/solver usable in Docker
# without doing `apt-get` at runtime.
RUN python -m playwright install --with-deps chromium

# Pre-fetch camoufox Firefox binary so the container works without network access at runtime.
# camoufox is the recommended solver browser type (higher Turnstile success rate on accounts.x.ai).
RUN python -m camoufox fetch

COPY config.defaults.toml /app/config.defaults.toml
COPY app /app/app
COPY main.py /app/main.py
COPY scripts /app/scripts

# When building on Windows, shell scripts may be copied with CRLF endings and
# without executable bit. Normalize both to keep ENTRYPOINT reliable.
RUN sed -i 's/\r$//' /app/scripts/*.sh || true \
    && chmod +x /app/scripts/*.sh || true

RUN mkdir -p /app/data /app/data/tmp /app/logs \
    && mkdir -p /var/run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config

EXPOSE 8000 22222

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]
