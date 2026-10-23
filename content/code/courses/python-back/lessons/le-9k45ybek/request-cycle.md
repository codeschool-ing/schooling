---
title: The trip a request makes
version: 1
---

Between the server and your view sits a stack of **middleware**, the list called `MIDDLEWARE` in
`settings.py`. Each one is a layer around everything below it: it sees the request on the way in,
can stop it and answer on its own, and sees the response on the way out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The middleware listed in settings, top to bottom, wraps the view like the layers of an onion. A request goes down through every layer to the URL resolver and the view; the response comes back up through the same layers in reverse order. CsrfViewMiddleware is highlighted: a POST without a CSRF token is refused there with a 403, before the view is reached.\"> <defs><marker id=\"rc-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"rc-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"170\" y=\"46\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">request</text> <text x=\"550\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">response</text> <rect x=\"200\" y=\"36\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"51\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TimingMiddleware</text> <rect x=\"200\" y=\"64\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"79\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SecurityMiddleware</text> <rect x=\"200\" y=\"92\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionMiddleware</text> <rect x=\"200\" y=\"120\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CommonMiddleware</text> <rect x=\"200\" y=\"148\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.25\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"163\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CsrfViewMiddleware</text> <rect x=\"200\" y=\"176\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AuthenticationMiddleware</text> <rect x=\"200\" y=\"204\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MessageMiddleware</text> <rect x=\"200\" y=\"232\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"247\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">XFrameOptionsMiddleware</text> <rect x=\"200\" y=\"270\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"291\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">URL resolver, then the view</text> <path d=\"M180 36 L180 282 L194 282\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-a)\"></path> <path d=\"M526 290 L540 290 L540 42\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-a)\"></path> <text x=\"556\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a POST with no</text> <text x=\"556\" y=\"155\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token stops here:</text> <text x=\"556\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">403, and the view</text> <text x=\"556\" y=\"185\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">never runs</text> <path d=\"M552 160 L526 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-b)\"></path> </svg>", "caption": "Each middleware sees the request on the way in and the response on the way out. TimingMiddleware is first in the list, so it starts its clock before every other layer and stops it after all of them."}
```

The four security headers of lesson 1 are added on the way out by `SecurityMiddleware` and
`XFrameOptionsMiddleware`. The redirect that added a slash came from `CommonMiddleware` on the way
in. And a cookie becomes `request.user` in `AuthenticationMiddleware`, before any view is called.

## A middleware of your own

A middleware is a class built once with the next layer, `get_response`, and called once per request.
This one measures how long everything below it took and says so in a standard header,
`Server-Timing`, which browsers show in their developer tools. Save it as `events/middleware.py`:

```python
# events/middleware.py
import time


class TimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        started = time.perf_counter()
        response = self.get_response(request)
        elapsed = (time.perf_counter() - started) * 1000
        response["Server-Timing"] = f"app;dur={elapsed:.1f}"
        return response
```

The line **before** `get_response` runs on the way in; the lines **after** it run on the way out,
with the response in hand. Add it at the top of `MIDDLEWARE`, so it wraps every other layer:

```
ana@vm:~/agenda$ sed -n '/^MIDDLEWARE/,/^]/p' config/settings.py
MIDDLEWARE = [
    'events.middleware.TimingMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

A change to `settings.py` restarts `runserver` too. Then:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing|x-frame)"
HTTP/1.1 200 OK
X-Frame-Options: DENY
Server-Timing: app;dur=1.9
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/nope/ | grep -iE "^(HTTP|server-timing)"
HTTP/1.1 404 Not Found
Server-Timing: app;dur=3.6
```

The milliseconds are the whole trip below the timing layer, and they change on every request. The
404 went through the same layers and was timed too: an exception raised in a view is turned into a
response before it reaches the middleware, so every layer still sees a response come back.

## A layer that answers before the view

```
ana@vm:~/agenda$ curl -si -X POST http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing)"
HTTP/1.1 403 Forbidden
Server-Timing: app;dur=3.0
```

This POST did not get a 405 from `require_GET`, as the `OPTIONS` request of the previous section
did. It got **403 Forbidden**, and the server's log said why: `Forbidden (CSRF cookie not set.)`.
`CsrfViewMiddleware` refuses any POST that does not carry a token proving it came from a form this
site served, and **it runs before the view**, so the view's own rule was never consulted. The timing
layer, above it, still timed the refusal. Lesson 3 adds the token to a form, which is what makes a
POST from a browser work, and lesson 6 explains why an API authenticated with a token rather than
a cookie does not need it.

## Order is behaviour

Middleware runs in list order on the way in and in reverse on the way out, so moving a line changes
what the application does. `SecurityMiddleware` is first among Django's so that its redirect to
HTTPS, in production, happens before any work is done; `AuthenticationMiddleware` comes after
`SessionMiddleware` because it reads the session that one loads. Django's documentation lists the
order each of its middleware needs, and a new one goes where its job says, which for most of yours
is after Django's.
