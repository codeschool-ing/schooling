---
title: async def and def in FastAPI, measured
version: 1
---

FastAPI accepts both kinds of route function, and runs them differently:

- an **`async def`** route runs **on the event loop**, so it must only wait with `await`;
- a plain **`def`** route runs **in a pool of threads**, 40 by default, so it may wait any way it
  likes, and occupies one thread while it does.

This module puts three versions of the same route side by side, plus one that computes instead of
waiting. Save it as `app/forecast.py`:

```schooling-example
{"language": "python", "file": "app/forecast.py", "parts": [{"code": "# app/forecast.py\nimport time\n\nimport httpx2\nfrom fastapi import APIRouter\n\nfrom .dependencies import EventDep\n\nrouter = APIRouter(prefix=\"/forecast\", tags=[\"forecast\"])\nPARTNER = \"http://127.0.0.1:8002/forecast/\"\n\n\n", "note": "An `APIRouter` is a group of routes that a module can define and an application can include, so `main.py` stays short."}, {"code": "@router.get(\"/async/{slug}\")\nasync def forecast_async(event: EventDep):\n    async with httpx2.AsyncClient() as client:\n        answer = await client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**The right way to wait**: an `async def` route that `await`s an asynchronous client. While it waits, the server runs other requests."}, {"code": "@router.get(\"/sync/{slug}\")\ndef forecast_sync(event: EventDep):\n    with httpx2.Client() as client:\n        answer = client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**Also correct**: a plain `def` route with a synchronous client. FastAPI runs it in a pool of threads, so it blocks a thread and not the server."}, {"code": "@router.get(\"/blocking/{slug}\")\nasync def forecast_blocking(event: EventDep):\n    with httpx2.Client() as client:\n        answer = client.get(PARTNER + event[\"slug\"])\n    return answer.json()\n\n\n", "note": "**The mistake**: `async def` with a synchronous call inside. It runs on the event loop itself, and while it waits, nothing else can run."}, {"code": "def crunch():\n    started = time.perf_counter()\n    total = sum(i * i for i in range(20_000_000))\n    return {\"total\": total, \"seconds\": round(time.perf_counter() - started, 2)}\n\n\n", "note": "Work for the processor, not for the network: about a second of arithmetic."}, {"code": "@router.get(\"/busy/async\")\nasync def busy_async():\n    return crunch()\n\n\n@router.get(\"/busy/sync\")\ndef busy_sync():\n    return crunch()\n"}]}
```

Add the router to `app/main.py`: the import beside the others, and `include_router` after the
`FastAPI(...)` call.

```
ana@vm:~/agenda-api$ grep -n 'forecast' app/main.py
7:from .forecast import router as forecast_router
16:app.include_router(forecast_router)
```

And a small load generator, saved as `load.py`, which sends `n` requests to one address **at the
same time** and reports how long all of them took:

```python
# load.py
import asyncio
import sys
import time

import httpx2


async def main(url, n):
    async with httpx2.AsyncClient(timeout=120) as client:
        started = time.perf_counter()
        answers = await asyncio.gather(*(client.get(url) for _ in range(n)))
        elapsed = time.perf_counter() - started
    codes = sorted({a.status_code for a in answers})
    print(f"{n} requests, status {codes}, {elapsed:.1f} s")


asyncio.run(main(sys.argv[1], int(sys.argv[2])))
```

Start agenda-api without `--reload` this time, `uv run uvicorn app.main:app --port 8001`, with the
partner still running on 8002. One request, to check:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/forecast/async/django-night; echo
{"venue":"django-night","rain":"unlikely"}
```

## Twenty at once, then a hundred

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 20
20 requests, status [200], 1.5 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 20
20 requests, status [200], 1.8 s
```

Twenty requests, each waiting a second for the partner, finished in **1.5 seconds with `async def`
and 1.8 with `def`**. Both overlapped the waits: the first on the loop, the second on twenty of its
forty threads. Now more requests than there are threads:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 100
100 requests, status [200], 3.3 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 100
100 requests, status [200], 5.2 s
```

**3.3 seconds against 5.2.** The `def` route had forty threads, so a hundred requests went through in
three waves of a second each, plus the cost of switching threads. The `async def` route has no such
ceiling: every waiting request is a coroutine, which costs a little memory and no thread. Most of
its remaining time is spent building a new client per request; a real application keeps one
`AsyncClient` open for the whole process.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Bars of total time measured with load.py. 20 requests took 1.5 seconds with async def and 1.8 with def. 100 requests took 3.3 seconds with async def and 5.2 with def. 10 requests to an async def route that makes a blocking call took 10.2 seconds.\"> <text x=\"260\" y=\"36\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requests, async def</text> <rect x=\"270\" y=\"20\" width=\"60.0\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></rect> <text x=\"338.0\" y=\"36\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.5 s</text> <text x=\"260\" y=\"70\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requests, def</text> <rect x=\"270\" y=\"54\" width=\"72.0\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"350.0\" y=\"70\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.8 s</text> <text x=\"260\" y=\"104\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100 requests, async def</text> <rect x=\"270\" y=\"88\" width=\"132.0\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></rect> <text x=\"410.0\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3.3 s</text> <text x=\"260\" y=\"138\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100 requests, def</text> <rect x=\"270\" y=\"122\" width=\"208.0\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"486.0\" y=\"138\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5.2 s</text> <text x=\"260\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10 requests, blocking call in async def</text> <rect x=\"270\" y=\"156\" width=\"408.0\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"686.0\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10.2 s</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Every request waits one second for the partner; the bar is the time for all of them.</text> </svg>", "caption": "Measured on the lab's four processors. The blocking case is ten requests, not twenty, because each one stops the whole server for its second."}
```
