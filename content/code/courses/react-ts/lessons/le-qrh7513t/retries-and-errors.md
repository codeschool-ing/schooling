---
title: When the server does not answer
version: 1
---

**A query that fails is retried before it is reported.** Most failures are momentary, a dropped
connection or a server restarting, and a second try a moment later succeeds. Stop the API server and
load the page, giving it nine seconds:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'wait 9000' | grep -E 'api|alert|error'
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
- alert: The planner could not be loaded.
```

Four requests for `/api/planner`, each answered **502 Bad Gateway** by Vite's proxy, which had nowhere
to forward them. The library tried once, then retried three times, waiting longer before each one,
about one, two and four seconds; only after the fourth failure did `isError` become true and the
planner draw its alert. The console has the browser's line for each failure, the same messages a user
would see in their own developer tools.

Three things in that transcript are decisions you can change, per query or for the whole client:

| default | what it means | when to change it |
|---|---|---|
| `retry: 3` | three retries after the first failure | `0` for a request that must not be repeated, or in tests, so failures are fast |
| a delay that doubles, up to 30 seconds | the server gets time to recover | rarely |
| errors from `queryFn` are reported once retries run out | `isError`, and the error in `error` | never: a failure must reach the screen |

**Mutations are not retried by default**, and for a good reason: a `POST` that reached the server and
lost its answer on the way back would add the session twice if repeated. A query only reads, so
reading twice is harmless.

The alert is what lesson 5 drew, now driven by the library. It tells the user something failed and
offers nothing to do about it, and a reload is not something a user should have to think of. Lesson
12 gives the failure a screen with a way out, and uses the library's `refetch` to give it one.
