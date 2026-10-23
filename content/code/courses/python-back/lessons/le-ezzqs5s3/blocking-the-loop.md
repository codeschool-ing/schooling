---
title: Blocking the loop, the mistake that looks correct
version: 1
---

The third route in `app/forecast.py` is an `async def` that makes a synchronous HTTP call. It works,
and one request at a time it is exactly as fast as the others:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 1
1 requests, status [200], 1.0 s
```

Ten at once:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 10
10 requests, status [200], 10.2 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 10
10 requests, status [200], 1.2 s
```

**10.2 seconds, against 1.2 for the correct `async def`.** The synchronous `client.get` waits for its
answer without an `await`, so the coroutine never hands the loop back. For that second, **nothing
else in the process runs**: not the other nine requests, not a health check, not the request that
only wanted to read a list of events. They went through one after another, one second each.

This is the worst of both worlds, and it is easy to write: a library that does network calls without
`async` is the default in Python, and nothing warns when you call it from an `async def`. The rules
that avoid it:

- **In an `async def`, everything that waits must be awaited.** HTTP through `httpx2.AsyncClient`, a
  database through an async driver, files through a library that offers async reads, sleeping through
  `asyncio.sleep`.
- **If a library has no async version, write `def`.** FastAPI then runs the route in a thread, and a
  blocking call blocks only that thread, as the `sync` route showed.
- **When one blocking call is unavoidable inside an `async def`**,
  `await asyncio.to_thread(function, *args)` runs it in a thread and awaits the result.

## Computing is not waiting

The last two routes do about a second of arithmetic, with no waiting at all:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/forecast/busy/async; echo
{"total":2666666466666670000000,"seconds":0.85}
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/busy/async 4
4 requests, status [200], 3.2 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/busy/sync 4
4 requests, status [200], 3.4 s
```

**Four requests took about four times as long as one, whichever kind of route ran them**: 3.2 seconds
with `async def` and 3.4 with `def`. On the loop, the arithmetic held it, exactly like the blocking
call. In threads it did not help either, because CPython runs Python code in one thread at a time,
the global interpreter lock, so four threads of arithmetic take turns. Work that computes needs more
**processes**, which is what lesson 16's workers are, or a queue and a worker of its own, which is
lesson 13.
