---
title: Views, the functions that answer
version: 1
---

A **view** is a function that receives an `HttpRequest` and returns an `HttpResponse`. Everything
else about Django exists to get a request to the right view and the response back out. Replace
`events/views.py` with this:

```schooling-example
{"language": "python", "file": "events/views.py", "parts": [{"code": "from django.http import Http404, JsonResponse\nfrom django.views.decorators.http import require_GET\n\nfrom .data import EVENTS\n\n\n", "note": "**A view is a function that takes a request and returns a response.** These two return JSON; lesson 3 makes them return pages."}, {"code": "@require_GET\ndef event_list(request):\n", "note": "`require_GET` answers any other method with **405 Method Not Allowed** before the function runs."}, {"code": "    venue = request.GET.get(\"venue\")\n", "note": "`request.GET` is the query string, as a dictionary. `.get` returns `None` when the parameter is absent."}, {"code": "    events = [e for e in EVENTS if venue is None or e[\"venue\"] == venue]\n    return JsonResponse({\"count\": len(events), \"events\": events})\n\n\n", "note": "`JsonResponse` serialises the dictionary and sets `Content-Type: application/json`."}, {"code": "@require_GET\ndef event_detail(request, slug):\n", "note": "`slug` arrives as an argument because the URL pattern names it: `<slug:slug>`."}, {"code": "    for event in EVENTS:\n        if event[\"slug\"] == slug:\n            return JsonResponse(event)\n    raise Http404(f\"No event called {slug}\")\n", "note": "**Raising `Http404` is how a view says \"no such thing\".** Django turns it into a 404 response."}]}
```

`runserver` reloads by itself when a file changes, so with it still running in the first terminal,
ask from the second:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/; echo
{"count": 3, "events": [{"slug": "django-night", "title": "Django Night", "starts_at": "2026-11-12T19:00", "venue": "Community Centre, room 3", "capacity": 40}, {"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}, {"slug": "testing-dojo", "title": "Testing dojo", "starts_at": "2026-11-26T19:00", "venue": "Community Centre, room 3", "capacity": 20}]}
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?venue=Public%20Library,%20lab%202"; echo
{"count": 1, "events": [{"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}]}
```

The second call filtered with `?venue=`, which curl had to send with its spaces written as `%20`.
**The query string arrives already decoded** in `request.GET`: the view compared plain text.

## One event, and one that does not exist

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night/; echo
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:37:18 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
X-Frame-Options: DENY
Content-Length: 135
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin
Cross-Origin-Opener-Policy: same-origin

{"slug": "django-night", "title": "Django Night", "starts_at": "2026-11-12T19:00", "venue": "Community Centre, room 3", "capacity": 40}
```

The same four security headers from lesson 1 are there, on every response, because they come from
middleware rather than from the view. And when the slug matches no event:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/no-such-event/
404
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/a%20space/
404
```

Two 404s for two different reasons. `no-such-event` matched the pattern, reached the view, and the
view raised `Http404`. `a%20space` is a path with a space in it, which the `slug` converter does not
accept, so no pattern matched and **the view never ran**. With `DEBUG` on, both 404 pages list the
patterns Django tried, which is the fastest way to find a typo in `urls.py`, and the first also
names the view that raised it and its message, `No event called no-such-event`.

## A method the view does not accept

```
ana@vm:~/agenda$ curl -si -X OPTIONS http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|allow)"
HTTP/1.1 405 Method Not Allowed
Allow: GET
```

`require_GET` answered before the view's body ran, with **405 Method Not Allowed** and an `Allow`
header naming the method it does accept. `OPTIONS` is the method a client sends to ask exactly that
question.

## What a request carries

| attribute | what it is |
|---|---|
| `request.method` | `"GET"`, `"POST"`, … |
| `request.GET` | the query string, as a dictionary of lists |
| `request.POST` | a submitted form (lesson 3) |
| `request.body` | the raw bytes of the body, for JSON |
| `request.headers` | the headers, case-insensitive: `request.headers["Accept"]` |
| `request.user` | who is logged in, added by middleware (lesson 11) |

`request.user` is the interesting one: **nothing in the request carried a user**. Middleware read a
cookie and attached one before the view was called, and the next section is about that layer.
