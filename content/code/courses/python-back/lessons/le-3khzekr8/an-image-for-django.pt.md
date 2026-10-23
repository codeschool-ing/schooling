---
title: Uma imagem para o agenda
version: 1
---

Um **Dockerfile** é a receita de uma imagem, uma instrução por passo. O do agenda, em
`~/agenda/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "# Dockerfile\nFROM python:3.12-slim\nCOPY --from=astral/uv:0.13.1 /uv /usr/local/bin/uv\n\n", "note": "**A imagem slim do Python** do Docker Hub, e o uv copiado da imagem da própria Astral: um binário, sem instalador."}, {"code": "WORKDIR /app\nENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 PYTHONUNBUFFERED=1\n\n", "note": "`UV_LINK_MODE=copy` porque o cache abaixo fica em outro sistema de arquivos; bytecode compilado na construção, para a primeira requisição não pagar por ele."}, {"code": "COPY pyproject.toml uv.lock ./\nRUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project\n\n", "note": "**As dependências primeiro, sozinhas.** O `--frozen` instala exatamente o que o `uv.lock` diz e se recusa a mudá-lo; o `--no-dev` deixa de fora o pytest e afins. A montagem de cache guarda os downloads do uv entre construções."}, {"code": "COPY . .\nENV PATH=\"/app/.venv/bin:$PATH\"\n\n", "note": "Depois o código, e o `bin` do ambiente primeiro no `PATH`, para que `gunicorn` e `python` sejam os do projeto."}, {"code": "RUN useradd --system --no-create-home agenda\nUSER agenda\n\n", "note": "**Não como root.** Um processo que escape por um bug no agenda ganha uma conta que não é dona de nada."}, {"code": "EXPOSE 8000\nCMD [\"gunicorn\", \"config.wsgi\", \"--workers\", \"3\", \"--bind\", \"0.0.0.0:8000\"]\n", "note": "O Gunicorn em todas as interfaces do contêiner, que é como o tráfego de fora entra nele."}]}
```

A ordem dos passos é uma decisão:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os passos do Dockerfile de cima para baixo: FROM python 3.12 slim, baixado uma vez; COPY do binário do uv; COPY do pyproject.toml e do uv.lock, que mudam quando as dependências mudam; RUN uv sync, o passo lento, em cache junto com eles; COPY do resto do código, que muda a cada edição; e o usuário, barato, depois do código.\"> <rect x=\"20\" y=\"18\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FROM python:3.12-slim</text> <text x=\"370\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a base, baixada uma vez</text> <rect x=\"20\" y=\"52\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"71\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY --from=astral/uv</text> <text x=\"370\" y=\"71\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o binário do uv</text> <rect x=\"20\" y=\"86\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"32\" y=\"105\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY pyproject.toml uv.lock</text> <text x=\"370\" y=\"105\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">muda quando as dependências mudam</text> <rect x=\"20\" y=\"120\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"32\" y=\"139\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RUN uv sync --frozen --no-dev</text> <text x=\"370\" y=\"139\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o passo lento, em cache com elas</text> <rect x=\"20\" y=\"154\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.18\" stroke=\"var(--amber)\"></rect> <text x=\"32\" y=\"173\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY . .</text> <text x=\"370\" y=\"173\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">muda a cada edição</text> <rect x=\"20\" y=\"188\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"207\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RUN useradd ... / USER agenda</text> <text x=\"370\" y=\"207\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">barato, depois do código</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Uma mudança invalida sua camada e todas as de baixo, nunca as de cima.</text> </svg>", "caption": "Por que o arquivo de lock é copiado antes do código: uma edição numa view reconstrói do COPY . . para baixo, e as dependências continuam em cache."}
```

Um **`.dockerignore`** deixa arquivos fora da construção. O ambiente virtual é desta máquina e a
imagem faz o seu; o `.env` guarda segredos que nunca podem ser gravados numa imagem, onde qualquer um
com a imagem conseguiria lê-los:

```sh
# .dockerignore
.venv/
.git/
.env
__pycache__/
.pytest_cache/
celerybeat-schedule*
tests/
```

```
ana@vm:~/agenda$ docker build -t agenda:0.1.0 . 2>&1 | grep -E "^#[0-9]+ \[stage|^#[0-9]+ [0-9.]+ (Installed|Bytecode)|naming to"
#6 [stage-0 1/7] FROM docker.io/library/python:3.12-slim@sha256:a0f57064cbdcd6285fa45f51237ab0b35ea8ebaed06a1f5973e89e19dfb86704
#8 [stage-0 3/7] WORKDIR /app
#9 [stage-0 2/7] COPY --from=astral/uv:0.13.1 /uv /usr/local/bin/uv
#10 [stage-0 4/7] COPY pyproject.toml uv.lock ./
#11 [stage-0 5/7] RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project
#11 0.566 Installed 31 packages in 418ms
#11 1.392 Bytecode compiled 1996 files in 825ms
#12 [stage-0 6/7] COPY . .
#13 [stage-0 7/7] RUN useradd --system --no-create-home agenda
#14 naming to docker.io/library/agenda:0.1.0 done
```

As linhas que ficaram são os passos, o relatório do próprio uv, e o nome que a imagem ganhou. Antes de
seguir, pergunte à imagem algo de que o agenda precisa na hora, um driver de banco:

```
ana@vm:~/agenda$ docker run --rm agenda:0.1.0 python -c "import psycopg" 2>&1 | tail -4
Attempts made:
- couldn't import psycopg 'c' implementation: No module named 'psycopg_c'
- couldn't import psycopg 'binary' implementation: No module named 'psycopg_binary'
- couldn't import psycopg 'python' implementation: libpq library not found
```

**`libpq library not found`.** O psycopg, como a aula 4 o instalou, é a versão em Python puro que chama a
biblioteca C `libpq`, e o Ubuntu tinha a `libpq` instalada com o PostgreSQL. A imagem slim não tem
nenhuma. Ou a imagem a instala com `apt-get`, ou o psycopg traz a sua: o extra **`binary`** é o psycopg
com uma cópia da libpq dentro do wheel. Acrescente-o, em cada projeto:

```
ana@vm:~/agenda$ uv add "psycopg[binary]"
Resolved 43 packages in 358ms
Downloading psycopg-binary (5.0MiB)
 Downloaded psycopg-binary
Prepared 1 package in 75ms
Installed 1 package in 1ms
 + psycopg-binary==3.3.6
ana@vm:~/agenda-api$ uv add "psycopg[binary]"
Resolved 43 packages in 203ms
Installed 1 package in 1ms
 + psycopg-binary==3.3.6
```

```
ana@vm:~/agenda$ docker build -q -t agenda:0.1.0 .
sha256:3f5ac490dd51651670db963a6ef1d9e85b798fc8b08ad14d08f98127d451fc0f
ana@vm:~/agenda$ docker run --rm agenda:0.1.0 python -c "import psycopg; print(psycopg.pq.__impl__, psycopg.pq.version())"
binary 180006
ana@vm:~/agenda$ docker run --rm agenda:0.1.0 whoami
agenda
ana@vm:~/agenda$ docker image ls agenda
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
agenda:0.1.0   3f5ac490dd51        381MB         86.5MB        
```

**`binary`**, a libpq versão 18, e o processo roda como `agenda`. A imagem tem 381 MB em disco, a maior
parte Python e Debian; o `CONTENT SIZE` é o que um registro guardaria, comprimido.
