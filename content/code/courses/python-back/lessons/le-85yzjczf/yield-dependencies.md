---
title: Dependencies with yield: before, and after
version: 1
---

Some things a route needs have to be given back: a lock, a file, a database connection. A dependency
that **yields** instead of returning gets both halves. The code before `yield` runs before the route;
the value it yields is what the route receives; the code after it runs when the route is finished.
`registration_lock` in `app/dependencies.py` holds a lock around every registration, and prints when
it takes and releases it. Two registrations, the second refused:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations
{"name":"Gil","email":"gil@example.org","created_at":"2026-10-22T22:42:42.309531Z"}
201
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations
{"detail":"This address is already registered."}
409
```

And what the server printed while they ran:

```
lock held
registered gil@example.org
INFO:     127.0.0.1:47132 - "POST /events/django-night/registrations HTTP/1.1" 201 Created
lock released
lock held
lock released
INFO:     127.0.0.1:47134 - "POST /events/django-night/registrations HTTP/1.1" 409 Conflict
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two timelines read from the server's log. For a successful registration the lock is held, the route runs, the response is sent, and then the finally block releases the lock. For a refused one the lock is held, the route raises, the finally block releases the lock, and then the 409 is sent.\"> <defs><marker id=\"tl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">a 201</text> <rect x=\"70\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lock held</text> <rect x=\"190\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"245.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">route runs</text> <rect x=\"310\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"365.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">response sent</text> <rect x=\"450\" y=\"40\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"535.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finally: lock released</text> <path d=\"M180 55 L184 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M300 55 L304 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M420 55 L444 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <text x=\"20\" y=\"116\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a 409</text> <rect x=\"70\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lock held</text> <rect x=\"190\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"245.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">route raises</text> <rect x=\"310\" y=\"130\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"395.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finally: lock released</text> <rect x=\"490\" y=\"130\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"545.0\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">409 sent</text> <path d=\"M180 145 L184 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M300 145 L304 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <path d=\"M480 145 L484 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#tl-a)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The exception arrives at the yield; only a finally or a with block runs after it.</text> </svg>", "caption": "The order of the log lines, drawn. Code written after the yield without a finally would have run only in the first case."}
```

Read the two halves of the log apart. For the 201, **the lock was released after Uvicorn logged the
response**, which it does as the response starts going out: code after `yield` ran once the route was
done with it. For the 409, the route raised `HTTPException`, and **the exception arrived at the
`yield`**: the release came before the response, and a line written after `yield` without `finally`
would not have run at all. That is why the dependency wraps its `yield` in `try`/`finally`, inside a
`with` that releases the lock whatever happens.

## What it protects, and what it does not

The lock makes the count and the append of one registration happen together **inside this process**.
That is all it can do. Lesson 16 runs the API in several worker processes, each with its own lock and
its own list, so the real fix is lesson 10's: the registrations go into PostgreSQL, and the lock is a
row lock every process shares. **The shape stays**: lesson 10's database session is a dependency with
`yield` exactly like this one, opened before the route and closed after it.
