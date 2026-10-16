---
title: The same view as a class
version: 1
---

A view can also be a class. Django calls a method of it named after the HTTP method, `get` for a GET
and `post` for a POST, and answers 405 for any method the class does not define. Here is
`event_detail` again, as a class, in the whole of `events/views.py`:

```python
# events/views.py
from django.http import Http404, JsonResponse
from django.views import View
from django.views.decorators.http import require_GET

from .data import EVENTS


@require_GET
def event_list(request):
    venue = request.GET.get("venue")
    events = [e for e in EVENTS if venue is None or e["venue"] == venue]
    return JsonResponse({"count": len(events), "events": events})


class EventDetailView(View):
    def get(self, request, slug):
        for event in EVENTS:
            if event["slug"] == slug:
                return JsonResponse(event)
        raise Http404(f"No event called {slug}")
```

The URL table points at the class through `as_view()`, which builds the function Django calls:

```python
# events/urls.py
from django.urls import path

from . import views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.EventDetailView.as_view(), name="detail"),
]
```

It answers exactly as before, and the method handling came for free:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/; echo
{"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}
ana@vm:~/agenda$ curl -si -X OPTIONS http://127.0.0.1:8000/events/async-workshop/ | grep -iE "^(HTTP|allow)"
HTTP/1.1 200 OK
Allow: GET, HEAD, OPTIONS
```

**`OPTIONS` now answers 200 with the methods the class defines**, which the function with
`require_GET` answered with a 405. `View` implements `options()` for every class, and lists `HEAD`
too, because a class with a `get` answers `HEAD` with the same headers and no body.

## Which one to write

| | a function | a class |
|---|---|---|
| reads as | the code, top to bottom | the methods, plus whatever the base class does |
| methods | one function, an `if` per method, or a decorator | one method per HTTP method |
| reuse | helper functions | inheritance and mixins |
| best for | a view that does one thing | a family of views that differ in a detail |

The class is worth its indirection when **Django already wrote the view you need**. `ListView`,
`DetailView`, `CreateView` and their relatives are classes that fetch rows, render a template and
handle a form, configured with a few attributes instead of written. They need models and templates
to work with, so lesson 3 uses `TemplateView` and lesson 4 the ones built on the database. For a
view that does one specific thing, a function stays the clearer choice, and Django's own
documentation says so.
