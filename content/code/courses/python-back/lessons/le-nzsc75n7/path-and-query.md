---
title: Routes, path parameters and query parameters
version: 1
---

With the shapes declared, the API gets its routes. This is the whole of `app/main.py` for the rest of
the lesson:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom datetime import datetime, timezone\n\nfrom fastapi import FastAPI, HTTPException, Query, status\n\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\nfrom .store import EVENTS, REGISTRATIONS\n\n", "note": "The whole API in one module for now. `HTTPException` is how a function stops with an error status; `Query` adds rules to a query parameter."}, {"code": "app = FastAPI(title=\"agenda API\", version=\"0.1.0\")\n\n\n", "note": "`title` and `version` describe the API, and lesson 8 shows where they appear."}, {"code": "def find_event(slug: str) -> dict:\n    if slug not in EVENTS:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    return EVENTS[slug]\n\n\n", "note": "**A plain function, not a route.** Raising `HTTPException` inside it stops whichever route called it, with a 404."}, {"code": "def with_taken(event: dict) -> dict:\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == event[\"slug\"])\n    return {**event, \"taken\": taken}\n\n\n", "note": "The count lesson 4 put in the database, done here over a list until lesson 10 gives this API one."}, {"code": "@app.get(\"/events\", response_model=list[EventOut])\ndef list_events(venue: str | None = None, limit: int = Query(default=20, ge=1, le=100)):\n    events = [e for e in EVENTS.values() if venue is None or e[\"venue\"] == venue]\n    return [with_taken(e) for e in events[:limit]]\n\n\n", "note": "**Every parameter that is not in the path is a query parameter.** `venue` is optional because its default is `None`; `limit` must be an integer from 1 to 100."}, {"code": "@app.get(\"/events/{slug}\", response_model=EventOut)\ndef get_event(slug: str):\n    return with_taken(find_event(slug))\n\n\n", "note": "`{slug}` in the path becomes the `slug` argument, typed as `str`."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED)\ndef create_event(event: EventIn):\n    if event.slug in EVENTS:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    EVENTS[event.slug] = event.model_dump()\n    return with_taken(EVENTS[event.slug])\n\n\n", "note": "**A parameter whose type is a Pydantic model is read from the JSON body**, validated before the function runs. `status_code` sets the success code."}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n)\ndef register(slug: str, registration: RegistrationIn):\n    event = find_event(slug)\n    mine = [r for r in REGISTRATIONS if r[\"slug\"] == slug]\n    if len(mine) >= event[\"capacity\"]:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    if any(r[\"email\"] == registration.email for r in mine):\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    row = {\"slug\": slug, **registration.model_dump(), \"created_at\": datetime.now(timezone.utc)}\n    REGISTRATIONS.append(row)\n    return row\n\n\n", "note": "Registering: the same three rules as Django's form had in lesson 3, in the same racy shape, until lesson 10 puts them on a database."}, {"code": "@app.get(\"/events/{slug}/registrations\", response_model=list[RegistrationPublic])\ndef list_registrations(slug: str):\n    find_event(slug)\n    return [r for r in REGISTRATIONS if r[\"slug\"] == slug]\n", "note": "Returns the rows with addresses in them; the response model takes the addresses out."}]}
```

Where a value comes from is decided by the function's signature, and nothing else:

| the parameter | is read from |
|---|---|
| named in the path, `{slug}` | the path |
| a simple type, `str`, `int`, `bool`, not in the path | the query string |
| a Pydantic model | the JSON body |

## Query parameters, typed

`limit` defaults to 20 and must be an integer from 1 to 100. Ask for one:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?limit=1" | python3 -m json.tool
[
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00:00-03:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": "",
        "taken": 0
    }
]
```

`taken` is there because the response model `EventOut` asked for it. `venue` filters, and is simply
absent when not given:

```
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202" | python3 -m json.tool | grep slug
        "slug": "async-workshop",
```

A `limit` out of range, and one that is not a number:

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=500"
{"detail":[{"type":"less_than_equal","loc":["query","limit"],"msg":"Input should be less than or equal to 100","input":"500","ctx":{"le":100}}]}
422
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=ten"
{"detail":[{"type":"int_parsing","loc":["query","limit"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"ten"}]}
422
```

**422, and the function never ran.** Each error says where the bad value was, `["query", "limit"]`,
what rule it broke and what was sent. That `loc` list is how a client knows which input to mark red.

## An event that does not exist

```
ana@vm:~/agenda-api$ curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/no-such-event
{"detail":"No event called no-such-event"}
404
```

`find_event` raised `HTTPException` with 404, and FastAPI answered with its message under `detail`.
The exception is not caught by the route: FastAPI catches it for every route, which is why a helper
function three calls deep can stop a request with the right status.
