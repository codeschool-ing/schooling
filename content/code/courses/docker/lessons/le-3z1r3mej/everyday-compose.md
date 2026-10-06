---
title: Compose from day to day
version: 1
---

**Most of a working day with Compose is five commands**: `up`, `ps`, `logs`, `exec` and `down`.
`ps` and `logs` appeared in the previous section; this one is about the rest, and about what each
one keeps and throws away.

## `exec`: a command in a running service

```
ana@vm:~/shelf$ docker compose exec db psql -U shelf -c "INSERT INTO books (title, author) VALUES ('Grande Sertão: Veredas', 'João Guimarães Rosa')"
INSERT 0 1
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
{"id":4,"title":"Grande Sertão: Veredas","author":"João Guimarães Rosa"}
```

`docker compose exec db psql` runs `psql` inside the `db` container, which has it, with no port
published and no client installed on the machine. Ana adds a fourth book, and `shelf` serves it.

## `down` keeps the data

```
ana@vm:~/shelf$ docker compose down
 Container shelf-web-1 Stopping 
 Container shelf-web-1 Stopped 
 Container shelf-web-1 Removing 
 Container shelf-web-1 Removed 
 Container shelf-db-1 Stopping 
 Container shelf-db-1 Stopped 
 Container shelf-db-1 Removing 
 Container shelf-db-1 Removed 
 Network shelf_default Removing 
 Network shelf_default Removed 
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"
shelf_db-data
ana@vm:~/shelf$ docker compose up -d --wait
 Network shelf_default Creating 
 Network shelf_default Creating 
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
 Container shelf-db-1 Waiting 
 Container shelf-web-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
4
```

**`down` removes the containers and the network, and keeps the named volume.** `up` makes new
containers, attaches the same volume, and the fourth book is still there. `--wait` makes `up` return
only when every service with a health check reports healthy, which is what a script wants before it
sends the first request.

## A new version of the code

When the source changes, `up --build` rebuilds the image and recreates only what changed:

```
ana@vm:~/shelf$ sed -i "s/VERSION: 1.5.0/VERSION: 1.5.1/; s/image: shelf:1.5.0/image: shelf:1.5.1/" compose.yaml
ana@vm:~/shelf$ docker compose up -d --build --wait 2>&1 | grep -vE "^ *#|^$"
 Image shelf:1.5.1 Building 
 Image shelf:1.5.1 Built 
 Container shelf-db-1 Running 
 Container shelf-web-1 Recreate 
 Container shelf-web-1 Recreated 
 Container shelf-db-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
 Container shelf-db-1 Waiting 
 Container shelf-web-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/version
1.5.1
ana@vm:~/shelf$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
db        Up 22 seconds (healthy)
web       Up 5 seconds (healthy)
```

**`db` stayed `Running`; only `web` was recreated**, and `/version` answers `1.5.1`. Compose compares
each service's configuration and image with what is running and leaves alone what matches, so the
database never restarted for a change in the web tier.

## `down -v` throws it away

```
ana@vm:~/shelf$ docker compose down -v
 Container shelf-web-1 Stopping 
 Container shelf-web-1 Stopped 
 Container shelf-web-1 Removing 
 Container shelf-web-1 Removed 
 Container shelf-db-1 Stopping 
 Container shelf-db-1 Stopped 
 Container shelf-db-1 Removing 
 Container shelf-db-1 Removed 
 Volume shelf_db-data Removing 
 Network shelf_default Removing 
 Volume shelf_db-data Removed 
 Network shelf_default Removed 
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"; docker network ls --filter name=shelf --format "{{.Name}}"
```

**`-v` removes the named volumes as well**, and with them every book. That is what a test run wants
at the end, and what nobody wants on a machine that holds real data, so `-v` is typed on purpose and
never from habit.

| command | does |
| --- | --- |
| `docker compose up -d` | creates what is missing, starts everything, in dependency order |
| `docker compose up -d --build` | rebuilds images first, recreates what changed |
| `docker compose ps` | the project's containers and their health |
| `docker compose logs -f web` | one service's log, followed |
| `docker compose exec db psql` | a command inside a running service |
| `docker compose down` | removes containers and networks; keeps volumes |
| `docker compose down -v` | removes the volumes too |

Compose is the tool for **one machine**: a developer's laptop, a test run in CI (lesson 25), a small
server. It does not move containers between machines or replace a failed one elsewhere. Lesson 27
looks at what does.
