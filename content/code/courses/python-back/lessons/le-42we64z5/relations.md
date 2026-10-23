---
title: Relations, and the query that runs once per row
version: 1
---

`Registration.event` is a **foreign key**: a column, `event_id`, holding an event's id. Django gives
both ends a way to the other. A registration has `.event`, the event object; an event has
`.registrations`, a manager for its registrations, named by `related_name`:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from events.models import Event; e = Event.objects.get(slug=\"testing-dojo\"); print(e.registrations.all()); print(e.registrations.first().event.venue)"
14 objects imported automatically (use -v 2 for details).

<QuerySet [<Registration: Carla for Testing dojo>, <Registration: Davi for Testing dojo>]>
Community Centre, room 3
```

`e.registrations.all()` is a QuerySet like any other, filtered to this event. And
`e.registrations.first().event.venue` went from the registration back to its event, with a query each
way.

## One query per row

That "query each way" is cheap once and expensive in a loop. This script lists every event with its
number of registrations, first the obvious way, then the way that scales:

```python
# nplus1.py
from django.db import connection, reset_queries
from django.db.models import Count

from events.models import Event

reset_queries()
for event in Event.objects.all():
    print(event.title, event.registrations.count())
print(len(connection.queries), "queries")

reset_queries()
for event in Event.objects.annotate(taken=Count("registrations")):
    print(event.title, event.taken)
print(len(connection.queries), "query")
```

```
ana@vm:~/agenda$ uv run python manage.py shell < nplus1.py
14 objects imported automatically (use -v 2 for details).

Django Night 1
Async Python workshop 12
Testing dojo 2
4 queries
Async Python workshop 12
Testing dojo 2
Django Night 1
1 query
```

**The loop sent four queries for three events**: one for the events and one `COUNT` per event. With a
thousand events it would send 1,001, and the page that lists events with their seats taken is exactly
where that loop gets written. `annotate(taken=Count("registrations"))` asked for the same numbers in
**one query**, with a join and a `GROUP BY`, and put the count on each object as `taken`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"On the left, a loop that asks each event for its registration count sends one query for the events and then one COUNT query per event: four for three events, and 1,001 for a thousand. On the right, annotate with Count sends a single query that joins the registrations and groups by event.\"> <defs><marker id=\"np-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">event.registrations.count() in a loop</text> <rect x=\"40\" y=\"36\" width=\"280\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT … FROM events_event</text> <rect x=\"60\" y=\"68\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 1</text> <rect x=\"60\" y=\"98\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 2</text> <rect x=\"60\" y=\"128\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 3</text> <text x=\"180\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 + N queries: 4 here, 1,001 for 1,000 events</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">annotate(taken=Count(\"registrations\"))</text> <rect x=\"390\" y=\"36\" width=\"310\" height=\"84\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"58\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT events_event.*,</text> <text x=\"545\" y=\"75\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COUNT(events_registration.id)</text> <text x=\"545\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">LEFT OUTER JOIN … GROUP BY id</text> <text x=\"545\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 query, however many events</text> </svg>", "caption": "The loop's cost grows with the number of rows; the annotation's does not. The page that lists events with their seats taken is exactly where the first shape hides."}
```

**The order changed**, too: the annotated list came back as Async, Testing, Django. Django leaves
`Meta.ordering` out of a query with a `GROUP BY`, since version 3.1, so a query that aggregates
should say `order_by()` itself if the order matters.

## The two tools for related rows

| | what it does | for |
|---|---|---|
| `select_related("event")` | one query with a `JOIN` | following a foreign key forwards: registrations with their events |
| `prefetch_related("registrations")` | a second query, then matched in Python | the reverse side, or many-to-many: events with their lists of registrations |
| `annotate(Count(…))` | a `JOIN` with `GROUP BY` | a number per row, without fetching the related rows at all |

The habit that finds these is the one from the previous section: count the queries a page makes.
`connection.queries` in a script, and in lesson 14 a test that fails when a page makes more queries
than it should.
