---
title: Dependencies: the parts a route asks for
version: 1
---

Lesson 7's routes each called `find_event(slug)` and declared `limit` themselves. Both are things
**many routes need**, and FastAPI has a mechanism for exactly that: a route declares what it needs in
its signature, and FastAPI builds it before calling the route. That is **dependency injection**, and
it is how FastAPI shares everything from a lookup to a database session. Save this as
`app/dependencies.py`:

```schooling-example
{"language": "python", "file": "app/dependencies.py", "parts": [{"code": "# app/dependencies.py\nimport threading\nfrom typing import Annotated\n\nfrom fastapi import Depends, HTTPException, Query, status\n\nfrom .store import EVENTS\n\n\n", "note": "Everything a route may ask FastAPI to build for it lives in `app/dependencies.py`."}, {"code": "def get_event(slug: str) -> dict:\n    if slug not in EVENTS:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    return EVENTS[slug]\n\n\n", "note": "**A dependency is a function.** Its own parameters are read from the request like a route's, so `slug` comes from the path."}, {"code": "EventDep = Annotated[dict, Depends(get_event)]\n\n\n", "note": "`Annotated` packs the type and the `Depends` into one name, so a route writes `event: EventDep` and nothing else."}, {"code": "class Page:\n    def __init__(\n        self,\n        limit: int = Query(default=20, ge=1, le=100),\n        offset: int = Query(default=0, ge=0),\n    ):\n        self.limit = limit\n        self.offset = offset\n\n\n", "note": "A class works too: FastAPI calls it with the query parameters, and the route gets the instance. `limit` and `offset` now have one definition for every list."}, {"code": "PageDep = Annotated[Page, Depends()]\n\n", "note": "`Depends()` with no argument means \"call the annotated class itself\"."}, {"code": "_registrations = threading.Lock()\n\n\n", "note": "**One lock for the whole process**, shared by every request this process serves."}, {"code": "def registration_lock():\n    with _registrations:\n        print(\"lock held\", flush=True)\n        try:\n            yield\n        finally:\n            print(\"lock released\", flush=True)\n", "note": "**A dependency with `yield`**: the code before it runs before the route, the code after it runs once the route is done. `finally` makes sure the second half runs even when the route raised."}]}
```

And replace `app/main.py` with this version, which uses them:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom datetime import datetime, timezone\n\nfrom fastapi import Depends, FastAPI, HTTPException, status\n\nfrom .dependencies import EventDep, PageDep, registration_lock\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\nfrom .store import EVENTS, REGISTRATIONS\n\n", "note": "`Depends` for the dependency without a value, and nothing else new among the imports."}, {"code": "app = FastAPI(\n    title=\"agenda API\",\n    version=\"0.2.0\",\n    description=\"Community events with a limited number of seats.\",\n)\n\n\n", "note": "The `title`, `version` and `description` go to the top of the schema and of the documentation pages."}, {"code": "def with_taken(event: dict) -> dict:\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"])\n    return {**event, \"taken\": taken}\n\n\n"}, {"code": "@app.get(\"/events\", response_model=list[EventOut], tags=[\"events\"])\ndef list_events(page: PageDep, venue: str | None = None):\n    \"\"\"Events in date order, optionally only those at one venue.\"\"\"\n    events = sorted(EVENTS.values(), key=lambda e: e[\"starts_at\"])\n    events = [e for e in events if venue is None or e[\"venue\"] == venue]\n    return [with_taken(e) for e in events[page.offset : page.offset + page.limit]]\n\n\n", "note": "`tags` group routes on the documentation page; **the docstring becomes the operation's description**. `page: PageDep` replaces the two query parameters lesson 7 declared here."}, {"code": "@app.get(\n    \"/events/{slug}\",\n    response_model=EventOut,\n    tags=[\"events\"],\n    responses={404: {\"description\": \"No event has this slug\"}},\n)\ndef get_event(event: EventDep):\n    \"\"\"One event, with the number of seats already taken.\"\"\"\n    return with_taken(event)\n\n\n", "note": "`responses` documents an answer FastAPI cannot see in the code, the 404 that `get_event` raises. `event: EventDep` replaces `find_event(slug)`."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED, tags=[\"events\"])\ndef create_event(event: EventIn):\n    if event.slug in EVENTS:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    EVENTS[event.slug] = event.model_dump()\n    return with_taken(EVENTS[event.slug])\n\n\n"}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n    tags=[\"registrations\"],\n    summary=\"Register for an event\",\n    responses={409: {\"description\": \"The event is full, or the address is already registered\"}},\n    dependencies=[Depends(registration_lock)],\n)\ndef register(event: EventDep, registration: RegistrationIn):\n    mine = [r for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"]]\n    if len(mine) >= event[\"capacity\"]:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    if any(r[\"email\"] == registration.email for r in mine):\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    row = {\n        \"slug\": event[\"slug\"],\n        **registration.model_dump(),\n        \"created_at\": datetime.now(timezone.utc),\n    }\n    REGISTRATIONS.append(row)\n    print(\"registered\", registration.email, flush=True)\n    return row\n\n\n", "note": "`summary` overrides the title FastAPI derives from the function's name. **`dependencies=[...]`** runs a dependency whose value the route does not need: the lock."}, {"code": "@app.get(\n    \"/events/{slug}/registrations\",\n    response_model=list[RegistrationPublic],\n    tags=[\"registrations\"],\n)\ndef list_registrations(event: EventDep):\n    return [r for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"]]\n", "note": "The same `EventDep`, so the 404 for an unknown event is written once."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"Before calling register, FastAPI resolves its dependencies from the request: get_event takes the slug from the path and returns the event or answers 404; RegistrationIn validates the body or answers 422; registration_lock takes the lock and holds it. Only when all three have succeeded is register called, with their results as its arguments.\"> <defs><marker id=\"di-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the request</text> <rect x=\"20\" y=\"32\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">path: slug=django-night</text> <text x=\"32\" y=\"92\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">body: {name, email}</text> <text x=\"32\" y=\"126\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">query: limit, offset</text> <text x=\"32\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(for the list route)</text> <rect x=\"270\" y=\"32\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">get_event(slug)</text> <text x=\"370\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a dict, or 404</text> <rect x=\"270\" y=\"92\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RegistrationIn</text> <text x=\"370\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a model, or 422</text> <rect x=\"270\" y=\"152\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registration_lock()</text> <text x=\"370\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">held until the end</text> <path d=\"M220 54 L264 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M220 88 L264 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <rect x=\"520\" y=\"70\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"610\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">register(event,</text> <text x=\"610\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registration)</text> <text x=\"610\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs last</text> <path d=\"M470 54 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M470 114 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <path d=\"M470 174 L514 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#di-a)\"></path> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Any dependency can stop the request; the route runs only if all of them succeeded.</text> </svg>", "caption": "The route's signature is a list of things it needs. FastAPI builds each one, in order, and hands them over."}
```

## Using them

The paginated list, page two of size one:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?limit=1&offset=1" | python3 -m json.tool | grep slug
        "slug": "async-workshop",
```

The `Page` class's rules apply wherever it is used, with the same 422 as any other parameter:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?offset=-1"
{"detail":[{"type":"greater_than_equal","loc":["query","offset"],"msg":"Input should be greater than or equal to 0","input":"-1","ctx":{"ge":0}}]}
422
```

And `get_event` answers for every route that declares `EventDep`, the event's own address and its
registrations alike:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope
{"detail":"No event called nope"}
404
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope/registrations
{"detail":"No event called nope"}
404
```

**One function, one message, two routes**, and a third route that needs an event gets the same
behaviour by writing `event: EventDep`.

## Why this beats calling a function

The routes could call `get_event(slug)` themselves, as lesson 7 did. Declaring it instead buys three
things. **The parameters a dependency reads appear in the schema**, as `limit` and `offset` did in the
previous section. **Dependencies can depend on others**, and FastAPI resolves the whole tree once per
request, caching a value two of them share. And a dependency can be **replaced from outside** without
touching the route, which is the last section of this lesson and the reason tests in lesson 14 are
short.
