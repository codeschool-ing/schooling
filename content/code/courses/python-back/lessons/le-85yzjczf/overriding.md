---
title: Overriding a dependency
version: 1
---

Because a route only declares what it needs, something else can decide what it gets.
`app.dependency_overrides` is a dictionary from a dependency to its replacement, and while an entry
is in it, every route that asked for the original gets the replacement. The main use is tests: a
route that needs a database gets a test database, a route that needs the current user gets a fixed
one.

FastAPI's `TestClient` sends requests to the application in the same process, without a server, and
it needs an HTTP client library to do it. Install it as a **development** dependency, which
production never installs:

```
ana@vm:~/agenda-api$ uv add --dev httpx2
Resolved 21 packages in 257ms
Prepared 3 packages in 18ms
Installed 3 packages in 3ms
 + httpcore2==2.16.0
 + httpx2==2.16.0
 + truststore==0.10.5
```

The library is `httpx2`: the current Starlette, under FastAPI, asks for it by name and warns when it
finds only the older `httpx`. Then this script, saved as `override.py` in `~/agenda-api`, replaces
`get_event` with a function that returns an event with no seats at all:

```python
# override.py
from fastapi.testclient import TestClient

from app.dependencies import get_event
from app.main import app


def a_full_event(slug: str) -> dict:
    return {
        "slug": slug,
        "title": "Full already",
        "starts_at": "2026-12-01T10:00:00-03:00",
        "venue": "Nowhere",
        "capacity": 0,
        "description": "",
    }


client = TestClient(app)
app.dependency_overrides[get_event] = a_full_event

answer = client.post("/events/anything/registrations", json={"name": "Gil", "email": "gil@example.org"})
print(answer.status_code, answer.json())

app.dependency_overrides.clear()
print(client.get("/events/anything").status_code)
```

```
ana@vm:~/agenda-api$ uv run python override.py
lock held
lock released
409 {'detail': 'This event is full.'}
404
```

**The registration route answered 409, `This event is full.`, for an event that does not exist**,
because the route never looked: it received what `get_event` would have returned, and the override
returned a full event. The lock dependency still ran, because only `get_event` was replaced. Then
`clear()` removed the override, and the same address was a 404 again.

This is the whole technique lesson 14 builds its FastAPI tests on. Two habits come with it: **clear
the overrides after each test**, or one test's replacement leaks into the next; and override the
smallest thing that makes the test possible, so the test still exercises everything around it.
