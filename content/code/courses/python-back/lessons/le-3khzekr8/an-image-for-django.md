---
title: An image for agenda
version: 1
---

A **Dockerfile** is the recipe for an image, one instruction per step. agenda's, at
`~/agenda/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "# Dockerfile\nFROM python:3.12-slim\nCOPY --from=astral/uv:0.13.1 /uv /usr/local/bin/uv\n\n", "note": "**The slim Python image** from Docker Hub, and uv copied out of Astral's own image: one binary, no installer."}, {"code": "WORKDIR /app\nENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 PYTHONUNBUFFERED=1\n\n", "note": "`UV_LINK_MODE=copy` because the cache below is on another filesystem; bytecode compiled at build time, so the first request does not pay for it."}, {"code": "COPY pyproject.toml uv.lock ./\nRUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project\n\n", "note": "**The dependencies first, alone.** `--frozen` installs exactly what `uv.lock` says and refuses to change it; `--no-dev` leaves out pytest and the like. The cache mount keeps uv's downloads between builds."}, {"code": "COPY . .\nENV PATH=\"/app/.venv/bin:$PATH\"\n\n", "note": "Then the code, and the environment's `bin` first on the `PATH`, so `gunicorn` and `python` are the project's."}, {"code": "RUN useradd --system --no-create-home agenda\nUSER agenda\n\n", "note": "**Not as root.** A process that escapes through a bug in agenda gets an account that owns nothing."}, {"code": "EXPOSE 8000\nCMD [\"gunicorn\", \"config.wsgi\", \"--workers\", \"3\", \"--bind\", \"0.0.0.0:8000\"]\n", "note": "Gunicorn on every interface of the container, which is how traffic from outside it gets in."}]}
```

The order of the steps is a decision:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The Dockerfile's steps from top to bottom: FROM python 3.12 slim, pulled once; COPY the uv binary; COPY pyproject.toml and uv.lock, which change when dependencies change; RUN uv sync, the slow step, cached with them; COPY the rest of the code, which changes with every edit; and the user, cheap, after the code.\"> <rect x=\"20\" y=\"18\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FROM python:3.12-slim</text> <text x=\"370\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the base, pulled once</text> <rect x=\"20\" y=\"52\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"71\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY --from=astral/uv</text> <text x=\"370\" y=\"71\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the uv binary</text> <rect x=\"20\" y=\"86\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"32\" y=\"105\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY pyproject.toml uv.lock</text> <text x=\"370\" y=\"105\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">changes when dependencies change</text> <rect x=\"20\" y=\"120\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"32\" y=\"139\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RUN uv sync --frozen --no-dev</text> <text x=\"370\" y=\"139\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the slow step, cached with them</text> <rect x=\"20\" y=\"154\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.18\" stroke=\"var(--amber)\"></rect> <text x=\"32\" y=\"173\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COPY . .</text> <text x=\"370\" y=\"173\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">changes with every edit</text> <rect x=\"20\" y=\"188\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"207\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RUN useradd ... / USER agenda</text> <text x=\"370\" y=\"207\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheap, after the code</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A change invalidates its layer and every layer below it, never the ones above.</text> </svg>", "caption": "Why the lock file is copied before the code: an edit to a view rebuilds from COPY . . down, and the dependencies stay cached."}
```

A **`.dockerignore`** keeps files out of the build. The virtual environment is for this machine and
the image makes its own; `.env` holds secrets that must never be baked into an image, where anybody
with the image could read them:

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

The lines kept are the steps, uv's own report, and the name the image got. Before going further, ask
the image something agenda needs at once, a database driver:

```
ana@vm:~/agenda$ docker run --rm agenda:0.1.0 python -c "import psycopg" 2>&1 | tail -4
Attempts made:
- couldn't import psycopg 'c' implementation: No module named 'psycopg_c'
- couldn't import psycopg 'binary' implementation: No module named 'psycopg_binary'
- couldn't import psycopg 'python' implementation: libpq library not found
```

**`libpq library not found`.** psycopg, as lesson 4 installed it, is the pure-Python version that
calls the C library `libpq`, and Ubuntu had `libpq` installed with PostgreSQL. The slim image has
none. Either the image installs it with `apt-get`, or psycopg brings its own: the **`binary`** extra
is psycopg with a copy of libpq inside the wheel. Add it, in each project:

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

**`binary`**, libpq version 18, and the process runs as `agenda`. The image is 381 MB on disk, most of
it Python and Debian; `CONTENT SIZE` is what a registry would store, compressed.
