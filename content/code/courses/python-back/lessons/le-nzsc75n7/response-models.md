---
title: Response models: the shape that leaves
version: 1
---

`response_model` declares what a route answers with, and FastAPI does three things with it: it
**validates** the function's return value against it, it **filters out** every field the model does
not name, and it describes the response in the API's documentation, which is lesson 8.

## Registering, and what comes back

The registration route answers with `RegistrationOut` and a 201:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"name":"Elisa","email":"elisa@example.org","created_at":"2026-10-22T22:32:17.635456Z"}
201
```

The person who registered gets their own address back, with the time the server set, in UTC.

## What everybody else sees

The list of who is coming is public, and the addresses in it are not. The function returns the raw
rows, address included, and the route declares `list[RegistrationPublic]`:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool
[
    {
        "name": "Elisa",
        "created_at": "2026-10-22T22:32:17.635456Z"
    }
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" aria-label=\"The registrations endpoint's function returns rows with a slug, a name, an email address and a date. The response model, a list of RegistrationPublic, names only the name and the date, so the client receives those two fields and never the email address.\"> <defs><marker id=\"rf-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"40\" width=\"210\" height=\"90\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what the function returned</text> <text x=\"32\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"slug\": \"testing-dojo\"</text> <text x=\"32\" y=\"81\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"name\": \"Elisa\"</text> <text x=\"32\" y=\"100\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"email\": \"elisa@…\"</text> <text x=\"32\" y=\"119\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"created_at\": \"2026-…\"</text> <rect x=\"280\" y=\"60\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">response_model=</text> <text x=\"365\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">list[RegistrationPublic]</text> <rect x=\"500\" y=\"40\" width=\"200\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"600\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what the client received</text> <text x=\"512\" y=\"72\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"name\": \"Elisa\"</text> <text x=\"512\" y=\"91\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"created_at\": \"2026-…\"</text> <path d=\"M230 85 L274 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rf-a)\"></path> <path d=\"M450 85 L494 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rf-a)\"></path> <text x=\"360\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Fields the response model does not name never leave the server.</text> </svg>", "caption": "The response model is a filter on the way out, so a function that returns too much cannot leak it."}
```

**The addresses did not reach the client**, and nothing in the function had to remember to remove
them. That is the property worth having: a function that returns too much, because somebody added a
field to the store next year, still cannot leak it, since the model on the way out names what may
leave. Returning the dictionary directly, with no `response_model`, would have sent every key.

## The rules on the way in still hold

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"detail":"This address is already registered."}
409
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo | python3 -m json.tool | grep -E "capacity|taken"
    "capacity": 20,
    "taken": 1
```

The duplicate was refused with 409, and the event's `taken` counts the one registration that was
made. **These rules hold only while one process holds the list.** They are the same check-then-append
as Django's lesson 3, two steps nothing ties together, and lesson 16 runs several worker processes,
each with its own copy of `REGISTRATIONS` that the others never see. Lesson 10 moves them onto
PostgreSQL, which every process shares, with the same lock lesson 4 used.
