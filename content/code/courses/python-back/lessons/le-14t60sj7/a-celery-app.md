---
title: A Celery app and the first task
version: 1
---

Celery needs an **app** object, which knows the broker and finds the tasks. In a Django project it
lives beside the settings, in `config/celery.py`:

```python
# config/celery.py
import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

app = Celery("agenda")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

`config_from_object` reads every setting that starts with `CELERY_`, so the broker goes in
`settings.py` with the rest; `autodiscover_tasks` imports `tasks.py` from every installed app. The
app has to be loaded when Django starts, so that the `@shared_task` decorators find it; that is what
`config/__init__.py` is for:

```python
# config/__init__.py
from .celery import app as celery_app

__all__ = ("celery_app",)
```

Add the broker's address at the end of `config/settings.py`, and take the mail call and its import
back out of `events/api.py`:

```
ana@vm:~/agenda$ tail -1 config/settings.py
CELERY_BROKER_URL = "redis://127.0.0.1:6379/0"
ana@vm:~/agenda$ grep -c 'mail' events/api.py
0
```

A **task** is a function a worker runs. `events/tasks.py`:

```python
# events/tasks.py
from celery import shared_task

from . import mail
from .models import Registration


@shared_task
def send_confirmation(registration_id):
    registration = Registration.objects.select_related("event").get(pk=registration_id)
    mail.confirmation(registration)
```

**It takes an id, not a registration.** The arguments travel through Redis as JSON, and a model
instance is not JSON; the id is, and the worker reads the row as it is when the task runs.
`register` starts it, in `events/services.py`:

```schooling-example
{"language": "python", "file": "events/services.py", "parts": [{"code": "# events/services.py\nfrom django.db import transaction\n\nfrom .models import Event, Registration\nfrom .tasks import send_confirmation\n\n\nclass RegistrationRefused(Exception):\n    pass\n\n\n", "note": "`services.py` now imports the task it starts."}, {"code": "def register(event_id, name, email):\n    with transaction.atomic():\n        event = Event.objects.select_for_update().get(pk=event_id)\n        if event.registrations.count() >= event.capacity:\n            raise RegistrationRefused(\"This event is full.\")\n        if event.registrations.filter(email=email).exists():\n            raise RegistrationRefused(\"This address is already registered.\")\n        registration = Registration.objects.create(event=event, name=name, email=email)\n", "note": "The same locked transaction as lesson 4."}, {"code": "        transaction.on_commit(lambda: send_confirmation.delay(registration.pk))\n        return registration\n", "note": "**`on_commit` waits for the commit.** A task queued inside the transaction could reach a fast worker before the row exists, or for a row that a rollback then removes."}]}
```

`.delay(...)` sends the message and returns at once; the function runs in another process.

## The worker

Start the mail server again, then the worker, in a terminal of its own:

```
ana@vm:~/agenda$ uv run celery -A config worker -l info
 
 -------------- celery@vm v5.6.3 (recovery)
--- ***** ----- 
-- ******* ---- Linux-6.18.44-fc-v153-x86_64-with-glibc2.39 2026-10-22 21:18:20
- *** --- * --- 
- ** ---------- [config]
- ** ---------- .> app:         agenda:0x7fa349fcd5b0
- ** ---------- .> transport:   redis://127.0.0.1:6379/0
- ** ---------- .> results:     disabled://
- *** --- * --- .> concurrency: 4 (prefork)
-- ******* ---- .> task events: OFF (enable -E to monitor tasks in this worker)
--- ***** ----- 
 -------------- [queues]
                .> celery           exchange=celery(direct) key=celery
                

[tasks]
  . events.tasks.send_confirmation

[2026-10-22 21:18:21,053: INFO/MainProcess] Connected to redis://127.0.0.1:6379/0
[2026-10-22 21:18:21,055: INFO/MainProcess] mingle: searching for neighbors
[2026-10-22 21:18:22,060: INFO/MainProcess] mingle: all alone
[2026-10-22 21:18:22,070: INFO/MainProcess] celery@vm ready.
```

The banner names the broker, four worker processes (one per processor of this machine), and the one
task it found. Now register Hana:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Hana", "email": "hana@example.org"}' -w ' %{http_code}\n'
{"name":"Hana","email":"hana@example.org","created_at":"2026-10-22T21:18:32.144005-03:00"} 201
```

In the worker's terminal:

```
[2026-10-22 21:18:32,191: INFO/MainProcess] Task events.tasks.send_confirmation[c745f2f3-5316-4f19-9032-749415ba5d7b] received
[2026-10-22 21:18:32,219: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[c745f2f3-5316-4f19-9032-749415ba5d7b] succeeded in 0.02728721299990866s: None
```

And in the mail server's:

```
---------- MESSAGE FOLLOWS ----------
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
Subject: You are registered for Testing dojo
From: agenda <agenda@example.org>
To: hana@example.org
Date: Fri, 23 Oct 2026 00:18:32 +0000
Message-ID: <179271471221.547.7531978724815521150@vm>
X-Peer: ('127.0.0.1', 54156)

Hello Hana,

see you on 26 November at 19:00, at Community Centre, room 3.
------------ END MESSAGE ------------
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"register() commits the registration. on_commit then calls delay with the registration's id, which puts a message on the Redis list called celery, and the API answers 201 to the client. A worker with four processes takes the message from Redis and talks to the mail server.\"> <defs><marker id=\"q-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">register()</text> <text x=\"95\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the row, committed</text> <rect x=\"190\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"265\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">on_commit</text> <text x=\"265\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.delay(registration.pk)</text> <rect x=\"360\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"435\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Redis</text> <text x=\"435\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the list called celery</text> <rect x=\"530\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"605\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">worker</text> <text x=\"605\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 processes</text> <path d=\"M170 75 L186 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M340 75 L356 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M510 75 L526 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <rect x=\"530\" y=\"140\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"605\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mail server</text> <path d=\"M605 100 L605 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M265 100 L265 150 L120 150\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#q-a)\"></path> <text x=\"110\" y=\"165\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">201 to the client</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The request ends when the message is in Redis; the mail is the worker's problem.</text> </svg>", "caption": "Where the confirmation goes after lesson 13. The request waits for Redis, not for the mail server."}
```

## A task that fails is gone

Stop the mail server again, and register Ivo:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Ivo", "email": "ivo@example.org"}' -w ' %{http_code}\n'
{"name":"Ivo","email":"ivo@example.org","created_at":"2026-10-22T21:18:34.976204-03:00"} 201
```

**201**: the registration no longer depends on the mail server, which was the point. The first two
lines in the worker's terminal, before the traceback:

```
[2026-10-22 21:18:34,987: INFO/MainProcess] Task events.tasks.send_confirmation[52b878e9-8e01-462e-ac46-bdb8edb7314e] received
[2026-10-22 21:18:34,999: ERROR/ForkPoolWorker-1] Task events.tasks.send_confirmation[52b878e9-8e01-462e-ac46-bdb8edb7314e] raised unexpected: ConnectionRefusedError(111, 'Connection refused')
```

**The task raised, and that was the end of it.** Ivo is registered, has no confirmation, and nothing
will try again. The next section fixes that.
