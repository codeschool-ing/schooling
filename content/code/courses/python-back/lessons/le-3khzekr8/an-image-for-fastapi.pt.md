---
title: Uma imagem para o agenda-api
version: 1
---

O Dockerfile do agenda-api é o do agenda com outro comando, em `~/agenda-api/Dockerfile`:

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

**O `--forwarded-allow-ips "*"`** confia em qualquer proxy, o que a aula 16 recusou. Dentro do Docker, o
endereço de onde o nginx se conecta é o gateway da rede do Docker, que não se sabe de antemão; a porta
é publicada só em `127.0.0.1`, então a única coisa que a alcança é algo no próprio servidor. Restringi-lo
ao endereço do gateway é melhor onde a rede é fixa.

O `.dockerignore` dele também deixa de fora os arquivos de texto que aulas anteriores escreveram, tokens
entre eles:

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

Os scripts de aulas anteriores vieram junto; nada os usa, e uma linha cada no `.dockerignore` os
deixaria de fora. Rodada sozinha, a imagem faz o que a aula 15 a fez fazer:

```
ana@vm:~/agenda-api$ docker run --rm agenda-api:0.1.0 python -c "from app.config import settings" 2>&1 | tail -3
secret_key
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
```

**Sem chave, não sobe.** A imagem não leva segredos, e o ambiente em que ela roda precisa fornecê-los.
Essa é a próxima seção.
