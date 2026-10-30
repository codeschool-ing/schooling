---
title: Retry-After, and when to stop
version: 1
---

**When the server says how long to wait, the client waits that long, and the computed backoff steps
aside.** The header is `Retry-After`, defined by HTTP for 429 Too Many Requests and 503 Service
Unavailable, and it carries either a number of seconds or a date. The server knows how loaded it is;
the client's formula is a guess about it.

`retry.ts` reads the header after every answer worth retrying, and if it holds a positive number of
seconds, that replaces the wait the formula chose, still held under `CAP`. Start the server as
`node server.ts 429` and send:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 429, waiting 2000 ms as Retry-After asks
attempt 2: 201, saved as n1
```

The server's 429 said two seconds, and the client waited exactly 2000 milliseconds rather than the
few it would have chosen on its own. The second try succeeded.

Two details are worth carrying from here. **The cap still applies**: a server that answers
`Retry-After: 86400` by mistake should not keep a phone's outbox closed for a day, so the client
takes the smaller of the two. And the header's other form, an HTTP date, needs a clock, which is the
thing lesson 11 says a phone's is not; the seconds form is the one to prefer when you write the
server.

## Giving up, for now

A retry loop needs an end, because an operation that has failed five times in a row is telling the
client something about the network or the server, and a phone hammering at it is a phone emptying
its battery. Start the server as `node server.ts 503 503 503 503 503`, five failures in a row, and
send:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 503, waiting 2 ms
attempt 2: 503, waiting 24 ms
attempt 3: 503, waiting 781 ms
attempt 4: 503, waiting 1118 ms
attempt 5: 503
giving up for now; the operation stays in the outbox
```

Five tries, four waits, and a stop. **Giving up here is not deleting.** The operation is still in
the outbox, and the next drain, when the app is opened or the network comes back, starts it again
from attempt 1. A 503 is never moved to `dead`, because it is not the server's answer about the
operation; it is the server saying it cannot answer yet.

| | what stops it | what happens to the operation |
|---|---|---|
| a success | the server accepted it | removed from the outbox |
| a 4xx | the server refused it | moved to `dead`, for the person (lesson 8) |
| tries used up | the client stopped asking | left in the outbox, for the next drain |

The numbers in `retry.ts`, five tries from a 200 millisecond base, fit a drain the person is
waiting on. A drain running in the background can afford a larger base and fewer tries, since
nobody is watching it. Neither is a law: they are a policy, and writing them as named constants at
the top of the file is what makes them a policy somebody can change.
