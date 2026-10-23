FROM python:3.12-slim
COPY --from=astral/uv:0.13.1 /uv /usr/local/bin/uv
WORKDIR /app
ENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv --mount=type=secret,id=ca SSL_CERT_FILE=/run/secrets/ca uv sync --frozen --no-dev --no-install-project
