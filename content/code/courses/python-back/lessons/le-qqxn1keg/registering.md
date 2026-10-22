---
title: Registering through the API, and the right status codes
version: 1
---

Registration is a POST to `/api/events/<slug>/registrations/`, open to anybody, handled by
`register_for_event` in `events/api.py`:

```
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"name":"Elisa","email":"elisa@example.org","created_at":"2026-10-22T19:13:36.419630-03:00"}
201
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"This address is already registered."}
409
```

**201, then 409.** The second request was perfectly well formed; what refused it was the state of the
data, a registration that already exists, and **409 Conflict** is the code for exactly that. The
message is the service's own. The other refusals each get the code that describes them:

```
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"not-an-address\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"email":["Enter a valid email address."]}
400
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"fabio@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/async-workshop/registrations/
{"detail":"This event is full."}
409
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"JSON parse error - Expecting ',' delimiter: line 1 column 17 (char 16)"}
400
ana@vm:~/agenda$ curl -s -X GET -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"Method \"GET\" not allowed."}
405
```

| answer | why | who decided |
|---|---|---|
| **400** `email` | the data does not have the right shape | the serializer |
| **409** full | the data is fine; the event has no seats | `register`, under its lock |
| **400** `JSON parse error` | the body is not JSON at all | DRF's parser, before the view |
| **405** `GET` | the view accepts only POST | `@api_view(["POST"])` |

## Why no CSRF token this time

Lesson 2 promised an answer here. Those POSTs carried no cookie and no token, and were accepted.
**DRF checks CSRF only for requests authenticated by a session cookie**, because CSRF is an attack on
cookies: a browser attaches them automatically to a request another site made it send. A request
with no cookie, or one that authenticates with a header the browser never adds by itself, cannot be
forged that way. So the registration endpoint, anonymous, needs no token; a logged-in browser using
the same endpoint through its session would need one; and the token authentication of lesson 11
needs none.
