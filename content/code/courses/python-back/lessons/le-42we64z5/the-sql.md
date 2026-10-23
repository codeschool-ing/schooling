---
title: The SQL behind a QuerySet
version: 1
---

An ORM saves writing SQL. It does not save knowing what SQL it wrote, because the database runs that
SQL and not the Python. Django lets you see it in three ways, and `sql.py` uses all three:

```python
# sql.py
from django.db import connection, reset_queries

from events.models import Event

events = Event.objects.filter(venue__startswith="Community").order_by("-starts_at")
print(events.query)
reset_queries()
titles = [e.title for e in events]
print(len(connection.queries), "query:", connection.queries[0]["sql"])
print(events.explain())
```

```
ana@vm:~/agenda$ uv run python manage.py shell < sql.py
14 objects imported automatically (use -v 2 for details).

SELECT "events_event"."id", "events_event"."title", "events_event"."slug", "events_event"."starts_at", "events_event"."venue", "events_event"."capacity", "events_event"."description" FROM "events_event" WHERE "events_event"."venue"::text LIKE Community% ORDER BY "events_event"."starts_at" DESC
1 query: SELECT "events_event"."id", "events_event"."title", "events_event"."slug", "events_event"."starts_at", "events_event"."venue", "events_event"."capacity", "events_event"."description" FROM "events_event" WHERE "events_event"."venue"::text LIKE 'Community%' ORDER BY "events_event"."starts_at" DESC
Sort  (cost=10.88..10.89 rows=1 width=1006)
  Sort Key: starts_at DESC
  ->  Seq Scan on events_event  (cost=0.00..10.88 rows=1 width=1006)
        Filter: ((venue)::text ~~ 'Community%'::text)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Three chained calls, Event.objects, filter and order_by, build a QuerySet and send no query to the database. The first time the QuerySet is used, in a list comprehension, Django sends one SELECT with a WHERE and an ORDER BY, and turns each row into an Event object.\"> <defs><marker id=\"lz-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">building a QuerySet runs nothing</text> <rect x=\"20\" y=\"38\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"85\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Event.objects</text> <rect x=\"170\" y=\"38\" width=\"210\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.filter(venue__startswith=…)</text> <rect x=\"400\" y=\"38\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"480\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.order_by(\"-starts_at\")</text> <path d=\"M150 55 L164 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <path d=\"M380 55 L394 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <text x=\"640\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">0 queries</text> <text x=\"640\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a description</text> <text x=\"20\" y=\"112\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">using it sends one SELECT</text> <rect x=\"20\" y=\"124\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"120\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[e.title for e in events]</text> <path d=\"M220 141 L262 141\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <rect x=\"268\" y=\"124\" width=\"292\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"414\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT … FROM \"events_event\"</text> <text x=\"414\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WHERE venue LIKE 'Community%'</text> <text x=\"414\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ORDER BY starts_at DESC</text> <text x=\"640\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1 query</text> <text x=\"640\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rows become objects</text> <text x=\"20\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Iterating, len(), list(), slicing with a step, bool() and printing all run it. Each chain method returns a new QuerySet.</text> </svg>", "caption": "A QuerySet is a description of a SELECT until something needs its rows. The sql.py run printed the description and then counted exactly one query."}
```

## What each of the three tells you

**`print(events.query)`** shows the statement as Django built it, **before anything ran**. Notice
`LIKE Community%`, with no quotes: the parameters are pasted in for reading, not quoted for running,
so this text is for your eyes and never for `psql`.

**`connection.queries`** is the list of statements that actually ran, with their real parameters,
`'Community%'` in quotes. Django keeps it only while `DEBUG` is on, which is why it is a development
tool, and `reset_queries()` empties it. Building the QuerySet ran nothing; the list comprehension
ran **exactly one query**, however many rows came back.

**`explain()`** asks PostgreSQL how it would run the statement. `Seq Scan` means it reads the whole
table, which for three rows is the fastest plan there is; on a table of a million events filtered by
venue, the same line is a reason to add an index. Reading plans properly is the `sql-databases`
course's job, and the habit to take from here is to look.

## When the ORM is not enough

`Event.objects.raw("SELECT …")` runs your SQL and returns model objects, and
`django.db.connection.cursor()` runs anything at all. Both pass parameters separately, as
`cursor.execute("… WHERE slug = %s", [slug])`, and **never by formatting them into the string**,
which is how SQL injection happens. Everything this course needs, the ORM can say.
