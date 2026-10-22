---
title: A viewset is five views
version: 1
---

The router registered `events` under two patterns, and the viewset answers each method on them:

| method and address | the viewset's method | answer |
|---|---|---|
| `GET /api/events/` | `list` | 200, a page of events |
| `POST /api/events/` | `create` | 201, the new event |
| `GET /api/events/<slug>/` | `retrieve` | 200, one event |
| `PUT`, `PATCH /api/events/<slug>/` | `update`, `partial_update` | 200, the changed event |
| `DELETE /api/events/<slug>/` | `destroy` | 204, nothing |

## Writing needs somebody

Reading was open. A write from an anonymous client:

```
ana@vm:~/agenda$ curl -si -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | sed -n "1p;\$p"; echo
HTTP/1.1 403 Forbidden
{"detail":"Authentication credentials were not provided."}
```

**403, `Authentication credentials were not provided.`** That is `IsAuthenticatedOrReadOnly`: a
PATCH is a write. DRF accepts **HTTP Basic authentication** by default, a user name and password in
a header, which curl sends with `-u`. It is the quickest way to test, and lesson 11 replaces it with
tokens, since a password sent with every request is only acceptable over HTTPS and barely then. As
lesson 5's superuser:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool
{
    "slug": "django-night",
    "title": "Django Night",
    "starts_at": "2026-11-12T19:00:00-03:00",
    "venue": "Community Centre, room 3",
    "capacity": 45,
    "description": "",
    "taken": 1
}
```

A `PATCH` changes only the fields it sends: Django Night now has 45 seats. A new event is a POST to
the list, and removing it is a DELETE on its address:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X POST -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/
{"slug":"pycon-watch","title":"PyCon talks, watched together","starts_at":"2026-12-03T19:00:00-03:00","venue":"Public Library, lab 2","capacity":15,"description":""}
201
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X DELETE -w "%{http_code}\n" http://127.0.0.1:8000/api/events/pycon-watch/
204
```

**201 Created** with the new event, and **204 No Content** for the deletion: the API's answers carry
their meaning in the status code, so a client can act on it without reading the body. The created
event has no `taken`, for the reason the serializers section gave: it came back from `save()`, not
from the annotated queryset.

## When not to use a viewset

The registration endpoint is a function, because it is one action that does not fit five standard
verbs on a resource. A viewset for something that is not a collection of rows produces routes nobody
should call; a function, or DRF's `APIView` class, says exactly what exists.
