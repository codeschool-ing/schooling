---
title: The bookshop and its database, with Compose
version: 1
---

The image needs a database, and starting one by hand beside it, with the right network, the right
password and the right order, is several commands that have to be typed correctly every time.
**Docker Compose** reads one file that describes the containers an application is made of and starts
them with one command. The `docker` course gives it lesson 19; here it starts two containers, a
PostgreSQL of the bookshop's own and the bookshop, on a network only they share. The PostgreSQL that
lesson 9 installed is not used, and keeps running untouched.

## Two secrets, in a file that stays here

Compose substitutes `${NAME}` in its file from the environment, and from a file called `.env` in the
same directory. That file is where this deployment's two secrets live, so it must never reach a
repository or an image. If the bookshop is kept in git, which the `git` course earlier in the track
taught, create `.gitignore` with:

```
target/
.env
```

`.dockerignore` keeps it out of the image already: only the jar goes in. Now write the file itself,
with two values nobody has to invent:

```
ana@vm:~/bookshop$ echo "BOOKSHOP_DB_PASSWORD=$(openssl rand -hex 16)" > .env
ana@vm:~/bookshop$ echo "BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32)" >> .env
ana@vm:~/bookshop$ chmod 600 .env
ana@vm:~/bookshop$ cut -d= -f1 .env
BOOKSHOP_DB_PASSWORD
BOOKSHOP_JWT_SECRET
```

The database password is new and random: this PostgreSQL is a different server from lesson 9's, and
the password it is created with can be anything. `chmod 600` makes the file readable by you alone, and
`cut` shows the names without printing the values, which is how to check such a file with somebody
looking over your shoulder.

## The file

Create `compose.yaml` in `~/bookshop`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  db:\n    image: postgres:16-alpine", "note": "Two **services**, and the first is the database: PostgreSQL 16 in its small Alpine image, the one lesson 19's tests already started."}, {"code": "    environment:\n      POSTGRES_DB: bookshop\n      POSTGRES_USER: bookshop\n      POSTGRES_PASSWORD: ${BOOKSHOP_DB_PASSWORD:?set BOOKSHOP_DB_PASSWORD}", "note": "The official image reads these three variables the first time it starts with an empty data directory, and creates the database and its user from them. The password comes from `.env`, and `:?` makes Compose refuse to start when it is missing."}, {"code": "    volumes:\n      - db-data:/var/lib/postgresql/data", "note": "The data directory is a **named volume**, `db-data`, which outlives the container. Without it the catalogue would be lost every time the container was removed."}, {"code": "    healthcheck:\n      test: [\"CMD\", \"pg_isready\", \"-U\", \"bookshop\", \"-d\", \"bookshop\"]\n      interval: 2s\n      retries: 15\n", "note": "Docker runs `pg_isready` inside the container every two seconds, and the service counts as healthy once it answers."}, {"code": "  app:\n    build: .\n    image: bookshop:0.1.0", "note": "The application. `build: .` says how to make the image if it does not exist, and `image:` names it: the same `bookshop:0.1.0` the last section built."}, {"code": "    depends_on:\n      db:\n        condition: service_healthy", "note": "Started only after the database reports healthy. Without the condition, Compose would start both at once and Flyway would race PostgreSQL's own start-up."}, {"code": "    environment:\n      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/bookshop\n      SPRING_DATASOURCE_PASSWORD: ${BOOKSHOP_DB_PASSWORD}\n      BOOKSHOP_JWT_SECRET: ${BOOKSHOP_JWT_SECRET:?set BOOKSHOP_JWT_SECRET}\n      MANAGEMENT_SERVER_ADDRESS: 0.0.0.0", "note": "Configuration from the environment, as two sections ago. Inside Compose's network the database's host name is its service name, `db`. The management server listens on every interface of the container, because a port published from outside reaches the container on its own address and not on its loopback."}, {"code": "    ports:\n      - \"8080:8080\"\n      - \"127.0.0.1:8081:8081\"", "note": "The API on port 8080 of every interface of the machine; the management port only on the machine's own loopback, so lesson 22's rule still holds outside the container."}, {"code": "    mem_limit: 1g", "note": "A memory limit, which the JVM reads at start and sizes its heap from."}, {"code": "    healthcheck:\n      test:\n        - CMD\n        - bash\n        - -c\n        - exec 3<>/dev/tcp/127.0.0.1/8081 &&\n          printf 'GET /actuator/health/readiness HTTP/1.0\\r\\n\\r\\n' >&3 &&\n          grep -q '\"status\":\"UP\"' <&3\n      interval: 5s\n      retries: 20\n", "note": "The health check asks lesson 22's **readiness** probe. The image has no `curl`, so `bash` opens a TCP connection itself, writes an HTTP request into it, and `grep` succeeds only if the answer says `UP`. The folded lines are one command."}, {"code": "volumes:\n  db-data:", "note": "The volume, declared once for the whole file."}]}
```

Two services, one volume, and every value that differs between machines read from `.env`. The
`POSTGRES_USER` that the official image creates is the database's superuser; for a database that exists
only for this application that is common, and lesson 9's separate role is the shape to copy when the
database is shared.

`:?` is what makes a missing secret loud. `--env-file /dev/null` tells Compose to read an empty file
in place of `.env`, which is what a fresh checkout looks like:

```
ana@vm:~/bookshop$ docker compose --env-file /dev/null up -d
time="2026-10-22T20:09:45-03:00" level=warning msg="The \"BOOKSHOP_DB_PASSWORD\" variable is not set. Defaulting to a blank string."
error while interpolating services.db.environment.POSTGRES_PASSWORD: required variable BOOKSHOP_DB_PASSWORD is missing a value: set BOOKSHOP_DB_PASSWORD
```

Nothing was created. Without `:?`, Compose would have carried on with the blank string its warning
mentions, and the failure would have come later, from inside a container, in a log somebody has to go
and find.

## Starting it

`up -d` creates and starts everything in the background, and `--wait` returns only when every service
with a health check reports healthy:

```
ana@vm:~/bookshop$ docker compose up -d --wait
 Network bookshop_default Creating 
 Network bookshop_default Creating 
 Volume bookshop_db-data Creating 
 Volume bookshop_db-data Creating 
 Volume bookshop_db-data Created 
 Volume bookshop_db-data Created 
 Network bookshop_default Created 
 Network bookshop_default Created 
 Container bookshop-db-1 Creating 
 Container bookshop-db-1 Created 
 Container bookshop-app-1 Creating 
 Container bookshop-app-1 Created 
 Container bookshop-db-1 Starting 
 Container bookshop-db-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Starting 
 Container bookshop-app-1 Started 
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose ps
NAME             IMAGE                COMMAND                  SERVICE   CREATED          STATUS                    PORTS
bookshop-app-1   bookshop:0.1.0       "java -XX:MaxRAMPerc…"   app       13 seconds ago   Up 10 seconds (healthy)   0.0.0.0:8080->8080/tcp, 127.0.0.1:8081->8081/tcp
bookshop-db-1    postgres:16-alpine   "docker-entrypoint.s…"   db        13 seconds ago   Up 13 seconds (healthy)   5432/tcp
```

The database was created and became healthy, and only then did the bookshop start, as `depends_on`
asked; its own health check is lesson 22's readiness probe. Compose named everything after the
directory, `bookshop`. The `PORTS` column says the same as the file: 8080 on every address of the
machine, 8081 on its loopback only, and PostgreSQL's 5432 not published at all: the bookshop reaches
it over the network the two containers share.

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":5}
ana@vm:~/bookshop$ curl -s 127.0.0.1:8081/actuator/health/readiness
{"status":"UP"}
ana@vm:~/bookshop$ docker compose logs app | grep -E 'Successfully applied|Started BookshopApplication|Catalogue opened'
app-1  | 2026-10-22T23:09:51.544Z  INFO 1 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Successfully applied 3 migrations to schema "public", now at version v3 (execution time 00:00.031s)
app-1  | 2026-10-22T23:09:54.646Z  INFO 1 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.447 seconds (process running for 5.724)
app-1  | 2026-10-22T23:09:54.771Z  INFO 1 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
ana@vm:~/bookshop$ docker compose exec app ps -o pid,user,args
    PID USER     COMMAND
      1 bookshop java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
     70 bookshop ps -o pid,user,args
```

The catalogue came from the new database, which Flyway filled on its first start with the three
migrations of lessons 13 and 14. The log's times end in `Z`: the image has no time zone of its own,
so the JVM inside it runs on UTC, three hours ahead of the São Paulo clock the machine keeps. And the process list from inside the
container has two entries, the bookshop as **PID 1**, run by `bookshop`, and the `ps` that asked. The
section after this one is about why PID 1 matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The machine runs two containers on Compose's network bookshop_default: app, from the image bookshop:0.1.0, listening on 8080 and 8081, and db, from postgres:16-alpine, listening on 5432. app reaches db by its name. Port 8080 is published on every address of the machine, so another computer can reach it; 8081 is published on 127.0.0.1 only, so only the machine itself can. 5432 is not published. db keeps its data in the volume db-data, outside the container. The .env file gives both containers their secrets.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"30\" width=\"560\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"162\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the machine</text><rect x=\"320\" y=\"62\" width=\"380\" height=\"146\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"332\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Compose's network</text><text x=\"450\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bookshop_default</text><rect x=\"340\" y=\"92\" width=\"150\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"352\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bookshop:0.1.0</text><text x=\"352\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:8080</text><text x=\"352\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:8081</text><rect x=\"550\" y=\"92\" width=\"140\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"562\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"562\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">postgres:16-alpine</text><text x=\"562\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:5432</text><text x=\"562\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not published</text><path d=\"M 490 176 L 548 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"519\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">db:5432</text><rect x=\"530\" y=\"232\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"542\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db-data</text><text x=\"542\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">volume, outlives the containers</text><path d=\"M 620 192 L 620 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another computer</text><path d=\"M 20 146 L 338 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"162\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0.0.0:8080</text><path d=\"M 165 166 L 338 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"162\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:8081</text><text x=\"162\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">from the machine only</text><rect x=\"170\" y=\"232\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.env</text><text x=\"182\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the two secrets</text><path d=\"M 290 244 L 400 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path><path d=\"M 290 254 L 572 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "What compose.yaml builds: two containers on a network of their own, two published ports with different reach, and the data outside both containers."}
```

## What survives

`down` removes the containers and the network. The volume stays:

```
ana@vm:~/bookshop$ docker compose down
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 
 Container bookshop-app-1 Removing 
 Container bookshop-app-1 Removed 
 Container bookshop-db-1 Stopping 
 Container bookshop-db-1 Stopped 
 Container bookshop-db-1 Removing 
 Container bookshop-db-1 Removed 
 Network bookshop_default Removing 
 Network bookshop_default Removed 
ana@vm:~/bookshop$ docker compose up -d --wait
 Network bookshop_default Creating 
 Network bookshop_default Creating 
 Network bookshop_default Created 
 Network bookshop_default Created 
 Container bookshop-db-1 Creating 
 Container bookshop-db-1 Created 
 Container bookshop-app-1 Creating 
 Container bookshop-app-1 Created 
 Container bookshop-db-1 Starting 
 Container bookshop-db-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Starting 
 Container bookshop-app-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose logs app | grep -E 'Schema|Started BookshopApplication'
app-1  | 2026-10-22T23:10:06.084Z  INFO 1 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
app-1  | 2026-10-22T23:10:09.176Z  INFO 1 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.29 seconds (process running for 5.555)
```

`Schema "public" is up to date`: the second start found the first one's tables and rows. The data
lives in the volume, outside any container, and a container can be thrown away and replaced at any
time, which is how an image is updated: build a new one, run `up -d` again, and Compose replaces the
container whose image changed.

One consequence catches everybody once. The official PostgreSQL image reads `POSTGRES_PASSWORD` **only
when it creates the database**, on a first start with an empty volume. Change the password in `.env`
afterwards and the database keeps the old one, while the bookshop arrives with the new one and is
refused. Either change the role's password inside the database, or, when the data does not matter,
remove the volume and start again.

## Why `MANAGEMENT_SERVER_ADDRESS` is there

Lesson 22 bound the management server to 127.0.0.1, and `compose.yaml` overrides that with
`0.0.0.0`, which looks like undoing the lesson. Delete the line and try:

```
ana@vm:~/bookshop$ docker compose up -d --wait 2>&1 | tail -n 1
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose ps --format '{{.Name}}  {{.Status}}' app
bookshop-app-1  Up 10 seconds (healthy)
ana@vm:~/bookshop$ curl -sS 127.0.0.1:8081/actuator/health/readiness
curl: (56) Recv failure: Connection reset by peer
```

The container reports healthy, and the machine cannot reach the port it published. Both are right.
The health check runs **inside** the container, where 127.0.0.1 is where the management server now
listens. A published port arrives at the container's own network address, never at its loopback, so
from the machine nothing is listening. The rule of lesson 22 is kept by the other half of the setting:
the container listens on every address of its own, and Compose publishes 8081 on the machine's
loopback only. Put the line back:

```
ana@vm:~/bookshop$ docker compose up -d --wait 2>&1 | tail -n 1
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ curl -sS 127.0.0.1:8081/actuator/health/readiness
{"status":"UP"}
```
