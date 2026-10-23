---
title: Variables that Node itself reads
version: 1
---

**A few environment variables are read by Node, not by your code**, and they change how the runtime
behaves without a line of the program changing. Lesson 2 used one, `UV_THREADPOOL_SIZE`. These are
the others a server meets:

| variable | what it does |
|---|---|
| `NODE_OPTIONS` | command-line options for every `node` started with it, such as a memory limit |
| `TZ` | the time zone `Date` uses to show local times |
| `NODE_EXTRA_CA_CERTS` | a file of extra certificates to trust, for a company network that inspects TLS |
| `UV_THREADPOOL_SIZE` | the size of libuv's pool, lesson 2 |

Two of them, run:

```
ana@dev:~/server/links$ node -p 'new Date("2026-10-01T12:00:00Z").toString()'
Thu Oct 01 2026 09:00:00 GMT-0300 (Brasilia Standard Time)
ana@dev:~/server/links$ TZ=Asia/Tokyo node -p 'new Date("2026-10-01T12:00:00Z").toString()'
Thu Oct 01 2026 21:00:00 GMT+0900 (Japan Standard Time)
ana@dev:~/server/links$ node -p 'new Date("2026-10-01T12:00:00Z").toISOString()'
2026-10-01T12:00:00.000Z
ana@dev:~/server/links$ NODE_OPTIONS=--max-old-space-size=40 node -e 'const a = []; for (;;) a.push(new Array(1e6).fill(0))' 2>&1 | grep -E 'FATAL|heap limit'
FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
```

**`TZ` changed what `toString` printed and not the moment itself**: the same instant, in São Paulo and
in Tokyo. That is why every date the links service stores is `toISOString()`, which is always UTC and
always the same text whatever the server's zone; a local time is for showing to a person, never for
storing.

**`NODE_OPTIONS` reached a program that never mentions it**: `--max-old-space-size=40` capped V8's
heap at 40 megabytes, and an allocation of more crashed with the out-of-memory error a too-small
server meets. It is how a platform gives Node a limit, and how a limit set long ago and forgotten
crashes a service that grew.

`NODE_EXTRA_CA_CERTS` is the honest answer to lesson 1's certificate errors on a company network:
the network's certificate in a file, named here, and Node trusts it alongside the usual ones. **It was
not run for this course**, which has no such network; the alternative people reach for,
`NODE_TLS_REJECT_UNAUTHORIZED=0`, turns checking off for every connection the process makes and should
never be set.
