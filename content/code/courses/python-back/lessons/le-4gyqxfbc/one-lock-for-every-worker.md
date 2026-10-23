---
title: One lock for every worker
version: 1
---

The registration route, from `app/main.py`:

```python
    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"No event called {slug}")
    taken = session.scalar(
        select(func.count()).select_from(Registration).where(Registration.event_id == event.id)
    )
    if taken >= event.capacity:
        raise HTTPException(status.HTTP_409_CONFLICT, "This event is full.")
    row = Registration(event=event, **registration.model_dump())
    session.add(row)
    try:
        session.commit()
    except IntegrityError:
        raise HTTPException(status.HTTP_409_CONFLICT, "This address is already registered.")
    return row
```

**`with_for_update()` is `SELECT … FOR UPDATE`**, the same lock Django's `select_for_update()` took
in lesson 4. Any other transaction asking for the same row with `FOR UPDATE` waits until this one
commits, so the count and the insert happen with nobody else in between. The count runs in SQL, and
the duplicate address is **left to the unique constraint**: checking first and inserting after is
two steps another request can fit between, while the constraint refuses inside the insert.

```
ana@vm:~/agenda-api$ curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{"name": "Bruno", "email": "bruno@example.org"}'; echo
{"name":"Bruno","email":"bruno@example.org","created_at":"2026-10-22T20:14:47.154897-03:00"}
ana@vm:~/agenda-api$ curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{"name": "Bruno", "email": "bruno@example.org"}'; echo
{"detail":"This address is already registered."}
```

The constraint's refusal arrived as `IntegrityError`, which the route turned into a 409. Now
`crowd.py`, twenty registrations at once against the four workers. Save it in `~/agenda-api`:

```python
# crowd.py
import asyncio
import sys

import httpx2


async def main(url):
    async with httpx2.AsyncClient(timeout=60) as client:
        answers = await asyncio.gather(
            *(client.post(url, json={"name": f"Person {i}", "email": f"p{i}@example.org"}) for i in range(20))
        )
    codes = [a.status_code for a in answers]
    print(codes.count(201), "registered,", codes.count(409), "refused")


asyncio.run(main(sys.argv[1]))
```

```
ana@vm:~/agenda-api$ uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations
12 registered, 8 refused
ana@vm:~/agenda-api$ psql agenda_api -c "select e.slug, count(r.id) from events e left join registrations r on r.event_id = e.id group by e.slug order by e.slug"
      slug      | count 
----------------+-------
 async-workshop |    12
 django-night   |     1
 testing-dojo   |     0
(3 rows)
```

**Twelve in, eight refused, twelve rows.**

## Without the lock

To see what the lock does, take `.with_for_update()` out of that line, start the API again and
send the crowd three times, emptying the workshop between rounds:

```
ana@vm:~/agenda-api$ grep -n "Event.slug == slug" app/main.py
61:    event = session.scalar(select(Event).where(Event.slug == slug))
ana@vm:~/agenda-api$ psql agenda_api -c "delete from registrations where email like 'p%@example.org'"
DELETE 12
ana@vm:~/agenda-api$ for round in 1 2 3; do uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations; psql agenda_api -qc "delete from registrations where email like 'p%@example.org'"; done
20 registered, 0 refused
19 registered, 1 refused
18 registered, 2 refused
```

**Twenty, nineteen and eighteen registrations for twelve seats**, a different number every round,
and not one error. Every request counted before enough of the others had committed. A different
machine will give different numbers, and some rounds may even come out right, which is how a race
gets to production: it passes the test someone ran once.

Lesson 8's `threading.Lock` could not have stopped this. It lives in one process, and there are four,
each with its own. **The row lock lives in the database, where all four look**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"crowd.py sends twenty registrations at once. Uvicorn spreads them over four worker processes, 552 to 555, as its log showed. Every worker asks PostgreSQL for the async-workshop row FOR UPDATE, and only one transaction holds that lock at a time.\"> <defs><marker id=\"wk-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"70\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"80\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">crowd.py</text> <text x=\"80\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 POSTs at once</text> <rect x=\"210\" y=\"20\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"41\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 552</text> <path d=\"M140 102 L204 37\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 37 L444 72\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"64\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"85\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 553</text> <path d=\"M140 102 L204 81\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 81 L444 92\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"108\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"129\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 554</text> <path d=\"M140 102 L204 125\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 125 L444 112\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"152\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"173\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 555</text> <path d=\"M140 102 L204 169\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 169 L444 132\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"450\" y=\"60\" width=\"250\" height=\"84\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"575\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">PostgreSQL</text> <text x=\"575\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events row async-workshop</text> <text x=\"575\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">FOR UPDATE: one holder at a time</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A threading.Lock lives in one process. The row lock lives where all four look.</text> </svg>", "caption": "Four processes, one lock. With it, twelve got in in every run; without it, between eighteen and twenty did."}
```

With the line back as it was:

```
ana@vm:~/agenda-api$ grep -n "Event.slug == slug" app/main.py
61:    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())
ana@vm:~/agenda-api$ uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations
12 registered, 8 refused
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/async-workshop; echo
{"slug":"async-workshop","title":"Async Python workshop","starts_at":"2026-11-19T14:00:00-03:00","venue":"Public Library, lab 2","capacity":12,"description":"","taken":12}
```

The workshop is full again, with the right number in it.

## What it costs

A lock makes registrations for **one event** wait in line; registrations for other events take other
rows and never wait for each other. The wait lasts until `commit`, so keep the locked part short: no
call to a partner and no slow computing between the `SELECT … FOR UPDATE` and the commit. Reading
an event, which every listing does, takes no lock at all.
