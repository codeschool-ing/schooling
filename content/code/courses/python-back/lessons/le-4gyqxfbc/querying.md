---
title: Querying, and the query per row
version: 1
---

A query in SQLAlchemy 2 is built with `select()` and run by the session. `queries.py` asks four
things:

```python
# queries.py
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db import engine
from app.models import Event, Registration

with Session(engine) as session:
    night = session.scalars(select(Event).where(Event.slug == "django-night")).one()
    print(night.title, night.capacity)

    same = session.get(Event, night.id)
    print(same is night)

    room_3 = select(Event).where(Event.venue == "Community Centre, room 3").order_by(Event.starts_at)
    print([e.slug for e in session.scalars(room_3)])

    counts = (
        select(Event.slug, func.count(Registration.id))
        .outerjoin(Event.registrations)
        .group_by(Event.slug)
        .order_by(Event.slug)
    )
    print(session.execute(counts).all())
```

```
ana@vm:~/agenda-api$ uv run python queries.py
Django Night 40
True
['django-night', 'testing-dojo']
[('async-workshop', 0), ('django-night', 0), ('testing-dojo', 0)]
```

| line | what it shows |
|---|---|
| `Django Night 40` | `select(Event).where(...)` is a statement; `session.scalars` runs it and yields objects; `.one()` insists on exactly one |
| `True` | **the identity map**: `session.get` by primary key returned the object the session already had for that row, not a copy |
| two slugs | `where` and `order_by` add to the statement; nothing runs until the session iterates |
| the tuples | a `select` of columns returns rows, not objects; `outerjoin` keeps the event with no registrations |

## The same N+1 as lesson 4

`Event.taken` is `len(self.registrations)`, and the registrations are loaded **the first time they
are asked for**. For a list of events, that is one query for the list and one more per event.
`nplus1.py` prints every query the engine sends:

```python
# nplus1.py
from sqlalchemy import event, select
from sqlalchemy.orm import Session, selectinload

from app.db import engine
from app.models import Event


@event.listens_for(engine, "before_cursor_execute")
def show(connection, cursor, statement, parameters, context, executemany):
    if "\nFROM " in statement:
        print("  query: FROM", " ".join(statement.split("\nFROM ")[1].split()), parameters)


with Session(engine) as session:
    print("lazy:")
    for e in session.scalars(select(Event)):
        print(e.slug, e.taken)

with Session(engine) as session:
    print("selectinload:")
    for e in session.scalars(select(Event).options(selectinload(Event.registrations))):
        print(e.slug, e.taken)
```

```
ana@vm:~/agenda-api$ uv run python nplus1.py
lazy:
  query: FROM events {}
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 1}
django-night 0
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 2}
async-workshop 0
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 3}
testing-dojo 0
selectinload:
  query: FROM events {}
  query: FROM registrations WHERE registrations.event_id IN (%(primary_keys_1)s::INTEGER, %(primary_keys_2)s::INTEGER, %(primary_keys_3)s::INTEGER) ORDER BY registrations.id {'primary_keys_1': 1, 'primary_keys_2': 2, 'primary_keys_3': 3}
django-night 0
async-workshop 0
testing-dojo 0
```

**Four queries for three events, then two.** The first loop is lesson 4's problem exactly: a list of
a hundred events would cost a hundred and one queries. `selectinload(Event.registrations)` loads the
registrations of every event on the page in one second query, with `IN`, which is what Django's
`prefetch_related` does. Its cousin `joinedload` does it in the same query with a join, as
`select_related` does, and fits a relationship with one row on the other side better than a list.

Lazy loading stays the default because it is never wrong, only slow, and slow shows up in a list of
queries like this one. **When a route returns several objects and touches a relationship of each,
load it eagerly.** For a count over a large table, counting in SQL, as the last line of
`queries.py` did, beats loading the rows to call `len` on them.
