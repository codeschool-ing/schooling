---
title: Gunicorn and Uvicorn instead of runserver
version: 1
---

`runserver` has said it at every start since lesson 2: *this is a development server, do not use it
in a production setting*. It reloads on every change, serves static files the slow way, and is built
to be convenient rather than to survive. A server runs the application under an **application
server**: **Gunicorn** for Django's WSGI side, and Uvicorn, which agenda-api already uses, for ASGI.

```
ana@vm:~/agenda$ uv add gunicorn
Resolved 42 packages in 756ms
Prepared 1 package in 50ms
Installed 1 package in 3ms
 + gunicorn==26.2.0
```

Gunicorn takes the WSGI application by its import path, `config.wsgi`, the module `startproject`
wrote in lesson 2 and nothing has used until now:

```
ana@vm:~/agenda$ uv run --env-file .env gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
[2026-10-23 00:55:29 +0000] [319] [INFO] Starting gunicorn 26.2.0
[2026-10-23 00:55:29 +0000] [319] [INFO] Listening at: http://127.0.0.1:8000 (319)
[2026-10-23 00:55:29 +0000] [319] [INFO] Using worker: sync
[2026-10-23 00:55:29 +0000] [320] [INFO] Booting worker with pid: 320
[2026-10-23 00:55:29 +0000] [321] [INFO] Booting worker with pid: 321
[2026-10-23 00:55:29 +0000] [322] [INFO] Booting worker with pid: 322
[2026-10-23 00:55:29 +0000] [319] [INFO] Control socket listening at /run/user/1000/gunicorn.ctl
ana@vm:~/agenda$ ps -o pid,ppid,cmd --forest -C gunicorn | cut -c1-90
    PID    PPID CMD
    319     316 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn conf
    320     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
    321     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
    322     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/
200
```

**One master and three workers.** The master opens the socket and does nothing else; each worker is a
separate process with its own copy of Django, answering one request at a time. A common starting
point is two or three workers per processor, adjusted after watching the machine under real load.
Kill a worker, as a crash or the kernel's out-of-memory killer would:

```
ana@vm:~/agenda$ kill -9 $(pgrep -n gunicorn)
```

The master noticed at once and started another:

```
[2026-10-23 00:55:34 +0000] [319] [ERROR] Worker (pid:322) was sent SIGKILL! Perhaps out of memory?
[2026-10-23 00:55:34 +0000] [351] [INFO] Booting worker with pid: 351
[2026-10-23 00:55:34 +0000] [319] [INFO] Control socket listening at /run/user/1000/gunicorn.ctl
```

## Uvicorn's workers

agenda-api ran with `--workers 4` in lesson 10. Uvicorn's own process manager does what
Gunicorn's master does, so it needs no Gunicorn in front:

```
ana@vm:~/agenda-api$ uv run uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started parent process [376]
INFO:     Started server process [378]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [379]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

The workers are Python processes started by `multiprocessing`, which is the name `pgrep` finds them
by. Kill one:

```
ana@vm:~/agenda-api$ kill -9 $(pgrep -f 'multiprocessing.spawn' | head -1)
```

```
INFO:     Waiting for child process [378]
INFO:     Child process [378] died
INFO:     Started server process [496]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Gunicorn with Uvicorn workers** is the older way to get the same supervision for an ASGI
application, and it is still common; since Uvicorn 0.30 its own manager restarts dead workers, which
is all agenda-api needs. Django can also run under Uvicorn, through `config.asgi`, as lesson 9 did:
that is the choice for a Django project with async views, and Gunicorn for one without.
