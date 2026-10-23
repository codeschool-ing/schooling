---
title: URLs, from the project to the app
version: 1
---

Django reads `ROOT_URLCONF`, `config/urls.py`, for every request, and tries its patterns in order
until one matches. **The project's table should stay short**: it says which app owns which prefix,
and each app keeps its own table. Replace `config/urls.py` with this, keeping the admin's line:

```python
# config/urls.py
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("events/", include("events.urls")),
]
```

`include("events.urls")` hands everything under `/events/` to the app. Create its table as
`events/urls.py`:

```python
# events/urls.py
from django.urls import path

from . import views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.event_detail, name="detail"),
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The path /events/testing-dojo/ is matched in two steps. config/urls.py matches the prefix events/ and hands the rest to the app's own urls.py, which matches &lt;slug:slug&gt;/ against testing-dojo/ and calls event_detail with slug set to testing-dojo.\"> <defs><marker id=\"ui-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">GET /events/testing-dojo/</text> <rect x=\"20\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">config/urls.py</text> <text x=\"125\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">path(\"events/\",</text> <text x=\"125\" y=\"121\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">include(\"events.urls\"))</text> <text x=\"125\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">matches and removes events/</text> <rect x=\"255\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">events/urls.py</text> <text x=\"360\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">path(\"&lt;slug:slug&gt;/\",</text> <text x=\"360\" y=\"121\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">views.event_detail)</text> <text x=\"360\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sees only testing-dojo/</text> <rect x=\"490\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">event_detail(request,</text> <text x=\"595\" y=\"111\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">slug=\"testing-dojo\")</text> <text x=\"595\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the converter made the argument</text> <path d=\"M230 106 L249 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ui-a)\"></path> <path d=\"M465 106 L484 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ui-a)\"></path> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The app never sees the prefix, so mounting it at another address changes one line in config/urls.py.</text> </svg>", "caption": "include() is a hand-over: the project's urls.py owns the prefix, the app's owns everything after it."}
```

## Converters, the typed part of a path

`<slug:slug>` matches a **slug**, letters, digits, hyphens and underscores, and passes it to the view
as the argument `slug`. A path that does not fit the converter matches nothing, so the view never
sees it:

| converter | matches | the view receives |
|---|---|---|
| `str` | anything but a slash, and the default | a `str` |
| `int` | digits | an `int` |
| `slug` | letters, digits, `-` and `_` | a `str` |
| `uuid` | a UUID | a `uuid.UUID` |
| `path` | anything, slashes included | a `str` |

## Names, so nothing has to write a URL twice

`app_name = "events"` and `name="detail"` give each pattern a name, `events:detail`, and the
project can build the URL from the name instead of writing the string again. `reverse` builds a
path, and `resolve` goes the other way, from a path to the view:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.urls import reverse; print(reverse(\"events:detail\", args=[\"testing-dojo\"]))"
12 objects imported automatically (use -v 2 for details).

/events/testing-dojo/
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.urls import resolve; m = resolve(\"/events/testing-dojo/\"); print(m.view_name, m.func.__name__, m.kwargs)"
12 objects imported automatically (use -v 2 for details).

events:detail event_detail {'slug': 'testing-dojo'}
```

The line about **12 objects imported automatically** is Django's shell telling you it imported the
models and common helpers for you; it prints it before running the command. Lesson 3 uses the same
names inside templates, and changing a URL later is one edit in `urls.py` with every link following
it.

## The trailing slash

Every pattern here ends in `/`, and Django adds one for you when it is missing:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night | head -4
HTTP/1.1 301 Moved Permanently
Date: Fri, 16 Oct 2026 22:37:18 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: text/html; charset=utf-8
```

`CommonMiddleware`, with its setting `APPEND_SLASH` on by default, sees that `/events/django-night`
matches nothing, that `/events/django-night/` would, and answers **301** pointing there. A browser
follows the redirect without the user noticing. A client posting JSON to the address without the
slash does not get its body forwarded, which is why APIs in lesson 6 are called with the slash.
