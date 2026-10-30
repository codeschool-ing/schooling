---
title: Operations that are idempotent by nature
version: 1
---

**Some operations need no key, because doing them twice already has the effect of doing them once.**
Setting a value is one: "the session `s7` is 25 minutes of guitar on 23 October" said twice leaves
the same session. Adding is not: "add a session" said twice adds two. HTTP names the difference.
`PUT` and `DELETE` are defined as idempotent, `POST` is not, and the definitions are a promise the
server's code has to keep.

The planner can use that. **If the device chooses a session's id when the session is made**, as
lessons 7 and 8 did with `s7`, then creating it can be a `PUT` to `/sessions/s7` rather than a `POST`
to `/sessions`, and a retry is harmless by construction. Lesson 9's duplicate needed a server that
chose ids; a client that chooses them removes the case. Lesson 4 is why a device-made id must be a
random one rather than `s7`, which two phones would both choose.

Start the server as `node server.ts`, with no faults, and send the same `PUT` twice:

```
ana@dev:~/planner/idempotency$ curl -s -X PUT -H 'x-user: ana' -d '{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}' http://127.0.0.1:8010/sessions/s7
{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
ana@dev:~/planner/idempotency$ curl -s -X PUT -H 'x-user: ana' -d '{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}' http://127.0.0.1:8010/sessions/s7
{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}]
```

Two requests, one session. The server stored the body under the path, so the second `PUT` wrote the
same bytes over themselves.

## Where it stops

Natural idempotency covers a write that states the whole result. It does not cover:

- **a payment**, where the effect is outside the server, at the card processor, and the processor
  needs its own key;
- **an increment**, "add 25 minutes to the week", which is lesson 8's event that cannot be folded and
  lesson 15's counter;
- **a `PUT` that does more than store**: one that also sends an e-mail, or charges, or appends to a
  history, is idempotent in its stored row and not in its side effects.

So the two tools divide the work. **Rows the device names go by `PUT`, with the device's id;
operations that cause something go by `POST`, with an idempotency key.** The planner's sessions are
the first kind and buying a course is the second, and an app needs both.
