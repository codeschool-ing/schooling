---
title: Most of a request is waiting
version: 1
---

The common belief is that `async` makes Python faster. **It does not make any piece of code run
faster.** What it does is let one process do something useful while a piece of code is waiting, and
a web request spends most of its life waiting: for the database, for another service, for a client
on a slow connection to finish sending.

To see it, agenda needs something slow to wait for. Real applications call partners, a payment
gateway, a map, a weather service, and those take hundreds of milliseconds each. This lesson stands
one in with a tiny FastAPI application that answers after exactly one second. Save it as `slow.py` in
`~/agenda-api`:

```python
# slow.py
import asyncio

from fastapi import FastAPI

app = FastAPI(title="a slow partner")


@app.get("/forecast/{venue}")
async def forecast(venue: str):
    await asyncio.sleep(1)
    return {"venue": venue, "rain": "unlikely"}
```

Run it in a terminal of its own, on port 8002, with `uv run uvicorn slow:app --port 8002`, and ask it
once:

```
ana@vm:~/agenda-api$ curl -s -w "  %{time_total} s\n" http://127.0.0.1:8002/forecast/community-centre
{"venue":"community-centre","rain":"unlikely"}  1.003181 s
```

**One second**, the time it spends in `asyncio.sleep`. Now three questions, one for each of three
places, asked two ways. Save this as `three.py`:

```schooling-example
{"language": "python", "file": "three.py", "parts": [{"code": "# three.py\nimport asyncio\nimport time\n\nimport httpx2\n\nURL = \"http://127.0.0.1:8002/forecast/\"\nVENUES = [\"community-centre\", \"public-library\", \"town-hall\"]\n\n\n", "note": "One partner, three places to ask about, and `httpx2` for both styles of client."}, {"code": "def one_after_another():\n    with httpx2.Client() as client:\n        return [client.get(URL + v).json()[\"venue\"] for v in VENUES]\n\n\n", "note": "**The ordinary way**: each `get` returns when its answer has arrived, so the three seconds add up."}, {"code": "async def all_at_once():\n    async with httpx2.AsyncClient() as client:\n        answers = await asyncio.gather(*(client.get(URL + v) for v in VENUES))\n    return [a.json()[\"venue\"] for a in answers]\n\n\n", "note": "**The concurrent way**: each `client.get(...)` makes a coroutine, and `gather` runs them together and waits for all three."}, {"code": "started = time.perf_counter()\nprint(one_after_another(), f\"{time.perf_counter() - started:.1f} s\")\n\nstarted = time.perf_counter()\nprint(asyncio.run(all_at_once()), f\"{time.perf_counter() - started:.1f} s\")\n", "note": "Timing both, the second through `asyncio.run`, which starts an event loop, runs one coroutine and closes the loop."}]}
```

```
ana@vm:~/agenda-api$ uv run python three.py
['community-centre', 'public-library', 'town-hall'] 3.1 s
['community-centre', 'public-library', 'town-hall'] 1.0 s
```

**3.1 seconds one after the other, 1.0 at once.** The partner took the same second to answer each
question both times. What changed is that the second version did not wait for the first answer before
asking the second question, so the three waits overlapped.

## Two kinds of slow

| the time goes to | example | does `async` help? |
|---|---|---|
| **waiting** for something outside the process | a query, an HTTP call, a file on a network disk | **yes**: other work runs during the wait |
| **computing** in the process | resizing an image, a large loop, parsing a big document | **no**: the processor is busy either way |

The rest of the lesson measures both columns.
