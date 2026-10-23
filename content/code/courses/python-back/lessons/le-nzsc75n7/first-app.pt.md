---
title: Um segundo projeto, ao lado do primeiro
version: 1
---

Desta aula até a aula 10, a API do agenda é construída de novo em FastAPI, num projeto próprio ao lado
do Django. Os mesmos eventos, as mesmas regras, outro conjunto de suposições, que é a comparação que a
aula 1 prometeu. Ele começa do jeito que o `hello-fastapi` começou, com um acréscimo:

```
ana@vm:~$ mkdir agenda-api && cd agenda-api && uv init --bare && uv add fastapi uvicorn "pydantic[email]"
Initialized project `agenda-api`
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 17 packages in 287ms
Prepared 4 packages in 61ms
Installed 16 packages in 8ms
 + annotated-doc==0.0.5
 + annotated-types==0.8.0
 + anyio==4.15.1
 + click==8.5.0
 + dnspython==2.9.0
 + email-validator==2.3.0
 + fastapi==0.161.1
 + h11==0.16.0
 + idna==3.20
 + opentelemetry-api==1.45.1
 + pydantic==2.14.1
 + pydantic-core==2.50.1
 + starlette==1.9.0
 + typing-extensions==4.16.0
 + typing-inspection==0.4.4
 + uvicorn==0.54.0
```

`pydantic[email]` é o Pydantic com um **extra**: as dependências opcionais necessárias para validar
endereços de e-mail, que trouxeram `email-validator` e `dnspython` junto. Os colchetes são as
dependências opcionais da aula 19 de `python`, vistas do lado de quem instala.

## Um pacote, não um arquivo

O `hello-fastapi` era um arquivo. Esta API vai ter vários módulos, então mora num pacote, `app`:

```
ana@vm:~/agenda-api$ mkdir app && touch app/__init__.py
```

Até a aula 10 dar a ela um banco, os eventos moram num dicionário indexado pelo slug, com os mesmos três
do agenda. Salve isto como `app/store.py`:

```python
# app/store.py
from datetime import datetime
from zoneinfo import ZoneInfo

SAO_PAULO = ZoneInfo("America/Sao_Paulo")

EVENTS = {
    "django-night": {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": datetime(2026, 11, 12, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": "",
    },
    "async-workshop": {
        "slug": "async-workshop",
        "title": "Async Python workshop",
        "starts_at": datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),
        "venue": "Public Library, lab 2",
        "capacity": 12,
        "description": "",
    },
    "testing-dojo": {
        "slug": "testing-dojo",
        "title": "Testing dojo",
        "starts_at": datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 20,
        "description": "",
    },
}

REGISTRATIONS = []
```

E a primeira versão do `app/main.py`, que só os lista:

```python
# app/main.py
from fastapi import FastAPI

from .store import EVENTS

app = FastAPI(title="agenda API", version="0.1.0")


@app.get("/events")
def list_events():
    return list(EVENTS.values())
```

```
ana@vm:~/agenda-api$ find . -path ./.venv -prune -o -type f -print | sort
./app/__init__.py
./app/main.py
./app/store.py
./pyproject.toml
./uv.lock
```

## Rodar, e rodar de novo a cada salvamento

Suba o Uvicorn num terminal próprio, na porta **8001**, para ele nunca disputar a 8000 com o projeto
Django:

```sh
uv run uvicorn app.main:app --reload --port 8001
```

`app.main:app` é o módulo `app.main` e o objeto `app` dentro dele. O **`--reload`** vigia os arquivos
do projeto e reinicia o servidor quando um muda, o que o `runserver` do Django faz sem ninguém pedir.
Do segundo terminal:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events | python3 -m json.tool | head -12
[
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00:00-03:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
        "description": ""
    },
    {
        "slug": "async-workshop",
        "title": "Async Python workshop",
```

E no primeiro, o que o servidor imprimiu desde a partida até essa requisição:

```
ana@vm:~/agenda-api$ uv run uvicorn app.main:app --reload --port 8001
INFO:     Will watch for changes in these directories: ['/home/ana/agenda-api']
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started reloader process [204] using StatReload
INFO:     Started server process [206]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:37710 - "GET /events HTTP/1.1" 200 OK
```

O recarregador é um processo e o servidor é outro, e é por isso que aparecem dois números de processo.

A função devolveu uma lista de dicionários com objetos `datetime`, e **o FastAPI os transformou em
JSON** sem serializer: as datas como textos ISO 8601 com o deslocamento. Essa conversão é o
`jsonable_encoder` do FastAPI, e as próximas seções trocam "o que a função devolveu" por um formato
declarado.
