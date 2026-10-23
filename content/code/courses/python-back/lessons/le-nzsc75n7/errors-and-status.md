---
title: Errors you raise, and the status codes they carry
version: 1
---

Validation answers for itself. Every other refusal is raised by your code, with `HTTPException`, and
the code that a client acts on is the status. Creating an event, then creating it again:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events
{"slug":"pycon-watch","title":"PyCon talks, watched together","starts_at":"2026-12-03T19:00:00-03:00","venue":"Public Library, lab 2","capacity":15,"description":"","taken":0}
201
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"Again\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events
{"detail":"pycon-watch already exists"}
409
```

**201, then 409** with the message the route wrote. `status.HTTP_409_CONFLICT` and the other
constants in `fastapi.status` are the numbers with their names, which makes a route readable without
a table of codes beside it.

## A method nobody declared

```
ana@vm:~/agenda-api$ curl -si -X DELETE http://127.0.0.1:8001/events/pycon-watch | grep -iE "^(HTTP|allow)"
HTTP/1.1 405 Method Not Allowed
allow: GET
```

There is no `DELETE` route for an event, and FastAPI answered **405 with an `allow` header** listing
the methods the path does have, as Django's `require_GET` did in lesson 2.

## The codes this API uses

| code | when | raised by |
|---|---|---|
| 200 | a read | the default |
| 201 | something was created | `status_code=` on the route |
| 404 | the event does not exist | `find_event` |
| 405 | the method has no route | FastAPI |
| 409 | the request is fine and the state refuses it | the route, with `HTTPException` |
| 422 | the data does not fit the model | Pydantic, before the route runs |

**Do not answer 200 with `{"error": …}` in the body.** It is the mistake APIs most often make, and it
forces every client to parse every response to find out whether it failed. The status line exists so
that a client, a proxy and a log line can all tell success from failure without reading a byte of the
body.
