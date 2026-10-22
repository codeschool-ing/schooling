---
title: A second project, beside the first
version: 1
---

From this lesson to lesson 10, agenda's API is built again in FastAPI, in a project of its own beside
the Django one. Same events, same rules, a different set of assumptions, which is the comparison
lesson 1 promised. It starts the way `hello-fastapi` did, with one addition:

```
ana@vm:~$ mkdir agenda-api && cd agenda-api && uv init --bare && uv add fastapi uvicorn "pydantic[email]"
Initialized project `agenda-api`
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 17 packages in 287ms
Prepared 4 packages in 61ms
Installed 16 packages in 8ms
 + annotated-doc==0.0.5
 + annotated-types==0.8.0
 + anyio==4.15.1
 + click==8.5.0
 + dnspython==2.9.0
 + email-validator==2.3.0
 + fastapi==0.161.1
 + h11==0.16.0
 + idna==3.20
 + opentelemetry-api==1.45.1
 + pydantic==2.14.1
 + pydantic-core==2.50.1
 + starlette==1.9.0
 + typing-extensions==4.16.0
 + typing-inspection==0.4.4
 + uvicorn==0.54.0
```

`pydantic[email]` is Pydantic with an **extra**: the optional dependencies needed to validate email
addresses, which brought `email-validator` and `dnspython` with it. The square brackets are lesson 19
of `python`'s optional dependencies, seen from the installing side.

## A package, not a file

`hello-fastapi` was one file. This API will have several modules, so it lives in a package, `app`:

```
ana@vm:~/agenda-api$ mkdir app && touch app/__init__.py
```

Until lesson 10 gives it a database, the events live in a dictionary keyed by slug, with the same
three as agenda. Save this as `app/store.py`:

```python
# app/store.py
from datetime import datetime
from zoneinfo import ZoneInfo

SAO_PAULO = ZoneInfo("America/Sao_Paulo")

EVENTS = {
    "django-night": {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": datetime(2026, 11, 12, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": "",
    },
    "async-workshop": {
        "slug": "async-workshop",
        "title": "Async Python workshop",
        "starts_at": datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),
        "venue": "Public Library, lab 2",
        "capacity": 12,
        "description": "",
    },
    "testing-dojo": {
        "slug": "testing-dojo",
        "title": "Testing dojo",
        "starts_at": datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 20,
        "description": "",
    },
}

REGISTRATIONS = []
```

And the first version of `app/main.py`, which only lists them:

```python
# app/main.py
from fastapi import FastAPI

from .store import EVENTS

app = FastAPI(title="agenda API", version="0.1.0")


@app.get("/events")
def list_events():
    return list(EVENTS.values())
```

```
ana@vm:~/agenda-api$ find . -path ./.venv -prune -o -type f -print | sort
./app/__init__.py
./app/main.py
./app/store.py
./pyproject.toml
./uv.lock
```

## Running it, and running it again on every save

Start Uvicorn in a terminal of its own, on port **8001**, so it never fights the Django project for
8000:

```sh
uv run uvicorn app.main:app --reload --port 8001
```

`app.main:app` is the module `app.main` and the object `app` in it. **`--reload`** watches the
project's files and restarts the server when one changes, which Django's `runserver` does without
being asked. From the second terminal:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events | python3 -m json.tool | head -12
[
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00:00-03:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": ""
    },
    {
        "slug": "async-workshop",
        "title": "Async Python workshop",
```

And in the first, what the server printed from its start to that request:

```
ana@vm:~/agenda-api$ uv run uvicorn app.main:app --reload --port 8001
INFO:     Will watch for changes in these directories: ['/home/ana/agenda-api']
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started reloader process [204] using StatReload
INFO:     Started server process [206]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:37710 - "GET /events HTTP/1.1" 200 OK
```

The reloader is one process and the server another, which is why two process numbers appear.

The function returned a list of dictionaries holding `datetime` objects, and **FastAPI turned them
into JSON** without a serializer: the dates as ISO 8601 strings with their offset. That conversion
is FastAPI's `jsonable_encoder`, and the next sections replace "whatever the function returned"
with a declared shape.
