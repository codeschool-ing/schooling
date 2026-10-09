---
title: O Langfuse rodando na sua máquina
version: 2
---

O Langfuse é de código aberto, e a versão que esta aula usa roda no seu computador a partir das
imagens que os autores publicam, sob o **Docker**. Se o Docker ainda não está na sua máquina, este é o
único lugar do curso que o instala. No Ubuntu 24.04, direto ou na máquina virtual da aula 1:

```sh
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
```

A segunda linha deixa você rodar `docker` sem `sudo`, e vale a partir do próximo login: saia e entre
de novo, ou abra um terminal novo com `newgrp docker`. Num Mac ou no Windows, o Docker Desktop dá os
mesmos dois comandos, `docker` e `docker compose`. Essas duas linhas não foram rodadas para este curso:
a máquina da gravação já tinha o Docker 29.8 com o Compose 5.6, e o que vem a seguir só precisa de um
Compose que leia arquivos da versão 2, o que todo Compose atual faz.

## O arquivo compose

O Langfuse não é um programa, são seis, e um **arquivo compose** diz que imagens iniciar, como elas se
acham e o que cada uma recebe de configuração. Crie um diretório para ele, fora de `~/obs`, com
`mkdir -p ~/langfuse`, e salve isto nele como `~/langfuse/docker-compose.yml`:

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

Todo segredo ali, as senhas, `SALT`, `ENCRYPTION_KEY` e `NEXTAUTH_SECRET`, é um valor provisório que não
abre nada, e isso só é seguro porque o servidor web é publicado em 127.0.0.1, onde só você o alcança. As
linhas `LANGFUSE_INIT_*` criam uma organização, um projeto chamado `support-assistant`, as duas chaves de
API dele e um usuário na primeira vez que o servidor sobe, para que você nunca precise passar por uma
tela de cadastro. Você ainda pode abrir http://localhost:3000 num navegador e entrar como
`ana@marginalia.example` com a senha do arquivo: tudo o que esta aula pergunta pela API, as telas
mostram.

## Subindo

```sh
docker compose -f ~/langfuse/docker-compose.yml up -d
```

Na primeira vez, o Docker baixa as seis imagens antes de iniciar qualquer coisa, e descompactadas elas
ocupam **5,4 GB** de disco, a maior coisa que este curso instala depois do modelo. A transcrição abaixo
é uma subida posterior, com as imagens já presentes:

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

O `-d` os deixa rodando em segundo plano, e eles continuam rodando até você pará-los, de um terminal
para outro, mas não depois de um reinício do Docker, a menos que você os suba de novo. Na primeira vez
o servidor leva mais ou menos um minuto migrando os bancos; até lá a verificação de saúde abaixo não
responde nada. Depois:

```
ana@dev:~/obs$ curl -s $LANGFUSE_BASE_URL/api/public/health; echo
{"status":"OK","version":"3.225.11"}
```

O que seis contêineres custam parados, e o disco que as imagens e os dados delas ocupam:

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

Parados, os seis seguram cerca de **2,2 GB de memória** entre eles, metade no servidor web, e o
ClickHouse mantém um processador ocupado arrumando as próprias tabelas mesmo sem nada chegando. Com o
modelo respondendo ao mesmo tempo, passa de 5 GB, e é por isso que a aula 1 pediu 8 GB no computador
inteiro. Numa máquina com menos, pare o Langfuse quando não estiver usando, e o modelo recebe a memória
de volta.

## As chaves, onde os programas as procuram

Os programas do resto desta aula leem do ambiente onde o Langfuse está e as duas chaves do projeto, e o
SDK do próprio Langfuse também, uma das duas bibliotecas que esta aula acrescenta:

```sh
cat >> ~/llmobs/bin/activate <<'EOF'
export LANGFUSE_BASE_URL=http://127.0.0.1:3000
export LANGFUSE_PUBLIC_KEY=pk-lf-local-0001
export LANGFUSE_SECRET_KEY=sk-lf-local-0001
EOF
source ~/llmobs/bin/activate
pip install langfuse==4.17.0 langsmith==0.14.4
```

As chaves são as que o arquivo compose criou, e não são mais secretas que as senhas ao lado delas. Um
Langfuse que outra pessoa roda dá a você duas chaves suas, nas configurações do projeto; aí elas são uma
senha, e ficam num arquivo que nunca vai para o repositório.

## Seis contêineres

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Os seis contêineres do Langfuse. O assistente manda spans por OTLP ao servidor web. O servidor web grava cada lote recebido no armazenamento de objetos (MinIO) e põe uma tarefa numa fila (Redis). O worker pega a tarefa, lê o lote e grava traces e observações no ClickHouse. O PostgreSQL guarda usuários, projetos, chaves, preços de modelos e prompts. O servidor web lê do ClickHouse e do PostgreSQL para responder às telas e à API.\"><rect x=\"150\" y=\"14\" width=\"556\" height=\"256\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"12\" y=\"112\" width=\"116\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant.py</text><text x=\"70\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\"></text><rect x=\"172\" y=\"112\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"242\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">telas, API, OTLP</text><rect x=\"360\" y=\"30\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MinIO</text><text x=\"435\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada lote, como chegou</text><rect x=\"360\" y=\"112\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Redis</text><text x=\"435\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fila</text><rect x=\"546\" y=\"112\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">worker</text><text x=\"619\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquiva o que chegou</text><rect x=\"546\" y=\"200\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClickHouse</text><text x=\"619\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traces, observações, notas</text><rect x=\"172\" y=\"200\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"242\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">projetos, chaves, preços</text><path d=\"M128 136 L172 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">OTLP / HTTP</text><path d=\"M312 124 L360 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M312 136 L360 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510 136 L546 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 124 L510 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M619 160 L619 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 224 L312 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M242 160 L242 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "O que chega é guardado primeiro e processado depois. Um trace só está na API depois que o worker o arquivou."}
```

| contêiner | o que guarda | por que é separado |
|---|---|---|
| `web` | as telas, a API pública, e o endpoint que recebe OTLP | é com ele que pessoas e programas falam |
| `worker` | nada; ele põe no lugar o que chegou | a ingestão pode atrasar sem deixar as telas lentas |
| `postgres` | usuários, projetos, chaves, preços de modelos, prompts | pequeno, relacional, muda pouco |
| `clickhouse` | traces, observações, notas | grande, só cresce, lido por agregação |
| `redis` | a fila entre `web` e `worker` | para que uma rajada de traces espere em vez de falhar |
| `minio` | cada lote que chegou, como chegou | armazenamento compatível com S3; a fonte que o worker lê |

É mais maquinaria que o binário único do Jaeger, e é o preço de um banco feito para as perguntas das
próximas seções: somas de tokens e de custo por dia e por usuário sobre um número enorme de
observações. Isso também tem uma consequência que as transcrições mostram: **um span enviado agora não
está na API agora**. Ele está na fila, depois no worker, depois no ClickHouse. Quando uma consulta desta
aula voltar com menos do que você mandou, espere vinte segundos e pergunte de novo; a gravação esperou
isso depois de cada reprodução.

## Parando

```sh
docker compose -f ~/langfuse/docker-compose.yml down
```

Isso para os seis e guarda o que eles armazenaram, e o próximo `up -d` acha os seus traces onde você
os deixou. O `down -v` também apaga os dados armazenados, e `docker image rm` com os nomes das seis
imagens devolve os 5,4 GB. A aula 7 roda outra ferramenta, o Phoenix, e parar o Langfuse antes deixa
a memória para ela.