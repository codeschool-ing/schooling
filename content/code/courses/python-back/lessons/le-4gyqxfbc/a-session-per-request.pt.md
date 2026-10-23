---
title: Uma session por requisição
version: 1
---

Uma session deve viver o tempo de uma unidade de trabalho, e numa API a unidade é uma requisição. O
`registration_lock` da aula 8 já tinha o formato: uma dependência que abre algo, faz `yield` disso e
fecha. O `app/db.py` ganha uma:

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

O `with Session(engine)` fecha a session depois da resposta, e **fechar desfaz tudo o que não teve
commit**, então uma rota que levantou uma exceção no meio não deixa transação aberta nem linha escrita
pela metade.

## Objetos para schemas

O Pydantic lê um dicionário por chave. Para ler um `Event` por atributo, cada schema de saída diz
`from_attributes=True`. Este é o novo `app/schemas.py`:

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

O `EventOut.taken` é a property do model, lida como qualquer outro atributo.

O `get_event` agora procura o slug no banco, pela session que ele declara; o FastAPI entrega a mesma
session a toda dependência de uma requisição. O `registration_lock` saiu, e a próxima seção diz por
quê. O `app/dependencies.py`:

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

E as rotas, em `app/main.py`:

```schooling-example
{"language": "python", "file": "app/main.py", "parts": [{"code": "# app/main.py\nfrom fastapi import FastAPI, HTTPException, status\nfrom sqlalchemy import func, select\nfrom sqlalchemy.exc import IntegrityError\nfrom sqlalchemy.orm import selectinload\n\nfrom .db import SessionDep\nfrom .dependencies import EventDep, PageDep\nfrom .forecast import router as forecast_router\nfrom .models import Event, Registration\nfrom .schemas import EventIn, EventOut, RegistrationIn, RegistrationOut, RegistrationPublic\n\napp = FastAPI(\n    title=\"agenda API\",\n    version=\"0.3.0\",\n    description=\"Community events with a limited number of seats.\",\n)\napp.include_router(forecast_router)\n\n\n", "note": "As rotas agora recebem uma `SessionDep`, e tudo o que leem ou escrevem passa por ela. A versão vai para 0.3.0."}, {"code": "@app.get(\"/events\", response_model=list[EventOut], tags=[\"events\"])\ndef list_events(session: SessionDep, page: PageDep, venue: str | None = None):\n    \"\"\"Events in date order, optionally only those at one venue.\"\"\"\n    query = select(Event).options(selectinload(Event.registrations)).order_by(Event.starts_at)\n    if venue is not None:\n        query = query.where(Event.venue == venue)\n    return session.scalars(query.offset(page.offset).limit(page.limit)).all()\n\n\n", "note": "**O `selectinload` é o `prefetch_related` da aula 4**: duas consultas para a página inteira em vez de uma por evento, porque todo evento vai ser perguntado pelo `taken`."}, {"code": "@app.get(\n    \"/events/{slug}\",\n    response_model=EventOut,\n    tags=[\"events\"],\n    responses={404: {\"description\": \"No event has this slug\"}},\n)\ndef get_event(event: EventDep):\n    \"\"\"One event, with the number of seats already taken.\"\"\"\n    return event\n\n\n", "note": "O `EventDep` já encontrou a linha. Devolver o objeto basta: o `EventOut` lê os atributos dele."}, {"code": "@app.post(\"/events\", response_model=EventOut, status_code=status.HTTP_201_CREATED, tags=[\"events\"])\ndef create_event(event: EventIn, session: SessionDep):\n    row = Event(**event.model_dump())\n    session.add(row)\n    try:\n        session.commit()\n    except IntegrityError:\n        raise HTTPException(status.HTTP_409_CONFLICT, f\"{event.slug} already exists\")\n    return row\n\n\n", "note": "**Quem decide se o slug está ocupado é o banco.** A restrição de unicidade recusa o segundo, e a rota transforma isso num 409."}, {"code": "@app.post(\n    \"/events/{slug}/registrations\",\n    response_model=RegistrationOut,\n    status_code=status.HTTP_201_CREATED,\n    tags=[\"registrations\"],\n    summary=\"Register for an event\",\n    responses={409: {\"description\": \"The event is full, or the address is already registered\"}},\n)\ndef register(slug: str, registration: RegistrationIn, session: SessionDep):\n    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())\n    if event is None:\n        raise HTTPException(status.HTTP_404_NOT_FOUND, f\"No event called {slug}\")\n    taken = session.scalar(\n        select(func.count()).select_from(Registration).where(Registration.event_id == event.id)\n    )\n    if taken >= event.capacity:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This event is full.\")\n    row = Registration(event=event, **registration.model_dump())\n    session.add(row)\n    try:\n        session.commit()\n    except IntegrityError:\n        raise HTTPException(status.HTTP_409_CONFLICT, \"This address is already registered.\")\n    return row\n\n\n", "note": "A inscrição, com um lock de linha: a última seção desta aula a desmonta."}, {"code": "@app.get(\n    \"/events/{slug}/registrations\",\n    response_model=list[RegistrationPublic],\n    tags=[\"registrations\"],\n)\ndef list_registrations(event: EventDep):\n    return event.registrations\n", "note": "O relationship, ordenado pelo id como o model pediu."}]}
```

O `app/forecast.py` da aula 9 lia `event["slug"]` do dicionário; um `Event` tem `event.slug`, em três
lugares. O `app/store.py` não tem mais o que fazer, nem o `seed.py`, que o importava:

```
ana@vm:~/agenda-api$ grep -n "event.slug" app/forecast.py
16:        answer = await client.get(PARTNER + event.slug)
23:        answer = client.get(PARTNER + event.slug)
30:        answer = client.get(PARTNER + event.slug)
ana@vm:~/agenda-api$ rm app/store.py seed.py
```

## Quatro processos

Suba a API **com quatro processos worker**. A aula 16 faz isso para produção; acontece aqui porque a
próxima seção precisa ver quatro processos dividindo um banco:

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

Um processo pai e quatro servidores, cada um com sua engine e seu pool. Eles respondem das mesmas
tabelas:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/django-night; echo
{"slug":"django-night","title":"Django Night","starts_at":"2026-11-12T19:00:00-03:00","venue":"Community Centre, room 3","capacity":40,"description":"","taken":0}
ana@vm:~/agenda-api$ curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202"; echo
[{"slug":"async-workshop","title":"Async Python workshop","starts_at":"2026-11-19T14:00:00-03:00","venue":"Public Library, lab 2","capacity":12,"description":"","taken":0}]
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/nope; echo
{"detail":"No event called nope"}
```
