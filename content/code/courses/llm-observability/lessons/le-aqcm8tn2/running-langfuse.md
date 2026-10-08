---
title: Running Langfuse on your own machine
version: 2
---

Langfuse is open source, and the version this lesson uses runs on your computer from the images its
authors publish, under **Docker**. If Docker is not on your machine yet, this is the one place in the
course that installs it. On Ubuntu 24.04, natively or in the virtual machine of lesson 1:

```sh
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
```

The second line lets you run `docker` without `sudo`, and takes effect at your next login: log out
and in again, or open a new terminal with `newgrp docker`. On a Mac or on Windows, Docker Desktop
gives you the same two commands, `docker` and `docker compose`. Those two lines were not run for
this course: the recording machine already had Docker 29.8 with Compose 5.6, and what follows needs
only a Compose that reads version 2 files, which every current one does.

## The compose file

Langfuse is not one program but six, and a **compose file** says which images to start, how they
find each other and what each is told. Make a directory for it, outside `~/obs`, with
`mkdir -p ~/langfuse`, and save this in it as `~/langfuse/docker-compose.yml`:

```yaml
# docker-compose.yml: Langfuse 3.225.11, self-hosted on one machine, for lesson 6 of llm-observability.
#
# Six containers: Langfuse's web server (the screens, the API and the OTLP
# endpoint at /api/public/otel) and its worker (which moves what arrives into
# ClickHouse); PostgreSQL for users, projects and settings; ClickHouse for the
# traces themselves; Redis as the queue between the two; and an S3-compatible
# store (MinIO) where every incoming event is kept before it is processed.
#
# Every secret below is a placeholder for a machine nobody else can reach. A
# real deployment generates its own SALT, ENCRYPTION_KEY (64 hex characters,
# from `openssl rand -hex 32`) and NEXTAUTH_SECRET, and keeps them out of the
# file.
#
# Each image is pinned to the digest the lesson was recorded with. MinIO's own
# images are no longer published on Docker Hub; this is Bitnami's build of it.
#
# The LANGFUSE_INIT_* variables create the organisation, the project, its two
# API keys and one user when the server first starts, so no sign-up screen has
# to be clicked. The web server is published on 127.0.0.1 only.
x-env: &env
  DATABASE_URL: postgresql://postgres:postgres@postgres:5432/postgres
  SALT: local-salt-not-a-secret
  ENCRYPTION_KEY: "0000000000000000000000000000000000000000000000000000000000000000"
  TELEMETRY_ENABLED: "false"
  CLICKHOUSE_MIGRATION_URL: clickhouse://clickhouse:9000
  CLICKHOUSE_URL: http://clickhouse:8123
  CLICKHOUSE_USER: clickhouse
  CLICKHOUSE_PASSWORD: clickhouse
  CLICKHOUSE_CLUSTER_ENABLED: "false"
  LANGFUSE_S3_EVENT_UPLOAD_BUCKET: langfuse
  LANGFUSE_S3_EVENT_UPLOAD_REGION: auto
  LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID: minio
  LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY: miniosecret
  LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT: http://minio:9000
  LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE: "true"
  LANGFUSE_S3_EVENT_UPLOAD_PREFIX: events/
  LANGFUSE_S3_MEDIA_UPLOAD_BUCKET: langfuse
  LANGFUSE_S3_MEDIA_UPLOAD_REGION: auto
  LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID: minio
  LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY: miniosecret
  LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: http://minio:9000
  LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE: "true"
  LANGFUSE_S3_MEDIA_UPLOAD_PREFIX: media/
  REDIS_HOST: redis
  REDIS_PORT: "6379"
  REDIS_AUTH: redissecret
services:
  worker:
    image: langfuse/langfuse-worker:3@sha256:8a28c946bb5401eef488153fa294db5a79bd99dd5c90db8e4d39559374c9ebd3
    depends_on: [postgres, minio, redis, clickhouse]
    environment: *env
  web:
    image: langfuse/langfuse:3@sha256:a343f64e035eb01aeea358703a0428945d909d01e19452509a5a830862dda878
    depends_on: [postgres, minio, redis, clickhouse]
    ports: ["127.0.0.1:3000:3000"]
    environment:
      <<: *env
      NEXTAUTH_URL: http://localhost:3000
      NEXTAUTH_SECRET: local-nextauth-not-a-secret
      LANGFUSE_INIT_ORG_ID: marginalia
      LANGFUSE_INIT_ORG_NAME: Marginalia
      LANGFUSE_INIT_PROJECT_ID: support
      LANGFUSE_INIT_PROJECT_NAME: support-assistant
      LANGFUSE_INIT_PROJECT_PUBLIC_KEY: pk-lf-local-0001
      LANGFUSE_INIT_PROJECT_SECRET_KEY: sk-lf-local-0001
      LANGFUSE_INIT_USER_EMAIL: ana@marginalia.example
      LANGFUSE_INIT_USER_NAME: Ana
      LANGFUSE_INIT_USER_PASSWORD: local-password-0001
  clickhouse:
    image: clickhouse/clickhouse-server:25.8@sha256:0152dd511befe6a2c2ef53e930726179669b08116da78500b37c51c96ff5ee77
    user: "101:101"
    environment:
      CLICKHOUSE_DB: default
      CLICKHOUSE_USER: clickhouse
      CLICKHOUSE_PASSWORD: clickhouse
  minio:
    image: bitnamilegacy/minio:2025.7.23@sha256:8935e75fa5d11295c17171e4aa49efe390a1193cd7f12e4d21b92af9ffef09d7
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: miniosecret
      MINIO_DEFAULT_BUCKETS: langfuse
  redis:
    image: redis:7@sha256:17e1d479466f88e2d8fe48f21f44aba1572bf3bbc207be16b09870072b83b005
    command: ["--requirepass", "redissecret"]
  postgres:
    image: postgres:17@sha256:c6222b54873a2fb19591cb06b93ef2825c03cdb680396e3600f24921f340f630
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
```

Every secret in it, the passwords, `SALT`, `ENCRYPTION_KEY` and `NEXTAUTH_SECRET`, is a placeholder
that opens nothing, and that is safe only because the web server is published on 127.0.0.1, where
nobody but you can reach it. The `LANGFUSE_INIT_*` lines create an organisation, a project called
`support-assistant`, its two API keys and one user the first time the server starts, so you never
have to click through a sign-up screen. You can still open http://localhost:3000 in a browser and
sign in as `ana@marginalia.example` with the password in the file: everything this lesson asks
through the API, the screens show.

## Starting it

```sh
docker compose -f ~/langfuse/docker-compose.yml up -d
```

The first time, Docker downloads the six images before it starts anything, and unpacked they take
**5.4 GB** of disk, the largest thing this course installs after the model. The transcript below is a
later start, with the images already there:

```
ana@dev:~$ docker compose -f ~/langfuse/docker-compose.yml up -d
 Network langfuse_default Creating 
 Network langfuse_default Creating 
 Network langfuse_default Created 
 Network langfuse_default Created 
 Container langfuse-minio-1 Creating 
 Container langfuse-clickhouse-1 Creating 
 Container langfuse-postgres-1 Creating 
 Container langfuse-redis-1 Creating 
 Container langfuse-postgres-1 Created 
 Container langfuse-redis-1 Created 
 Container langfuse-clickhouse-1 Created 
 Container langfuse-minio-1 Created 
 Container langfuse-web-1 Creating 
 Container langfuse-worker-1 Creating 
 Container langfuse-worker-1 Created 
 Container langfuse-web-1 Created 
 Container langfuse-postgres-1 Starting 
 Container langfuse-minio-1 Starting 
 Container langfuse-redis-1 Starting 
 Container langfuse-clickhouse-1 Starting 
 Container langfuse-postgres-1 Started 
 Container langfuse-minio-1 Started 
 Container langfuse-redis-1 Started 
 Container langfuse-clickhouse-1 Started 
 Container langfuse-worker-1 Starting 
 Container langfuse-web-1 Starting 
 Container langfuse-worker-1 Started 
 Container langfuse-web-1 Started 
```

`-d` leaves them running in the background, and they keep running until you stop them, across
terminals, but not across a restart of Docker unless you start them again. The server takes a
minute or so to migrate its databases the first time; until then the health check below answers
nothing. Then:

```
ana@dev:~/obs$ curl -s $LANGFUSE_BASE_URL/api/public/health; echo
{"status":"OK","version":"3.225.11"}
```

What six containers cost while they idle, and the disk the images and their data take:

```
ana@dev:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
NAME                    CPU %     MEM USAGE / LIMIT
langfuse-web-1          0.74%     1.147GiB / 15.72GiB
langfuse-worker-1       0.58%     440.9MiB / 15.72GiB
langfuse-postgres-1     0.03%     70.42MiB / 15.72GiB
langfuse-redis-1        0.40%     7.672MiB / 15.72GiB
langfuse-clickhouse-1   34.45%    338.1MiB / 15.72GiB
langfuse-minio-1        0.11%     204.3MiB / 15.72GiB
ana@dev:~$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          7         7         5.428GB   0B (0%)
Containers      6         6         766kB     0B (0%)
Local Volumes   5         5         54.29MB   0B (0%)
Build Cache     0         0         0B        0B
```

Idle, the six hold about **2.2 GB of memory** between them, half of it the web server, and
ClickHouse keeps a processor busy tidying its own tables even with nothing arriving. With the model
answering at the same time that is over 5 GB, which is why lesson 1 asked for 8 GB in the whole
computer. On a machine with less, stop Langfuse when you are not using it, and the model has the
memory back.

## The keys, where the programs look for them

The programs in the rest of this lesson read where Langfuse is and the project's two keys from the
environment, and so does Langfuse's own SDK, which is one of two libraries this lesson adds:

```sh
cat >> ~/llmobs/bin/activate <<'EOF'
export LANGFUSE_BASE_URL=http://127.0.0.1:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-local-0001
export LANGFUSE_SECRET_KEY=sk-lf-local-0001
EOF
source ~/llmobs/bin/activate
pip install langfuse==4.17.0 langsmith==0.14.4
```

The keys are the ones the compose file created, and they are no more secret than the passwords
beside them. A Langfuse somebody else runs gives you two keys of your own, from the project's
settings; they are then a password, and they belong in a file nobody commits.

## Six containers

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Langfuse's six containers. The assistant sends spans over OTLP to the web server. The web server writes each incoming batch to object storage (MinIO) and puts a job on a queue (Redis). The worker takes the job, reads the batch and writes traces and observations into ClickHouse. PostgreSQL holds users, projects, keys, model prices and prompts. The web server reads from ClickHouse and PostgreSQL to answer the screens and the API.\"><rect x=\"150\" y=\"14\" width=\"556\" height=\"256\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"12\" y=\"112\" width=\"116\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant.py</text><text x=\"70\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\"></text><rect x=\"172\" y=\"112\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"242\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">screens, API, OTLP</text><rect x=\"360\" y=\"30\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MinIO</text><text x=\"435\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every batch, as it came</text><rect x=\"360\" y=\"112\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Redis</text><text x=\"435\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the queue</text><rect x=\"546\" y=\"112\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">worker</text><text x=\"619\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">files what arrived</text><rect x=\"546\" y=\"200\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClickHouse</text><text x=\"619\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traces, observations, scores</text><rect x=\"172\" y=\"200\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"242\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">projects, keys, prices, prompts</text><path d=\"M128 136 L172 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">OTLP / HTTP</text><path d=\"M312 124 L360 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M312 136 L360 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510 136 L546 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 124 L510 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M619 160 L619 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 224 L312 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M242 160 L242 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "What arrives is kept first and processed after. A trace is in the API only once the worker has filed it."}
```

| container | what it holds | why it is separate |
|---|---|---|
| `web` | the screens, the public API, and the endpoint that receives OTLP | it is what people and programs talk to |
| `worker` | nothing; it moves what arrived into place | ingestion can lag without slowing the screens |
| `postgres` | users, projects, keys, model prices, prompts | small, relational, changes rarely |
| `clickhouse` | traces, observations, scores | large, appended, read by aggregation |
| `redis` | the queue between `web` and `worker` | so that a burst of traces waits instead of failing |
| `minio` | every batch that arrived, as it arrived | S3-compatible storage; the source the worker reads from |

That is more machinery than Jaeger's single binary, and it is the cost of a database built for the
questions in the next sections: sums of tokens and cost by day and user over a great many
observations. It also has a consequence the transcripts show: **a span sent now is not in the API
now**. It is in the queue, then in the worker, then in ClickHouse. When a query in this lesson comes
back with less than you sent, wait twenty seconds and ask again; the recording waited that long after
every replay.

## Stopping it

```sh
docker compose -f ~/langfuse/docker-compose.yml down
```

That stops the six and keeps what they stored, so the next `up -d` finds your traces where you left
them. `down -v` also deletes the stored data, and `docker image rm` with the six image names gives
back the 5.4 GB. Lesson 7 runs another tool under Docker, and stopping Langfuse first leaves it the
memory.
