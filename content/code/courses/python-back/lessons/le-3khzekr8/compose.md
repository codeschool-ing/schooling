---
title: Compose: the whole of agenda in one file
version: 1
---

Lesson 16 ran seven processes from seven places. **Docker Compose** describes them in one file and
starts them together. A deployment is its own small project, a directory with the compose file and
the secrets for it. First, lesson 16's services give their ports back, since the containers take
them over:

```
ana@vm:~$ sudo systemctl disable --now agenda agenda-worker agenda-beat agenda-api
Removed "/etc/systemd/system/multi-user.target.wants/agenda.service".
Removed "/etc/systemd/system/multi-user.target.wants/agenda-beat.service".
Removed "/etc/systemd/system/multi-user.target.wants/agenda-api.service".
Removed "/etc/systemd/system/multi-user.target.wants/agenda-worker.service".
ana@vm:~$ mkdir deploy
```

The file, `~/deploy/compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "# compose.yaml\nservices:\n  db:\n    image: postgres:16\n    environment:\n      POSTGRES_USER: agenda_app\n      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}\n      POSTGRES_DB: agenda\n    volumes:\n      - db-data:/var/lib/postgresql/data\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U agenda_app -d agenda\"]\n      interval: 2s\n      retries: 15\n\n  api-db:\n    image: postgres:16\n    environment:\n      POSTGRES_USER: agenda_api_app\n      POSTGRES_PASSWORD: ${API_DATABASE_PASSWORD}\n      POSTGRES_DB: agenda_api\n    volumes:\n      - api-db-data:/var/lib/postgresql/data\n    healthcheck:\n      test: [\"CMD-SHELL\", \"pg_isready -U agenda_api_app -d agenda_api\"]\n      interval: 2s\n      retries: 15\n\n", "note": "**Two databases, each with a volume** for its data and a health check that answers only when PostgreSQL accepts connections. The passwords come from `.env` beside the file."}, {"code": "  redis:\n    image: redis:7\n\n", "note": "Redis as the broker, with nothing to configure."}, {"code": "  web:\n    image: agenda:0.1.0\n    restart: unless-stopped\n    environment: &django\n      DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}\n      DJANGO_ALLOWED_HOSTS: agenda.example.org\n      DJANGO_HSTS_SECONDS: \"3600\"\n      DATABASE_HOST: db\n      DATABASE_USER: agenda_app\n      DATABASE_PASSWORD: ${DATABASE_PASSWORD}\n      CELERY_BROKER_URL: redis://redis:6379/0\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    depends_on: &needs\n      db:\n        condition: service_healthy\n      redis:\n        condition: service_started\n\n", "note": "**The image, not a build.** `&django` names the environment so the worker and beat can reuse it; `db` and `redis` are the services' names, which the network resolves. The port is published on `127.0.0.1` only, for lesson 16's nginx."}, {"code": "  worker:\n    image: agenda:0.1.0\n    restart: unless-stopped\n    command: [\"celery\", \"-A\", \"config\", \"worker\", \"-l\", \"info\"]\n    environment: *django\n    depends_on: *needs\n\n  beat:\n    image: agenda:0.1.0\n    restart: unless-stopped\n    command: [\"celery\", \"-A\", \"config\", \"beat\", \"-l\", \"info\", \"-s\", \"/tmp/celerybeat-schedule\"]\n    environment: *django\n    depends_on: *needs\n\n", "note": "The same image with another command: what lesson 16 did with three unit files."}, {"code": "  api:\n    image: agenda-api:0.1.0\n    restart: unless-stopped\n    environment:\n      AGENDA_API_SECRET_KEY: ${API_SECRET_KEY}\n      AGENDA_API_DATABASE_URL: postgresql+psycopg://agenda_api_app:${API_DATABASE_PASSWORD}@api-db/agenda_api\n    ports:\n      - \"127.0.0.1:8001:8001\"\n    depends_on:\n      api-db:\n        condition: service_healthy\n\n", "note": "agenda-api, its URL assembled from the password in `.env`."}, {"code": "volumes:\n  db-data:\n  api-db-data:\n"}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Seven services on the network deploy_default. web runs Gunicorn on 8000, worker and beat run Celery; all three use db, which keeps its data in the volume db-data, and redis. api runs Uvicorn on 8001 and uses api-db, with the volume api-db-data. Only web and api publish a port, on 127.0.0.1.\"> <defs><marker id=\"cp-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"30\" width=\"680\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"36\" y=\"50\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the network deploy_default</text> <rect x=\"40\" y=\"70\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text> <text x=\"125\" y=\"103\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gunicorn, :8000</text> <rect x=\"40\" y=\"120\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">worker</text> <text x=\"125\" y=\"153\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">celery worker</text> <rect x=\"40\" y=\"170\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"188\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">beat</text> <text x=\"125\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">celery beat</text> <rect x=\"270\" y=\"70\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"340\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text> <text x=\"340\" y=\"103\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">volume db-data</text> <rect x=\"270\" y=\"145\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"340\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">redis</text> <rect x=\"470\" y=\"70\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"555\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api</text> <text x=\"555\" y=\"103\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uvicorn, :8001</text> <rect x=\"470\" y=\"145\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"555\" y=\"163\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api-db</text> <text x=\"555\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">volume api-db-data</text> <path d=\"M210 90 L266 90\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <path d=\"M210 140 L266 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <path d=\"M210 140 L266 160\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <path d=\"M210 190 L266 170\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <path d=\"M210 90 L266 158\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <path d=\"M555 110 L555 141\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#cp-a)\"></path> <text x=\"360\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Each service finds the others by name: db, redis, api-db. Only web and api publish a port, on 127.0.0.1.</text> </svg>", "caption": "compose.yaml drawn: lesson 16's processes as containers, each application with a database of its own, found by name instead of address."}
```

Compose reads `${DATABASE_PASSWORD}` and the others from a `.env` beside the file. Generate it, as
lesson 15 did, and keep it to its owner:

```
ana@vm:~/deploy$ for name in DJANGO_SECRET_KEY DATABASE_PASSWORD API_SECRET_KEY API_DATABASE_PASSWORD; do echo "$name=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"; done > .env
ana@vm:~/deploy$ chmod 600 .env && cut -d= -f1 .env
DJANGO_SECRET_KEY
DATABASE_PASSWORD
API_SECRET_KEY
API_DATABASE_PASSWORD
ana@vm:~/deploy$ docker compose config --services
redis
db
web
worker
api-db
api
beat
```

Start the two databases and Redis first, and wait until they are healthy:

```
ana@vm:~/deploy$ docker compose up -d --wait db api-db redis 2>&1 | grep -v "^ *Image\|Pulling\|Pulled"
 Network deploy_default Creating 
 Volume deploy_api-db-data Creating 
 Volume deploy_db-data Creating 
 Volume deploy_api-db-data Creating 
 Network deploy_default Creating 
 Volume deploy_db-data Creating 
 Volume deploy_api-db-data Created 
 Volume deploy_api-db-data Created 
 Volume deploy_db-data Created 
 Volume deploy_db-data Created 
 Network deploy_default Created 
 Network deploy_default Created 
 Container deploy-redis-1 Creating 
 Container deploy-db-1 Creating 
 Container deploy-api-db-1 Creating 
 Container deploy-redis-1 Created 
 Container deploy-api-db-1 Created 
 Container deploy-db-1 Created 
 Container deploy-redis-1 Starting 
 Container deploy-api-db-1 Starting 
 Container deploy-db-1 Starting 
 Container deploy-redis-1 Started 
 Container deploy-api-db-1 Started 
 Container deploy-db-1 Started 
 Container deploy-redis-1 Waiting 
 Container deploy-db-1 Waiting 
 Container deploy-api-db-1 Waiting 
 Container deploy-redis-1 Healthy 
 Container deploy-api-db-1 Healthy 
 Container deploy-db-1 Healthy 
```

## Migrations, once

The databases are empty. **Migrations run as a one-off container**, before the applications start,
for reasons the next section gives:

```
ana@vm:~/deploy$ docker compose run --rm web python manage.py migrate 2>&1 | tail -3
  Applying events.0003_event_organiser... OK
  Applying events.0004_registration_confirmation_sent_at... OK
  Applying sessions.0001_initial... OK
ana@vm:~/deploy$ docker compose run --rm api alembic upgrade head 2>&1 | tail -3
INFO  [alembic.runtime.migration] Running upgrade  -> 0001, events and registrations
INFO  [alembic.runtime.migration] Running upgrade 0001 -> 0002, users
INFO  [alembic.runtime.migration] Running upgrade 0002 -> 0003, organisers and admins
```

Then everything, and a look:

```
ana@vm:~/deploy$ docker compose up -d --wait 2>&1 | tail -4
 Container deploy-api-1 Healthy 
 Container deploy-redis-1 Healthy 
 Container deploy-worker-1 Healthy 
 Container deploy-beat-1 Healthy 
ana@vm:~/deploy$ docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
SERVICE   STATUS                    PORTS
api       Up 2 seconds              127.0.0.1:8001->8001/tcp
api-db    Up 10 seconds (healthy)   5432/tcp
beat      Up 1 second               8000/tcp
db        Up 10 seconds (healthy)   5432/tcp
redis     Up 10 seconds             6379/tcp
web       Up 2 seconds              127.0.0.1:8000->8000/tcp
worker    Up 2 seconds              8000/tcp
ana@vm:~/deploy$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: agenda.example.org" -H "X-Forwarded-Proto: https" http://127.0.0.1:8000/events/
200
ana@vm:~/deploy$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8001/events
000
```

Django answers. **The API does not**, and its log says why:

```
ana@vm:~/deploy$ docker compose logs api 2>&1 | grep -m1 Error
api-1  | ModuleNotFoundError: No module named 'httpx2'
```

**The container found a bug the virtual machine had hidden.** `app/forecast.py` imports `httpx2`,
which lesson 8 added as a *development* dependency, for tests; lesson 9 then used it in the
application, and the virtual machine, which installs development dependencies, never complained.
The image installs with `--no-dev`, as production should. Move it:

```
ana@vm:~/agenda-api$ uv remove --dev httpx2
Resolved 39 packages in 17ms
Uninstalled 3 packages in 19ms
 - httpcore2==2.16.0
 - httpx2==2.16.0
 - truststore==0.10.5
ana@vm:~/agenda-api$ uv add httpx2
Resolved 43 packages in 21ms
Installed 3 packages in 3ms
 + httpcore2==2.16.0
 + httpx2==2.16.0
 + truststore==0.10.5
ana@vm:~/agenda-api$ docker build -q -t agenda-api:0.1.0 .
sha256:bbe04ab5c11aca2f2febf38e92f01f8a202219a6d1b1ec004668e1b072cfb8ea
ana@vm:~/deploy$ docker compose up -d --wait api 2>&1 | tail -1
 Container deploy-api-db-1 Healthy 
ana@vm:~/deploy$ curl -s http://127.0.0.1:8001/events; echo
[]
ana@vm:~/deploy$ docker compose logs --tail 2 worker
worker-1  | [2026-10-22 22:25:00,037: INFO/MainProcess] Task events.tasks.resend_unconfirmed[257f666b-3477-44cb-8ee6-46b80d070375] received
worker-1  | [2026-10-22 22:25:00,074: INFO/ForkPoolWorker-1] Task events.tasks.resend_unconfirmed[257f666b-3477-44cb-8ee6-46b80d070375] succeeded in 0.03509992900035286s: []
```

`restart: unless-stopped` had been restarting the API every time it failed; with the new image it
stays up, with an empty list of events from its new database. The worker reaches Redis by its service
name, and has already run the sweep that beat sends it.

## Data that outlives the containers

Create a user, take everything down, and bring it up again:

```
ana@vm:~/deploy$ docker compose exec web python manage.py shell -v 0 -c "from django.contrib.auth.models import User; User.objects.create_user('ana', 'ana@example.org', 'not-a-real-password'); print(User.objects.count())"
1
ana@vm:~/deploy$ docker compose down 2>&1 | tail -3
 Container deploy-redis-1 Removed 
 Network deploy_default Removing 
 Network deploy_default Removed 
ana@vm:~/deploy$ docker compose up -d --wait 2>&1 | tail -2
 Container deploy-worker-1 Healthy 
 Container deploy-beat-1 Healthy 
ana@vm:~/deploy$ docker compose exec web python manage.py shell -v 0 -c "from django.contrib.auth.models import User; print(User.objects.count())"
1
ana@vm:~/deploy$ docker volume ls --format "{{.Name}}"
0f3298adbf94be349f07fbea123f89259cdb7197929ab590944e98fba822ca5e
deploy_api-db-data
deploy_db-data
f22bc6a8d39fd4d4232310d0672cdaf8d55e03abd94af3af2fe891323a0c7cd8
```

**Still one user.** `down` removed the containers and the network, and kept the **volumes**,
`deploy_db-data` and `deploy_api-db-data`. The two unnamed ones are Redis's: its image declares a
volume for `/data`, and each new Redis container was given a fresh one. `docker compose down --volumes` deletes them too, which on a server deletes the
database.
