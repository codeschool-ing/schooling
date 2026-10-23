---
title: FastAPI's background tasks
version: 1
---

FastAPI has something smaller built in: **`BackgroundTasks`**, functions that run in the same process
after the response has been sent. agenda-api sends its confirmation that way. The message, with the
standard library's `smtplib`, in `app/mail.py`:

```python
# app/mail.py
import smtplib
from email.message import EmailMessage


def confirmation(name: str, email: str, title: str) -> None:
    message = EmailMessage()
    message["From"] = "agenda API <agenda@example.org>"
    message["To"] = email
    message["Subject"] = f"You are registered for {title}"
    message.set_content(f"Hello {name},\n\nsee you there.\n")
    with smtplib.SMTP("127.0.0.1", 1025) as smtp:
        smtp.send_message(message)
```

In `app/main.py`, import `BackgroundTasks` from `fastapi` and `mail` from the package, give `register`
a parameter `background: BackgroundTasks`, and add the task just before `return row`:

```python
    background.add_task(mail.confirmation, row.name, row.email, event.title)
```

```
ana@vm:~/agenda-api$ grep -n 'BackgroundTasks\|background\|import mail' app/main.py
2:from fastapi import BackgroundTasks, FastAPI, HTTPException, status
7:from . import mail
72:def register(slug: str, registration: RegistrationIn, session: SessionDep, background: BackgroundTasks):
87:    background.add_task(mail.confirmation, row.name, row.email, event.title)
```

With the mail server running, register Maria:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{"name": "Maria", "email": "maria@example.org"}' -w ' %{http_code}\n'
{"name":"Maria","email":"maria@example.org","created_at":"2026-10-22T21:23:47.138589-03:00"} 201
```

```
---------- MESSAGE FOLLOWS ----------
From: agenda API <agenda@example.org>
To: maria@example.org
Subject: You are registered for Testing dojo
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
X-Peer: ('127.0.0.1', 58018)

Hello Maria,

see you there.
------------ END MESSAGE ------------
```

Now stop the mail server and register Nuno:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{"name": "Nuno", "email": "nuno@example.org"}' -w ' %{http_code}\n'
{"name":"Nuno","email":"nuno@example.org","created_at":"2026-10-22T21:23:48.873284-03:00"} 201
```

**201**, and in the API's terminal, the first lines and the last of what followed:

```
INFO:     127.0.0.1:36172 - "POST /events/testing-dojo/registrations HTTP/1.1" 201 Created
ERROR:    Exception in ASGI application
Traceback (most recent call last):
ConnectionRefusedError: [Errno 111] Connection refused
```

The response had already gone when the mail failed, so the client heard nothing of it, and **nothing
will retry**. The exception is in a log, and Nuno has no confirmation.

## Which one

| | `BackgroundTasks` | Celery |
|---|---|---|
| runs | in the web process, after the response | in worker processes, from a broker |
| survives a restart of the web server | **no**: queued work is lost | **yes**: it waits in Redis |
| retries | write them yourself | `autoretry_for`, `retry_backoff` |
| schedules | no | beat |
| costs | nothing to install | Redis, a worker and beat to run and watch |

**`BackgroundTasks` is for work whose loss nobody would notice**: a log line, a metric, a cache to
warm. A confirmation e-mail is not that, and agenda-api would need Celery too, which works with
FastAPI the same way: a Celery app, tasks, a worker, `.delay()` from the route. Django is not what
makes Celery fit; the need for a queue that outlives the request is.
