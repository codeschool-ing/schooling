---
title: The API's views, and the URLs a router writes
version: 1
---

The API's views go in their own module, `events/api.py`. One class handles everything about events,
and one function handles registering:

```schooling-example
{"language": "python", "file": "events/api.py", "parts": [{"code": "# events/api.py\nfrom django.db.models import Count\nfrom django.shortcuts import get_object_or_404\nfrom rest_framework import status, viewsets\nfrom rest_framework.decorators import api_view, permission_classes\nfrom rest_framework.permissions import AllowAny\nfrom rest_framework.response import Response\n\nfrom .models import Event\nfrom .serializers import EventSerializer, RegistrationSerializer\nfrom .services import RegistrationRefused, register\n\n\n", "note": "Everything the API answers with lives in `events/api.py`, apart from the HTML views."}, {"code": "class EventViewSet(viewsets.ModelViewSet):\n    serializer_class = EventSerializer\n    lookup_field = \"slug\"\n\n", "note": "**A `ModelViewSet` is five views in one class**: list, retrieve, create, update and destroy. `lookup_field = \"slug\"` puts slugs in the URLs instead of numeric ids."}, {"code": "    def get_queryset(self):\n        events = Event.objects.annotate(taken=Count(\"registrations\")).order_by(\"starts_at\")\n        venue = self.request.query_params.get(\"venue\")\n        if venue:\n            events = events.filter(venue=venue)\n        return events\n\n\n", "note": "The queryset every one of those views starts from: lesson 4's annotation, an explicit order since a `GROUP BY` drops the model's, and a filter from the query string."}, {"code": "@api_view([\"POST\"])\n", "note": "**A function view, DRF style.** `@api_view` turns `request` into DRF's request, with `request.data` parsed from JSON, and lets it return a `Response`."}, {"code": "@permission_classes([AllowAny])\ndef register_for_event(request, slug):\n    event = get_object_or_404(Event, slug=slug)\n", "note": "Registering is open to anybody, whatever the project's default says."}, {"code": "    serializer = RegistrationSerializer(data=request.data)\n    serializer.is_valid(raise_exception=True)\n", "note": "`raise_exception=True` turns invalid data into a 400 with the serializer's errors, without an `if`."}, {"code": "    try:\n        registration = register(event.pk, **serializer.validated_data)\n    except RegistrationRefused as refusal:\n        return Response({\"detail\": str(refusal)}, status=status.HTTP_409_CONFLICT)\n    return Response(RegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)\n", "note": "**The same service the form calls**, so the API gets the lock and the capacity rule for free. A refusal is a **409 Conflict**: the request was well formed and the state of the event refused it."}]}
```

`EventViewSet` is one class that answers five kinds of request, and a **router** writes the URL
patterns for it. Save the API's URL table as `events/api_urls.py`:

```python
# events/api_urls.py
from django.urls import path
from rest_framework.routers import DefaultRouter

from . import api

router = DefaultRouter()
router.register("events", api.EventViewSet, basename="event")

urlpatterns = [
    path("events/<slug:slug>/registrations/", api.register_for_event, name="register"),
    *router.urls,
]
```

And mount it under `/api/` in `config/urls.py`:

```python
# config/urls.py
from django.contrib import admin
from django.urls import include, path
from django.views.generic import TemplateView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("about/", TemplateView.as_view(template_name="about.html"), name="about"),
    path("events/", include("events.urls")),
    path("api/", include("events.api_urls")),
]
```

`DefaultRouter` adds a root that lists the resources it knows:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/ | python3 -m json.tool
{
    "events": "http://127.0.0.1:8000/api/events/"
}
```

## Reading one event

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool
{
    "slug": "django-night",
    "title": "Django Night",
    "starts_at": "2026-11-12T19:00:00-03:00",
    "venue": "Community Centre, room 3",
    "capacity": 40,
    "description": "",
    "taken": 1
}
```

The detail is the serializer's output, with `taken` this time because the viewset's queryset
annotates it. Every event in the API is addressed by its slug, which is what `lookup_field` asked
for.

## The page for people

Ask the same address for HTML, as a browser does:

```
ana@vm:~/agenda$ curl -si -H "Accept: text/html" http://127.0.0.1:8000/api/events/django-night/ | grep -E "^(HTTP|Content-Type)"
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
```

**DRF answered with a web page**: the *browsable API*, which shows the JSON, the allowed methods
and, for a logged-in user, a form for each write. Which format comes back is decided by the request's
`Accept` header, **content negotiation**, and every endpoint gets the page for free. It is a
development convenience worth keeping, and an API whose only clients are programs can switch it off
with `DEFAULT_RENDERER_CLASSES`.
