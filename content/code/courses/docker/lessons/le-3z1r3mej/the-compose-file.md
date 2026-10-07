---
title: The Compose file
version: 1
---

**`compose.yaml` describes the services an application is made of, and `docker compose` makes the
containers, networks and volumes that match it.** Ana's file says everything the commands of the
previous section said, and two things they could not:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_DB: shelf
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      timeout: 2s
      retries: 15
    restart: unless-stopped

  web:
    build:
      context: .
      args:
        VERSION: 1.5.0
    image: shelf:1.5.0
    env_file: shelf.env
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  db-data:

secrets:
  db_password:
    file: ./db_password.txt
```

Read it by service:

- **`db`** runs `postgres:17`, keeps its data in the named volume `db-data` (lesson 8), and has a
  **health check**. `pg_isready` asks Postgres whether it accepts connections. The `-h 127.0.0.1`
  matters: while it initialises, the image runs a temporary server that listens only on a local
  socket, and a `pg_isready` without `-h` would call that one ready.
- **`web`** is built from the Dockerfile in the same directory, with the image name and build
  argument written down. It is published on the loopback address only (lesson 17), and its
  `depends_on` waits for `db` to be **healthy**, not merely started. That is the order fixed.
- **`secrets`** hands the password to Postgres as a file. The official image reads
  `POSTGRES_PASSWORD_FILE` for exactly this.

The two files beside it hold what must not go into the repository:

```
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
```

```
lab-only-secret
```

```
.git
.env
*.env
db_password.txt
compose.yaml
testdata/
Dockerfile*
.dockerignore
```

```
ana@vm:~/shelf$ ls -l compose.yaml shelf.env db_password.txt
-rw-r--r-- 1 ana ana 755 Oct  6 15:12 compose.yaml
-rw-r--r-- 1 ana ana  16 Oct  6 15:12 db_password.txt
-rw-r--r-- 1 ana ana  60 Oct  6 15:12 shelf.env
```

**`.dockerignore` now leaves out both, and the Compose file**, so that none of them reaches a build
context; `.gitignore` should list the two secrets too. And both are `-rw-r--r--`, readable by every
user of Ana's machine, which the end of this section comes back to.

## One command

```
ana@vm:~/shelf$ docker compose up -d
 Network shelf_default Creating 
 Network shelf_default Creating 
 Volume shelf_db-data Creating 
 Volume shelf_db-data Creating 
 Volume shelf_db-data Created 
 Volume shelf_db-data Created 
 Network shelf_default Created 
 Network shelf_default Created 
 Container shelf-db-1 Creating 
 Container shelf-db-1 Created 
 Container shelf-web-1 Creating 
 Container shelf-web-1 Created 
 Container shelf-db-1 Starting 
 Container shelf-db-1 Started 
 Container shelf-db-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
ana@vm:~/shelf$ docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
SERVICE   STATUS                                     PORTS
db        Up 2 seconds (healthy)                     5432/tcp
web       Up Less than a second (health: starting)   127.0.0.1:8080->8080/tcp
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
ana@vm:~/shelf$ docker compose logs web
web-1  | 2026/10/06 18:12:24 catalogue: postgres
web-1  | 2026/10/06 18:12:24 shelf 1.5.0 listening on :8080
```

**The order in the output is the order the file asked for**: the network and the volume, then `db`,
then `Waiting` until `db` is `Healthy`, and only then `web`. The image `shelf:1.5.0` already existed,
so nothing was built. The catalogue answers, from Postgres, the first time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"What docker compose up made from compose.yaml, in the project shelf. A network, shelf_default, holds two containers. shelf-db-1 runs postgres:17, with the named volume shelf_db-data mounted at /var/lib/postgresql/data and the secret db_password, from the file db_password.txt, mounted at /run/secrets/db_password. shelf-web-1 runs shelf:1.5.0, built from the Dockerfile, with DATABASE_URL from shelf.env, and is published on 127.0.0.1:8080. An arrow labelled depends_on service_healthy runs from web to db: web is started only once db&#x27;s pg_isready check passes. web reaches db by the name db on port 5432, which is not published on the host.\"><defs><marker id=\"l19project-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19project-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l19project-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l19project-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"420\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"166\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">shelf_default</text><rect x=\"180\" y=\"70\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"260\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf-web-1</text><text x=\"260\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf:1.5.0</text><text x=\"260\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">env from shelf.env</text><rect x=\"390\" y=\"70\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"470\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf-db-1</text><text x=\"470\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">postgres:17</text><text x=\"470\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not published</text><path d=\"M340 96 L390 96\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-paper)\"></path><text x=\"365\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db:5432</text><path d=\"M340 120 L390 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l19project-ah-amber)\"></path><text x=\"365\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">starts after db is healthy</text><rect x=\"20\" y=\"85\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1:8080</text><path d=\"M130 105 L180 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-phosphor)\"></path><rect x=\"600\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">volume</text><text x=\"655\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shelf_db-data</text><rect x=\"600\" y=\"120\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">secret</text><text x=\"655\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db_password</text><path d=\"M600 82 L550 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-wire)\"></path><path d=\"M600 142 L550 126\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-wire)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all of it from compose.yaml, by docker compose up</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">docker compose down removes the containers and the network; -v removes the volume too</text></svg>", "caption": "One file, one command: a network, a volume, a secret and two containers, started in the right order."}
```

## What it made

```
ana@vm:~/shelf$ docker network ls --filter name=shelf --format "{{.Name}}\t{{.Driver}}"
shelf_default	bridge
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"
shelf_db-data
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Image}}"
NAMES         IMAGE
shelf-web-1   shelf:1.5.0
shelf-db-1    postgres:17
```

**Everything is named after the project**, which is the directory's name, `shelf`: the network
`shelf_default`, the volume `shelf_db-data`, the containers `shelf-db-1` and `shelf-web-1`. Two
projects on one machine never collide, and `docker compose` finds its own things again by that name.

## Where the password is now

```
ana@vm:~/shelf$ docker compose exec db ls -l /run/secrets/
total 4
-rw-r--r-- 1 30033 30033 16 Oct  6 18:12 db_password
ana@vm:~/shelf$ docker inspect shelf-db-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"POSTGRES\"))"
"POSTGRES_DB=shelf"
"POSTGRES_PASSWORD_FILE=/run/secrets/db_password"
"POSTGRES_USER=shelf"
ana@vm:~/shelf$ docker inspect shelf-web-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"DATABASE\"))"
"DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf"
```

**Postgres has the password in a file, and its environment names only the path.** `docker inspect`
on `db` shows no secret. On `web`, it still does: `shelf` reads `DATABASE_URL` from its environment,
and only a program written to read a file can take its secret as one. The file arrives
`-rw-r--r--`, owned by Ana's UID, because a Compose secret from a file is that file mounted as it
is: tighten it on the host and the container's user must still be able to read it.
