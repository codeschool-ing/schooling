---
title: A session per request
version: 1
---

A session should live as long as one unit of work, and in an API the unit is a request. Lesson 8's
`registration_lock` already had the shape: a dependency that opens something, `yield`s it and
closes it. `app/db.py` gains one:

```python
# app/db.py
from typing import Annotated

from fastapi import Depends
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

engine = create_engine("postgresql+psycopg:///agenda_api")


def get_session():
    with Session(engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_session)]
```

`with Session(engine)` closes the session after the response, and **closing rolls back anything not
committed**, so a route that raised halfway leaves no transaction open and no row half written.

## Objects into schemas

Pydantic reads a dictionary by key. To read an `Event` by attribute, each output schema says
`from_attributes=True`. This is the new `app/schemas.py`:

```python
# app/schemas.py
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class EventIn(BaseModel):
    slug: str = Field(pattern=r"^[a-z0-9-]+$", max_length=50)
    title: str = Field(min_length=1, max_length=200)
    starts_at: datetime
    venue: str = Field(min_length=1, max_length=200)
    capacity: int = Field(ge=1, le=1000)
    description: str = ""


class EventOut(EventIn):
    model_config = ConfigDict(from_attributes=True)

    taken: int


class RegistrationIn(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr


class RegistrationOut(RegistrationIn):
    model_config = ConfigDict(from_attributes=True)

    created_at: datetime


class RegistrationPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    created_at: datetime
```

`EventOut.taken` is the model's property, read like any other attribute.

`get_event` now looks the slug up in the database, through the session it declares; FastAPI hands
the same session to every dependency of one request. `registration_lock` is gone, and the next section
says why. `app/dependencies.py`:

```python
# app/dependencies.py
from typing import Annotated

from fastapi import Depends, HTTPException, Query, status
from sqlalchemy import select

from .db import SessionDep
from .models import Event


def get_event(slug: str, session: SessionDep) -> Event:
    event = session.scalar(select(Event).where(Event.slug == slug))
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"No event called {slug}")
    return event


EventDep = Annotated[Event, Depends(get_event)]


class Page:
    def __init__(
        self,
        limit: int = Query(default=20, ge=1, le=100),
        offset: int = Query(default=0, ge=0),
    ):
        self.limit = limit
        self.offset = offset


PageDep = Annotated[Page, Depends()]
```

And the routes, in `app/main.py`:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom fastapi import FastAPI, HTTPException, status\nfrom sqlalchemy import func, select\nfrom sqlalchemy.exc import IntegrityError\nfrom sqlalchemy.orm import selectinload\n\nfrom .db import SessionDep\nfrom .dependencies import EventDep, PageDep\nfrom .forecast import router as forecast_router\nfrom .models import Event, Registration\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\n\napp = FastAPI(\n    title=\"agenda API\",\n    version=\"0.3.0\",\n    description=\"Community events with a limited number of seats.\",\n)\napp.include_router(forecast_router)\n\n\n", "note": "The routes now take a `SessionDep`, and everything they read or write goes through it. The version moves to 0.3.0."}, {"code": "@app.get(\"/events\", response_model=list[EventOut], tags=[\"events\"])\ndef list_events(session: SessionDep, page: PageDep, venue: str | None = None):\n    \"\"\"Events in date order, optionally only those at one venue.\"\"\"\n    query = select(Event).options(selectinload(Event.registrations)).order_by(Event.starts_at)\n    if venue is not None:\n        query = query.where(Event.venue == venue)\n    return session.scalars(query.offset(page.offset).limit(page.limit)).all()\n\n\n", "note": "**`selectinload` is lesson 4's `prefetch_related`**: two queries for the whole page rather than one per event, because every event will be asked for `taken`."}, {"code": "@app.get(\n    \"/events/{slug}\",\n    response_model=EventOut,\n    tags=[\"events\"],\n    responses={404: {\"description\": \"No event has this slug\"}},\n)\ndef get_event(event: EventDep):\n    \"\"\"One event, with the number of seats already taken.\"\"\"\n    return event\n\n\n", "note": "`EventDep` already found the row. Returning the object is enough: `EventOut` reads its attributes."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED, tags=[\"events\"])\ndef create_event(event: EventIn, session: SessionDep):\n    row = Event(**event.model_dump())\n    session.add(row)\n    try:\n        session.commit()\n    except IntegrityError:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    return row\n\n\n", "note": "**The database decides whether the slug is taken.** The unique constraint refuses the second one, and the route turns that into a 409."}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n    tags=[\"registrations\"],\n    summary=\"Register for an event\",\n    responses={409: {\"description\": \"The event is full, or the address is already registered\"}},\n)\ndef register(slug: str, registration: RegistrationIn, session: SessionDep):\n    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())\n    if event is None:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    taken = session.scalar(\n        select(func.count()).select_from(Registration).where(Registration.event_id == event.id)\n    )\n    if taken >= event.capacity:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    row = Registration(event=event, **registration.model_dump())\n    session.add(row)\n    try:\n        session.commit()\n    except IntegrityError:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    return row\n\n\n", "note": "Registering, with a row lock: the last section of this lesson takes it apart."}, {"code": "@app.get(\n    \"/events/{slug}/registrations\",\n    response_model=list[RegistrationPublic],\n    tags=[\"registrations\"],\n)\ndef list_registrations(event: EventDep):\n    return event.registrations\n", "note": "The relationship, ordered by id as the model asked."}]}
```

`app/forecast.py` from lesson 9 read `event["slug"]` from the dictionary; an `Event` has
`event.slug`, in three places. `app/store.py` has nothing left to do, nor has `seed.py`, which
imported it:

```
ana@vm:~/agenda-api$ grep -n "event.slug" app/forecast.py
16:        answer = await client.get(PARTNER + event.slug)
23:        answer = client.get(PARTNER + event.slug)
30:        answer = client.get(PARTNER + event.slug)
ana@vm:~/agenda-api$ rm app/store.py seed.py
```

## Four processes

Start the API **with four worker processes**. Lesson 16 does this for production; it happens here
because the next section needs to see four processes share one database:

```
ana@vm:~/agenda-api$ uv run uvicorn app.main:app --port 8001 --workers 4
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started parent process [550]
INFO:     Started server process [552]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [554]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [555]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [553]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

A parent process and four servers, each with its own engine and pool. They answer from the same
tables:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/django-night; echo
{"slug":"django-night","title":"Django Night","starts_at":"2026-11-12T19:00:00-03:00","venue":"Community Centre, room 3","capacity":40,"description":"","taken":0}
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202"; echo
[{"slug":"async-workshop","title":"Async Python workshop","starts_at":"2026-11-19T14:00:00-03:00","venue":"Public Library, lab 2","capacity":12,"description":"","taken":0}]
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/nope; echo
{"detail":"No event called nope"}
```
