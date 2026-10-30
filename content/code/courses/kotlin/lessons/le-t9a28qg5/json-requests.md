---
title: JSON in, JSON out, and the requests that are refused
version: 1
---

`@Serializable` on `Session` is all the serialization plugin needs: **it generates, at compile time, the
code that turns a `Session` into JSON and back**, with no reflection at run time. `ContentNegotiation`
is the Ktor plugin that uses it, reading the request's `Content-Type` and choosing the format.

A POST carries a session in its body. `-i` shows the response's status line and headers:

```
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"android-apps","minutes":30}'
HTTP/1.1 201 Created
Content-Length: 38
Content-Type: application/json

{"course":"android-apps","minutes":30}
ana@vm:~/kt/server$ curl -s -w '\n' localhost:8080/sessions
[{"course":"kotlin","minutes":45},{"course":"android-apps","minutes":30}]
```

`201 Created` is the status the handler chose, and the body is the session it received, echoed back as
JSON. The list now has two entries. Two requests with something wrong:

```
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"kotlin","minutes":0}'
HTTP/1.1 400 Bad Request
Content-Length: 24
Content-Type: text/plain; charset=UTF-8

minutes must be positive
ana@vm:~/kt/server$ curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{"course":"kotlin"}'
HTTP/1.1 400 Bad Request
Content-Length: 64
Content-Type: text/plain; charset=UTF-8

Failed to convert request body to class studyplan.server.Session
```

The first reached the handler: the JSON was a valid `Session`, and the `if` refused zero minutes, as
`WeekTotal` did in lesson 17. **The second never reached the handler at all.** A body with no `minutes`
cannot become a `Session`, which has no default for it, so `receive` threw, and Ktor answered `400` for
it. Nothing in `Server.kt` handles that case, and nothing has to: a non-null `Int` with no default is
a field the request must carry, and the type says so.

`sessions` is a `MutableStateFlow`, changed with `update`, for the reason lesson 17 gave. Ktor answers
requests on several threads at once, and two POSTs arriving together must both be counted. A real
server would keep the list in a database rather than in memory, where it is lost each time the server
stops.

Stop the server with **Ctrl+C** in its own terminal.
