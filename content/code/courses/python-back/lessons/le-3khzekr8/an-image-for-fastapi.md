---
title: An image for agenda-api
version: 1
---

agenda-api's Dockerfile is agenda's with a different command, at `~/agenda-api/Dockerfile`:

```dockerfile
# Dockerfile
FROM python:3.12-slim
COPY --from=astral/uv:0.13.1 /uv /usr/local/bin/uv

WORKDIR /app
ENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 PYTHONUNBUFFERED=1

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project

COPY . .
ENV PATH="/app/.venv/bin:$PATH"

RUN useradd --system --no-create-home agenda
USER agenda

EXPOSE 8001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--workers", "2", "--proxy-headers", "--forwarded-allow-ips", "*"]
```

**`--forwarded-allow-ips "*"`** trusts any proxy, which lesson 16 refused. Inside Docker the address
nginx connects from is the Docker network's gateway, which is not known in advance; the port is
published on `127.0.0.1` only, so the one thing that can reach it is something on the server itself.
Narrowing it to the gateway's address is better where the network is fixed.

Its `.dockerignore` also leaves out the text files earlier lessons wrote, tokens among them:

```sh
# .dockerignore
.venv/
.git/
.env
__pycache__/
.pytest_cache/
tests/
*.txt
```

```
ana@vm:~/agenda-api$ docker build -q -t agenda-api:0.1.0 .
sha256:ea4004e336c89fd1685bb03e02d04e943a0e2b2ba0c85786d2e4ecd8b65e6186
ana@vm:~/agenda-api$ docker run --rm agenda-api:0.1.0 ls
Dockerfile
alembic.ini
app
bad_tokens.py
create_user.py
crowd.py
doors.py
hello_db.py
load.py
migrations
nplus1.py
pyproject.toml
queries.py
show_sql.py
slow.py
uv.lock
```

The scripts of earlier lessons came along; nothing uses them, and a line each in `.dockerignore` would
leave them out. Run alone, the image does what lesson 15 made it do:

```
ana@vm:~/agenda-api$ docker run --rm agenda-api:0.1.0 python -c "from app.config import settings" 2>&1 | tail -3
secret_key
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
```

**No key, no start.** The image carries no secrets, and the environment it runs in must supply them.
That is the next section.
