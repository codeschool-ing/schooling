---
title: The same endpoint, written twice
version: 1
---

The fastest way to see what each framework assumes is to make each of them do the same small thing.
The example is one endpoint: `GET /hello/<name>` answers with a little JSON greeting. Both projects
live in your home directory, side by side, and both are uv projects, which `python` lesson 19
introduced.

## Django

```
ana@vm:~$ mkdir hello-django && cd hello-django && uv init --bare
Initialized project `hello-django`
ana@vm:~/hello-django$ uv add django
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 5 packages in 300ms
Downloading django (8.0MiB)
 Downloaded django
Prepared 3 packages in 1.63s
Installed 3 packages in 405ms
 + asgiref==3.12.1
 + django==6.1.2
 + sqlparse==0.6.0
ana@vm:~/hello-django$ uv run django-admin startproject hello .
ana@vm:~/hello-django$ find . -path ./.venv -prune -o -type f -print | sort
./hello/__init__.py
./hello/asgi.py
./hello/settings.py
./hello/urls.py
./hello/wsgi.py
./manage.py
./pyproject.toml
./uv.lock
```

`uv init --bare` writes only `pyproject.toml`; Django brings its own layout. `startproject` made a
package called `hello` with five files and a `manage.py` beside it, **before a single line of yours
exists**. Lesson 2 goes through each of them. For now, replace the whole of `hello/urls.py` with
this:

```python
# hello/urls.py
from django.http import JsonResponse
from django.urls import path


def hello(request, name):
    return JsonResponse({"greeting": f"Hello, {name}", "framework": "Django"})


urlpatterns = [
    path("hello/<str:name>", hello),
]
```

The function takes the request and returns a response. The list at the bottom says which URL runs
it, and `<str:name>` is the part of the path that becomes the argument. Start the development server
in this terminal:

```
ana@vm:~/hello-django$ uv run python manage.py runserver 8000
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).

You have 18 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
Run 'python manage.py migrate' to apply them.
October 16, 2026 - 22:18:47
Django version 6.1.2, using settings 'hello.settings'
Starting WSGI development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.

WARNING: This is a development server. Do not use it in a production setting. Use a production WSGI or ASGI server instead.
For more information on production servers see: https://docs.djangoproject.com/en/6.1/howto/deployment/
```

It keeps running, and keeps printing a line per request, until you press Ctrl-C. **Open a second
terminal** and ask it:

```
ana@vm:~/hello-django$ curl -si http://127.0.0.1:8000/hello/ana; echo
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:18:50 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
X-Frame-Options: DENY
Content-Length: 49
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin
Cross-Origin-Opener-Policy: same-origin

{"greeting": "Hello, ana", "framework": "Django"}
ana@vm:~/hello-django$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/goodbye/ana
404
```

`-s` silences curl's progress meter, `-i` prints the headers, and the `echo` puts the prompt back on
a line of its own, since the body ends without one.

## FastAPI

In the second terminal, a second project:

```
ana@vm:~$ mkdir hello-fastapi && cd hello-fastapi && uv init --bare
Initialized project `hello-fastapi`
ana@vm:~/hello-fastapi$ uv add fastapi uvicorn
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 15 packages in 396ms
Downloading pydantic-core (2.1MiB)
 Downloaded pydantic-core
Prepared 14 packages in 164ms
Installed 14 packages in 8ms
 + annotated-doc==0.0.5
 + annotated-types==0.8.0
 + anyio==4.15.1
 + click==8.5.0
 + fastapi==0.143.3
 + h11==0.16.0
 + idna==3.20
 + opentelemetry-api==1.45.1
 + pydantic==2.14.1
 + pydantic-core==2.50.1
 + starlette==1.8.0
 + typing-extensions==4.16.0
 + typing-inspection==0.4.4
 + uvicorn==0.54.0
```

**Two packages were asked for, because FastAPI is not a server.** `uvicorn` is the program that
listens on the port and calls FastAPI; Django's `runserver` did both jobs inside one command. The
whole application is one file, `main.py`, in the project's directory:

```python
# main.py
from fastapi import FastAPI

app = FastAPI()


@app.get("/hello/{name}")
def hello(name: str):
    return {"greeting": f"Hello, {name}", "framework": "FastAPI"}
```

The decorator is the route: the method, the path, and `{name}` as its variable part. The function
returns a dictionary, and FastAPI turns it into JSON. Start it, in this terminal:

```
ana@vm:~/hello-fastapi$ uv run uvicorn main:app --port 8001
INFO:     Started server process [275]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
```

`main:app` reads as "the object `app` in the module `main`". **Open a third terminal**, and ask:

```
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8001/hello/ana; echo
HTTP/1.1 200 OK
date: Fri, 16 Oct 2026 22:18:59 GMT
server: uvicorn
content-length: 47
content-type: application/json

{"greeting":"Hello, ana","framework":"FastAPI"}
ana@vm:~/hello-fastapi$ curl -s http://127.0.0.1:8001/openapi.json | head -c 160; echo
{"openapi":"3.1.0","info":{"title":"FastAPI","version":"0.1.0"},"paths":{"/hello/{name}":{"get":{"summary":"Hello","operationId":"hello_hello__name__get","param
```

## What the two answers say

The bodies agree; everything around them is the frameworks talking about themselves.

- **Django sent four headers nobody asked for**: `X-Frame-Options: DENY`, `X-Content-Type-Options:
  nosniff`, `Referrer-Policy` and `Cross-Origin-Opener-Policy`. They come from middleware that
  `startproject` switched on, and each one tells the browser to refuse something it would otherwise
  allow, such as showing your page inside somebody else's frame. **FastAPI sent none.** Lesson 16 adds
  them in front of it.
- **FastAPI published a description of the endpoint that nobody wrote**: `/openapi.json` names the
  path, the method and the parameter, and lesson 8 turns it into a documentation page. Django has
  nothing at that address.
- **Django already expects a database.** "18 unapplied migrations" are the tables its built-in apps
  want, users, sessions and the admin, for an endpoint that uses none of them.
- **The sizes follow the assumptions.**

```
ana@vm:~$ for p in hello-django hello-fastapi; do echo "$p: $(cd $p && uv pip list 2>/dev/null | tail -n +3 | wc -l) packages, $(du -sh $p/.venv | cut -f1) in .venv"; done
hello-django: 3 packages, 47M in .venv
hello-fastapi: 14 packages, 17M in .venv
```

**Django is three packages and 47 MB; FastAPI is fourteen packages and 17 MB.** Django is one large
package because it carries everything in the table of the first section, including the admin's
pages and translations into dozens of languages. FastAPI is small pieces, each doing one job, and
more of them arrive as the application asks: a database layer in lesson 10, a password hasher in
lesson 11.

Leave both projects where they are. Press Ctrl-C in the two terminals running servers before the
next lesson, which starts the real project from nothing.
