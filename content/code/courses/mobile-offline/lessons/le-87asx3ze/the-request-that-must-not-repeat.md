---
title: The request that must not repeat
version: 1
---

**A retry assumes the failed request did nothing. When the answer is lost after the server has done
the work, that assumption is wrong, and the retry does the work a second time.** Everything earlier
in this lesson is safe for requests where doing it twice is the same as doing it once. Creating a
session is not one of them.

The case is common rather than exotic. A phone sends a `POST`, the server saves the session and
writes its answer, and the answer is lost: the phone went into a tunnel, switched from Wi-Fi to the
mobile network, or hit its timeout a moment before the reply arrived. From the phone, all three look
exactly like a request that never arrived.

## Watching it happen

The server's `drop` does this on purpose: it saves the session and closes the connection before
answering. Start it as `node server.ts drop`, send, and ask the server what it has:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: no answer, waiting 2 ms
attempt 2: 201, saved as n2
ana@dev:~/planner/retry$ curl -s http://127.0.0.1:8009/sessions
[{"course":"guitar","date":"2026-10-23","minutes":25,"id":"n1"},{"course":"guitar","date":"2026-10-23","minutes":25,"id":"n2"}]
```

**One tap, two sessions.** The first try was saved as `n1` and its answer never left the server, so
the client saw `no answer` and did what the table at the top of this lesson told it to. The second
try was saved as `n2`, and that answer arrived. The person's week now holds 50 minutes of guitar on
23 October where they planned 25, and nothing on either side recorded an error.

The server's terminal saw two requests that look alike:

```
ana@dev:~/planner/retry$ node server.ts drop
listening on 8009
POST /sessions drop
POST /sessions ok
```

## Why the client cannot fix it alone

The client could stop retrying `POST` altogether. Then a lost answer leaves the session on the
phone and the server uncertain, which is lesson 7's `pending` for ever. It could ask the server
first, "did you save a guitar session on the 23rd?", and the server cannot tell this session from a
second one the person really meant to add.

What both sides are missing is a way to say *this* operation, as opposed to *an* operation with the
same body. **That is an identity for the request, chosen by the client before the first try and
sent with every retry**, and lesson 10 builds it: the idempotency key, and the payment that taught
the industry to use one.
