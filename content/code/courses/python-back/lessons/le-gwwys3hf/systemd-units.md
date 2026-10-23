---
title: systemd units for every process
version: 1
---

A process started from a terminal stops when the terminal closes, does not start when the machine
boots, and nobody restarts it if it dies. **systemd** does all three: each long-running process gets
a **unit file**, and systemd starts it, restarts it, and keeps its output in the journal.

## Production settings

First what production needs from Django. Add to the end of `config/settings.py`:

```python
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", BASE_DIR / "staticfiles")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
```

`STATIC_ROOT` is where `collectstatic` gathers every app's static files, so that nginx can serve
them from one directory. The other five belong to HTTPS, which the last section of this lesson
brings, and they answer four of lesson 15's warnings. **`not DEBUG`** makes them follow the one flag:
off on your machine, on in production, where `DEBUG` is off.

```
ana@vm:~/agenda$ sed -n '/^STATIC_ROOT/,$p' config/settings.py
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", BASE_DIR / "staticfiles")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
ana@vm:~/agenda$ sudo install -d -o ana -g ana /var/www/agenda/static
ana@vm:~/agenda$ DJANGO_STATIC_ROOT=/var/www/agenda/static uv run --env-file .env python manage.py collectstatic --noinput

158 static files copied to '/var/www/agenda/static'.
ana@vm:~/agenda$ ls /var/www/agenda/static
admin
events
rest_framework
```

`/var/www/agenda/static` is outside the home directory on purpose: on Ubuntu 24.04 home directories
are closed to other users, and nginx runs as `www-data`.

## An environment file only root can read

Lesson 15 promised a file the service alone can read. systemd reads it **as root, before starting
the process**, so it can be root's alone. Build it from `.env`, without the development
`DJANGO_DEBUG`, and add what production sets:

```
ana@vm:~/agenda$ sudo install -d -m 755 /etc/agenda
ana@vm:~/agenda$ grep -v '^DJANGO_DEBUG=' .env | sudo install -m 600 /dev/stdin /etc/agenda/agenda.env
ana@vm:~/agenda$ printf 'DJANGO_ALLOWED_HOSTS=agenda.example.org\nDJANGO_STATIC_ROOT=/var/www/agenda/static\nDJANGO_HSTS_SECONDS=3600\n' | sudo tee -a /etc/agenda/agenda.env > /dev/null
ana@vm:~/agenda$ sudo install -m 600 ../agenda-api/.env /etc/agenda/agenda-api.env
ana@vm:~/agenda$ sudo ls -l /etc/agenda
total 8
-rw------- 1 root root 204 Oct 23 00:55 agenda-api.env
-rw------- 1 root root 293 Oct 23 00:55 agenda.env
ana@vm:~/agenda$ sudo cut -d= -f1 /etc/agenda/agenda.env
DJANGO_SECRET_KEY
DATABASE_USER
DATABASE_PASSWORD
DATABASE_HOST
DJANGO_ALLOWED_HOSTS
DJANGO_STATIC_ROOT
DJANGO_HSTS_SECONDS
```

`install -m 600` creates each file readable and writable by root only. The names are visible to
`sudo`; to anybody else, the file is closed, including ana:

```
ana@vm:~/agenda$ cat /etc/agenda/agenda.env
cat: /etc/agenda/agenda.env: Permission denied
```

## The units

One unit for the web application, in `/etc/systemd/system/agenda.service`:

```ini
# /etc/systemd/system/agenda.service
[Unit]
Description=agenda: Django under Gunicorn
After=network.target postgresql.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

| line | does |
|---|---|
| `After=` | start after the network and PostgreSQL, when they are on the same machine |
| `User=` | run as ana; a real server would have an account for the application alone |
| `EnvironmentFile=` | the variables, read by systemd as root |
| `ExecStart=` | the full path into the project's `.venv`: no `uv run`, nothing to resolve at boot |
| `Restart=on-failure` | start it again if it exits with an error |
| `WantedBy=` | start it at boot, once enabled |

The Celery worker and beat get one each, the same shape with a different command:

```ini
# /etc/systemd/system/agenda-worker.service
[Unit]
Description=agenda: Celery worker
After=network.target postgresql.service redis-server.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/celery -A config worker -l info
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/agenda-beat.service
[Unit]
Description=agenda: Celery beat, the one clock
After=network.target redis-server.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/celery -A config beat -l info
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

And agenda-api, with its own environment file and two Uvicorn workers. `--proxy-headers` and
`--forwarded-allow-ips` are for nginx, and the last section explains them:

```ini
# /etc/systemd/system/agenda-api.service
[Unit]
Description=agenda-api: FastAPI under Uvicorn
After=network.target postgresql.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda-api
EnvironmentFile=/etc/agenda/agenda-api.env
ExecStart=/home/ana/agenda-api/.venv/bin/uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001 --proxy-headers --forwarded-allow-ips 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

`daemon-reload` makes systemd read new unit files; `enable --now` starts each one and marks it to
start at boot:

```
ana@vm:~/agenda$ sudo systemctl daemon-reload
ana@vm:~/agenda$ sudo systemctl enable --now agenda agenda-worker agenda-beat agenda-api
Created symlink /etc/systemd/system/multi-user.target.wants/agenda.service → /etc/systemd/system/agenda.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-worker.service → /etc/systemd/system/agenda-worker.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-beat.service → /etc/systemd/system/agenda-beat.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-api.service → /etc/systemd/system/agenda-api.service.
ana@vm:~/agenda$ systemctl is-active agenda agenda-worker agenda-beat agenda-api
active
active
active
active
ana@vm:~/agenda$ systemctl status agenda --no-pager | head -12
● agenda.service - agenda: Django under Gunicorn
     Loaded: loaded (/etc/systemd/system/agenda.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-10-23 00:55:48 UTC; 6s ago
   Main PID: 725 (gunicorn)
        CPU: 878ms
     CGroup: /system.slice/agenda.service
             ├─725 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             ├─730 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             ├─736 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             └─739 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000

Oct 23 00:55:48 vm gunicorn[725]: [2026-10-23 00:55:48 +0000] [725] [INFO] Starting gunicorn 26.2.0
ana@vm:~/agenda$ journalctl -u agenda-api -n 6 --no-pager -o cat
INFO:     Started server process [734]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [732]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## Checking a running server

Lesson 14's tests checked agenda's code. A deployment is checked differently: every service active,
a worker answering, the application answering for its host name.

```
ana@vm:~/agenda$ systemctl is-active postgresql redis-server
active
active
ana@vm:~/agenda$ uv run --env-file .env celery -A config inspect ping
->  celery@vm: OK
        pong

1 node online.
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -H "Host: agenda.example.org" http://127.0.0.1:8000/events/
301 https://agenda.example.org/events/
ana@vm:~/agenda$ curl -s -H "Host: api.agenda.example.org" http://127.0.0.1:8001/events/django-night; echo
{"slug":"django-night","title":"Django Night","starts_at":"2026-11-12T19:00:00-03:00","venue":"Community Centre, room 3","capacity":40,"description":"","taken":1}
```

**`pong` from `celery@vm`** is the worker answering over Redis, which proves the broker and the worker
at once. The 301 is Django sending a plain-HTTP request to HTTPS, because `DEBUG` is off: nothing
answers on HTTPS yet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 266\" role=\"img\" aria-label=\"A browser talks only to nginx, which redirects port 80, terminates TLS on 443, serves /static/ from disk and adds headers. nginx passes requests to agenda.service, Gunicorn on port 8000 with three workers, and to agenda-api.service, Uvicorn on port 8001 with two workers. agenda-worker and agenda-beat run Celery. The applications use PostgreSQL; agenda and the Celery services use Redis.\"> <defs><marker id=\"lo-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"110\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"70\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a browser</text> <rect x=\"160\" y=\"90\" width=\"150\" height=\"86\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"235\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">nginx</text> <text x=\"235\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:80 redirects, :443 TLS</text> <text x=\"235\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/static/ from disk</text> <text x=\"235\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">adds headers</text> <path d=\"M120 133 L156 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"40\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">agenda.service</text> <text x=\"450\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gunicorn :8000, 3 workers</text> <path d=\"M310 133 L356 63\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"186\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">agenda-api.service</text> <text x=\"450\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uvicorn :8001, 2 workers</text> <path d=\"M310 133 L356 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"112\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"132\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">agenda-worker, agenda-beat</text> <text x=\"450\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Celery</text> <rect x=\"590\" y=\"60\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"645\" y=\"85\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text> <rect x=\"590\" y=\"150\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"645\" y=\"175\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Redis</text> <path d=\"M540 63 L586 80\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 209 L586 90\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 135 L586 170\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 70 L586 165\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#lo-a)\"></path> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Only nginx listens beyond the machine; everything behind it answers on 127.0.0.1.</text> </svg>", "caption": "agenda in production, as this lesson leaves it: seven services under systemd, one of them facing the world."}
```
