---
title: WSGI and ASGI, the contract under both
version: 1
---

The first section said the server and the framework are two programs. They can be two programs
because Python defines what one says to the other, and the same server can run any framework that
keeps the contract. There are two contracts, and the file list `startproject` printed contains
both: `hello/wsgi.py` and `hello/asgi.py`.

## WSGI: one call, one answer

**WSGI**, the Web Server Gateway Interface, dates from 2003 and was updated for Python 3 in 2010 as
PEP 3333. An application is a function the server calls once per request, with two arguments: a
dictionary describing the request, and a function to call with the status and the headers. What
it returns is the body. This is the whole of a WSGI application, with no framework at all, and a
server from Python's standard library to run it:

```python
# wsgi_app.py
import json
from wsgiref.simple_server import make_server


def app(environ, start_response):
    name = environ["PATH_INFO"].removeprefix("/hello/")
    body = json.dumps({"greeting": f"Hello, {name}", "framework": None}).encode()
    start_response("200 OK", [("Content-Type", "application/json")])
    return [body]


if __name__ == "__main__":
    make_server("127.0.0.1", 8002, app).serve_forever()
```

## ASGI: messages, sent and received

**ASGI**, the Asynchronous Server Gateway Interface, came out of the Django project in 2016 and
reached version 3.0 in 2019. An application is an `async` function, called with a dictionary
describing the connection, `scope`, and two functions, `receive` and `send`. It answers by
**sending messages**: one with the status and the headers, then one or more with the body.

```python
# asgi_app.py
import json


async def app(scope, receive, send):
    name = scope["path"].removeprefix("/hello/")
    body = json.dumps({"greeting": f"Hello, {name}", "framework": None}).encode()
    await send({
        "type": "http.response.start",
        "status": 200,
        "headers": [(b"content-type", b"application/json")],
    })
    await send({"type": "http.response.body", "body": body})
```

Save both in `~/hello-fastapi`, whose environment already has uvicorn. Run the first with
`uv run python wsgi_app.py` and the second with `uv run uvicorn asgi_app:app --port 8003`, each in
a terminal of its own, and ask both:

```
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8002/hello/ana; echo
HTTP/1.0 200 OK
Date: Fri, 16 Oct 2026 22:19:00 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
Content-Length: 45

{"greeting": "Hello, ana", "framework": null}
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8003/hello/ana; echo
HTTP/1.1 200 OK
date: Fri, 16 Oct 2026 22:18:59 GMT
server: uvicorn
content-type: application/json
Transfer-Encoding: chunked

{"greeting": "Hello, ana", "framework": null}
```

The server line of the first answer is the one Django's `runserver` sent, `WSGIServer/0.2`:
**`runserver` is the standard library's WSGI server with Django's application inside it.** And the
second answer is chunked, because the application sent the headers before the server knew how long
the body would be, which is exactly what a stream of messages allows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two lanes. In WSGI the server calls the application once with the request and gets the body back as the return value; the call blocks until the application is done. In ASGI the server calls an async application with the connection, and the application sends a message with the status and headers, then one or more messages with the body, and may receive messages too, while the server serves other connections in the meantime.\"> <defs><marker id=\"ga-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ga-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">WSGI</text> <rect x=\"80\" y=\"44\" width=\"120\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">server</text> <rect x=\"464\" y=\"44\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"584\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">application</text> <text x=\"584\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">def app(environ, start_response)</text> <path d=\"M200 70 L458 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one call per request</text> <path d=\"M464 104 L206 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the return value is the body</text> <text x=\"20\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">ASGI</text> <rect x=\"80\" y=\"150\" width=\"120\" height=\"100\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">server</text> <rect x=\"464\" y=\"150\" width=\"240\" height=\"100\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"584\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">application</text> <text x=\"584\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">async def app(scope, receive, send)</text> <path d=\"M200 166 L458 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">called once per connection</text> <path d=\"M464 192 L206 192\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-amber)\"></path> <text x=\"332\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http.response.start</text> <path d=\"M464 218 L206 218\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-amber)\"></path> <text x=\"332\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http.response.body</text> <text x=\"332\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">messages, while other connections are served</text> </svg>", "caption": "WSGI is a function call that blocks until it returns. ASGI is a conversation in messages, and while one application waits, the server can serve another connection."}
```

## Why the difference matters

**A WSGI call holds its worker until it returns.** If the function spends two seconds waiting for
another service, that worker does nothing else for two seconds, and a server with eight workers
answers at most eight such requests at a time. **An ASGI application can `await` the slow answer**,
and the server serves other connections in the meantime. ASGI can also keep a connection open and
send messages down it whenever there is something to say, which is what a WebSocket needs and WSGI
cannot express at all.

That is the honest size of the advantage: it matters when requests spend their time **waiting**,
and it does nothing for a request that spends its time computing. Lesson 9 measures both cases.

In this course the pairs are fixed. **Django runs under WSGI** in lessons 2 to 16, as most Django
sites do, with Gunicorn as the server in production; it can run under ASGI too, and lesson 9 shows
when that helps. **FastAPI runs only under ASGI**, with Uvicorn. Neither framework has to change for
the server to change, which is the whole point of a contract.
