---
title: Async no Django
version: 1
---

O Django aceita views `async def` desde a versão 3.1, e elas funcionam nos dois servidores: sob WSGI, o
Django roda cada uma num event loop próprio durante a requisição; sob ASGI, elas dividem o loop do
servidor, que é onde as esperas se sobrepõem. A aula 1 reparou que o projeto já tinha o
`config/asgi.py`. O projeto agenda precisa do cliente do parceiro, e de um servidor ASGI, já que o
`runserver` é WSGI:

```
ana@vm:~/agenda$ uv add httpx2 uvicorn
Resolved 17 packages in 86ms
Installed 8 packages in 3ms
 + anyio==4.15.1
 + click==8.5.0
 + h11==0.16.0
 + httpcore2==2.16.0
 + httpx2==2.16.0
 + idna==3.20
 + truststore==0.10.5
 + uvicorn==0.54.0
```

## Uma view async

Uma previsão para um evento, do mesmo parceiro lento, salva como `events/forecast.py`:

```python
# events/forecast.py
import httpx2
from django.http import JsonResponse
from django.shortcuts import aget_object_or_404

from .models import Event

PARTNER = "http://127.0.0.1:8002/forecast/"


async def forecast(request, slug):
    event = await aget_object_or_404(Event, slug=slug)
    async with httpx2.AsyncClient() as client:
        answer = await client.get(PARTNER + event.slug)
    return JsonResponse({"event": event.title, **answer.json()})
```

E o endereço dela, no `events/urls.py`:

```python
# events/urls.py
from django.urls import path

from . import forecast, views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.event_detail, name="detail"),
    path("<slug:slug>/forecast/", forecast.forecast, name="forecast"),
]
```

O `aget_object_or_404` é a versão `async` do atalho da aula 4. **O ORM tem um nome async para todo
método que roda uma consulta**, com um `a` na frente, `aget`, `acount`, `acreate`, e `async for` sobre um
QuerySet. Os nomes comuns são recusados dentro de código async, o que é fácil de mostrar. Salve isto
como `orm_async.py` em `~/agenda`:

```python
# orm_async.py
import asyncio

from events.models import Event


async def wrong():
    return Event.objects.get(slug="django-night")


async def right():
    return await Event.objects.aget(slug="django-night")


try:
    asyncio.run(wrong())
except Exception as error:
    print(type(error).__name__, "-", error)

print(asyncio.run(right()))
```

```
ana@vm:~/agenda$ uv run python manage.py shell < orm_async.py
14 objects imported automatically (use -v 2 for details).

SynchronousOnlyOperation - You cannot call this from an async context - use a thread or sync_to_async.
Django Night
```

**`SynchronousOnlyOperation`**: o Django se recusou a rodar uma consulta bloqueante num event loop,
exatamente o erro da seção anterior, pego por você. A versão com `a` funcionou. Por baixo, o ORM async
ainda roda a consulta numa thread, já que o driver de banco que ele usa é síncrono; o que ele poupa é o
bloqueio do loop.

## Sob o Uvicorn

Rode o projeto como aplicação ASGI com `uv run uvicorn config.asgi:application --port 8000`, com o
parceiro ainda na 8002:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/testing-dojo/forecast/; echo
{"event": "Testing dojo", "venue": "testing-dojo", "rain": "unlikely"}
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/nope/forecast/
404
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8000/events/testing-dojo/forecast/ 20
20 requests, status [200], 1.6 s
```

A view respondeu, um slug desconhecido foi 404, e **vinte requisições levaram 1,6 segundo**: as esperas
pelo parceiro se sobrepuseram, como no FastAPI.

## Se o agenda deve fazer isso

Ainda não, e o motivo está no resto do código Django: toda outra view do agenda é síncrona, e o admin
também. Sob ASGI, o Django roda cada view síncrona numa thread, o que funciona e custa um pouco em toda
requisição. Um site Django ganha com ASGI quando tem views que **esperam muito pela rede**, ou conexões
longas como WebSockets. O agenda serve páginas a partir de um banco a poucos milissegundos, então fica
com WSGI e Gunicorn na aula 16, e esta view é o exemplo de como fazer, não uma recomendação.
