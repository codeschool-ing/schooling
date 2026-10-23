---
title: Static files: the CSS, and where it is served from
version: 1
---

A stylesheet, an image, a script: files that are the same for everybody and never pass through a
view are **static files**. Django finds them the way it finds templates, in a `static/` directory
inside each app, with the app's name repeated so two apps cannot collide. Save this as
`events/static/events/agenda.css`:

```css
/* events/static/events/agenda.css */
body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; }
header a { font-weight: bold; text-decoration: none; }
.errorlist { color: #b00020; }
```

The base template links it with `{% static 'events/agenda.css' %}`, which turns the path inside
`static/` into the address the file is served at:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/ | grep stylesheet
  <link rel="stylesheet" href="/static/events/agenda.css">
```

`/static/` is `STATIC_URL` from `settings.py`. And the file is there:

```
ana@vm:~/agenda$ curl -sI http://127.0.0.1:8000/static/events/agenda.css | grep -E "^(HTTP|Content-Type|Content-Length)"
HTTP/1.1 200 OK
Content-Type: text/css
Content-Length: 206
```

**`runserver` served it because `DEBUG` is on.** The `staticfiles` app, switched on by
`startproject`, adds a handler for `/static/` to the development server and nothing else. With
`DEBUG` off, or under Gunicorn, nothing in Django serves these files, and that is deliberate: a
Python process is the slowest thing in the stack to hand out the same bytes to everybody.

## In production

Two settings and one command change that, and lesson 16 does all three:

| | what it does |
|---|---|
| `STATIC_ROOT` | one directory where every app's static files are gathered |
| `manage.py collectstatic` | copies each app's `static/` into `STATIC_ROOT`, with Django's own files, including the admin's |
| nginx in front | serves `STATIC_ROOT` at `/static/` directly, and passes everything else to Django |

The template does not change: `{% static %}` writes the same address in both places, which is why
every link to a static file should go through it rather than being typed.
