---
title: SQLAlchemy, and the engine
version: 1
---

Django came with its database layer. FastAPI does not: it handles requests and leaves storage to
you. The library nearly every Python project outside Django uses for that is **SQLAlchemy**, and the
one that changes its tables over time is **Alembic**, written by the same author. SQLModel, which
FastAPI's own tutorial uses, is a layer over SQLAlchemy, so what this lesson teaches is underneath it
too.

The API gets a database of its own in the PostgreSQL that lesson 4 installed. In `~/agenda-api`, add
the two libraries and the same driver Django uses, then create the database:

```
ana@vm:~/agenda-api$ uv add sqlalchemy psycopg alembic
Resolved 27 packages in 259ms
Downloading sqlalchemy (4.5MiB)
 Downloaded sqlalchemy
Prepared 4 packages in 127ms
Installed 5 packages in 4ms
 + alembic==1.20.1
 + mako==1.4.3
 + markupsafe==3.0.4
 + psycopg==3.3.6
 + sqlalchemy==2.1.6
ana@vm:~/agenda-api$ createdb agenda_api
```

`createdb` worked without a password because lesson 4 made `ana` a PostgreSQL role, and a local
connection as the same user is let in by **peer authentication**: PostgreSQL asks the operating
system who is on the other end of the socket.

## One engine per process

Everything SQLAlchemy sends goes through an **engine**. Create one in a new module, `app/db.py`:

```python
# app/db.py
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg:///agenda_api")
```

The URL says everything about where to connect:

| part | meaning |
|---|---|
| `postgresql` | the dialect: which SQL to write |
| `+psycopg` | the driver: which library carries it |
| `///` | no user, no password and no host: the local socket, as the operating system user |
| `agenda_api` | the database |

**`create_engine` does not connect.** It builds a **pool**, which opens connections the first time
something asks for one and keeps them open for the next. A short script, `hello_db.py`, asks for one:

```python
# hello_db.py
from sqlalchemy import text

from app.db import engine

with engine.connect() as connection:
    result = connection.execute(text("select current_user, current_database()"))
    print(result.one())
```

```
ana@vm:~/agenda-api$ uv run python hello_db.py
('ana', 'agenda_api')
```

`text()` is raw SQL, run on a connection borrowed from the pool and returned when the `with` block
ends. This is **Core**, the half of SQLAlchemy that speaks in SQL statements. The other half, the
**ORM**, speaks in objects, and it is built on top of Core:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Five boxes from left to right: your code, which works with Event objects; the Session, which keeps an identity map and a unit of work; the Engine, a pool of connections; psycopg, the driver; and PostgreSQL with the database agenda_api. An ORM query enters at the Session; a Core query with text enters at the Engine.\"> <defs><marker id=\"ly-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"40\" width=\"100\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"70.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your code</text> <text x=\"70.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Event objects</text> <rect x=\"136\" y=\"40\" width=\"190\" height=\"58\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"231.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Session</text> <text x=\"231.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">identity map, unit of work</text> <rect x=\"342\" y=\"40\" width=\"120\" height=\"58\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"402.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Engine</text> <text x=\"402.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a pool of connections</text> <rect x=\"478\" y=\"40\" width=\"90\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"523.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">psycopg</text> <text x=\"523.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the driver</text> <rect x=\"584\" y=\"40\" width=\"116\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"642.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">PostgreSQL</text> <text x=\"642.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">agenda_api</text> <path d=\"M120 69 L132 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M326 69 L338 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M462 69 L474 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M568 69 L580 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <text x=\"136\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORM: session.scalars(select(Event))</text> <text x=\"342\" y=\"150\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Core: connection.execute(text(...))</text> <path d=\"M231 134 L231 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ly-a)\"></path> <path d=\"M402 156 L402 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ly-a)\"></path> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The ORM is built on Core; both send their SQL through the same engine.</text> </svg>", "caption": "SQLAlchemy in layers. hello_db.py went in at the engine; seed.py and queries.py at the session."}
```

Create the engine **once per process**, at import, as `app/db.py` does. An engine per request would
open a connection per request, which is the cost the pool exists to avoid. And the URL sitting in the
code is a lesson-15 problem: there it moves into the environment, with a password, over TCP.
