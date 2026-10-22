---
title: Async in Django
version: 1
---

Django has supported `async def` views since version 3.1, and they work under both servers:
under WSGI, Django runs each one in an event loop of its own for the length of the request; under
ASGI, they share the server's loop, which is where the waiting overlaps. Lesson 1 noticed the
project already had `config/asgi.py`. The agenda project needs the partner's client, and an ASGI
server, since `runserver` is a WSGI one:

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

## An async view

A forecast for an event, from the same slow partner, saved as `events/forecast.py`:

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

And its address, in `events/urls.py`:

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

`aget_object_or_404` is the `async` version of lesson 4's shortcut. **The ORM has an async name for
every method that runs a query**, with an `a` in front, `aget`, `acount`, `acreate`, and `async for`
over a QuerySet. The ordinary names are refused inside async code, which is easy to show. Save this
as `orm_async.py` in `~/agenda`:

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

**`SynchronousOnlyOperation`**: Django refused to run a blocking query on an event loop, the exact
mistake of the previous section, caught for you. The `a` version worked. Underneath, the async ORM
still runs the query in a thread, since the database driver it uses is synchronous; what it saves you
is blocking the loop.

## Under Uvicorn

Run the project as an ASGI application with `uv run uvicorn config.asgi:application --port 8000`,
with the partner still on 8002:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/testing-dojo/forecast/; echo
{"event": "Testing dojo", "venue": "testing-dojo", "rain": "unlikely"}
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/nope/forecast/
404
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8000/events/testing-dojo/forecast/ 20
20 requests, status [200], 1.6 s
```

The view answered, an unknown slug was a 404, and **twenty requests took 1.6 seconds**: the waits for
the partner overlapped, as they did in FastAPI.

## Whether agenda should do this

Not yet, and the reason is in the rest of the Django code: every other view in agenda is synchronous,
and so is the admin. Under ASGI, Django runs each synchronous view in a thread, which works and costs
a little on every request. A Django site gains from ASGI when it has views that **wait on the network
a lot**, or long-lived connections such as WebSockets. agenda serves pages from a database a few
milliseconds away, so it keeps WSGI and Gunicorn in lesson 16, and this view is the example of how,
not a recommendation.
