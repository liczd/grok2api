FROM python:3.13-slim

# 1. 基础环境设置
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# 2. 安装系统依赖（精简版，移除 xvfb）
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata ca-certificates openssh-server sudo procps \
    libgtk-3-0 libasound2 libdbus-1-3 libnss3 libatk1.0-0 \
    libatk-bridge2.0-0 libgbm1 libpangocairo-1.0-0 libpango-1.0-0 \
    libxkbcommon0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. 关键：设置浏览器路径到 /opt (避免被挂载卷覆盖)
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright \
    XDG_CACHE_HOME=/opt/browser-cache \
    TMPDIR=/tmp

# 创建目录并确保权限
RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH $XDG_CACHE_HOME /app/data /app/logs

# 4. 构建业务逻辑
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
RUN uv sync --frozen --no-dev --no-install-project

# 5. 安装浏览器到 /opt
RUN .venv/bin/python -m playwright install --with-deps chromium firefox
RUN .venv/bin/python -m camoufox fetch

COPY config.defaults.toml /app/config.defaults.toml
COPY app /app/app
COPY main.py /app/main.py
COPY scripts /app/scripts

# 6. 处理脚本权限及 SSH 配置
RUN sed -i 's/\r$//' /app/scripts/*.sh || true \
    && chmod +x /app/scripts/*.sh || true \
    && mkdir -p /var/run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 8000 22222

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["/app/scripts/start.sh"]