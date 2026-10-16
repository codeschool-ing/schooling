---
title: The lab: an order-status service
version: 1
---

One small service holds the day's order events in memory and offers them all four ways. Two instances of
it run, as a shop behind a load balancer would run them, and a Redis waits for the last section. It
lives in `~/lab/live`:

```sh
mkdir -p ~/lab/live && cd ~/lab/live
```

`live.py`, the service:

```schooling-example
{"language": "python", "file": "live.py", "parts": [{"code": "\"\"\"Order-status events, by polling, long polling, SSE and WebSocket.\"\"\"\nimport asyncio, os\nfrom aiohttp import web, WSMsgType\n\nNAME = os.environ[\"NAME\"]\nBACKPLANE = os.environ.get(\"BACKPLANE\")\nevents = []                     # (id, text)\nchanged = asyncio.Condition()   # notified whenever an event is added\nstats = {\"requests\": 0}\n\n\nasync def add(text):\n    async with changed:\n        events.append((len(events) + 1, text))\n        changed.notify_all()\n\n\ndef after(since):\n    return [e for e in events if e[0] > since]\n\n", "note": "The order-status service. It keeps the events of the day in memory, each with a number, and offers them four ways: plain polling, long polling, a Server-Sent Events stream, and a WebSocket. `POST /publish` adds an event, the way the warehouse would when an order ships."}, {"code": "async def publish(request):\n    text = await request.text()\n    if BACKPLANE:\n        await request.app[\"redis\"].publish(\"orders\", text)\n    else:\n        await add(text)\n    return web.Response(text=f\"{NAME}: published\\n\")\n\n\nasync def follow_backplane(app):\n    import redis.asyncio as redis\n    app[\"redis\"] = redis.from_url(BACKPLANE)\n    pubsub = app[\"redis\"].pubsub()\n    await pubsub.subscribe(\"orders\")\n\n    async def listen():\n        async for message in pubsub.listen():\n            if message[\"type\"] == \"message\":\n                await add(message[\"data\"].decode())\n    app[\"listener\"] = asyncio.create_task(listen())\n\n", "note": "Without a backplane an event exists only on the instance that received it. With `BACKPLANE` set, `publish` sends it to Redis instead, and every instance, this one included, receives it from Redis and adds it."}, {"code": "async def poll(request):\n    stats[\"requests\"] += 1\n    since = int(request.query.get(\"since\", 0))\n    return web.json_response([text for _, text in after(since)])\n\n", "note": "Polling: answer at once with whatever is newer than `since`, which is often nothing."}, {"code": "async def long_poll(request):\n    stats[\"requests\"] += 1\n    since = int(request.query.get(\"since\", 0))\n    async with changed:\n        try:\n            await asyncio.wait_for(changed.wait_for(lambda: after(since)), 25)\n        except asyncio.TimeoutError:\n            pass\n    return web.json_response([text for _, text in after(since)])\n\n", "note": "Long polling: if there is nothing new, hold the request open until there is, or for 25 seconds, and answer then."}, {"code": "async def sse(request):\n    stats[\"requests\"] += 1\n    since = int(request.headers.get(\"Last-Event-ID\", request.query.get(\"since\", 0)))\n    resp = web.StreamResponse(headers={\"Content-Type\": \"text/event-stream\", \"Cache-Control\": \"no-cache\"})\n    await resp.prepare(request)\n    while True:\n        for id_, text in after(since):\n            await resp.write(f\"id: {id_}\\ndata: {NAME}: {text}\\n\\n\".encode())\n            since = id_\n        async with changed:\n            await changed.wait_for(lambda: after(since))\n\n", "note": "Server-Sent Events: one response that never ends, a line `id:` and a line `data:` per event. A client that reconnects sends `Last-Event-ID`, and the stream starts after it, so nothing is missed."}, {"code": "async def websocket(request):\n    stats[\"requests\"] += 1\n    ws = web.WebSocketResponse(heartbeat=20)\n    await ws.prepare(request)\n    since = len(events)\n\n    async def push():\n        nonlocal since\n        while True:\n            async with changed:\n                await changed.wait_for(lambda: after(since))\n            for id_, text in after(since):\n                await ws.send_str(f\"{NAME}: {text}\")\n                since = id_\n    pusher = asyncio.create_task(push())\n    async for msg in ws:\n        if msg.type == WSMsgType.TEXT:\n            await ws.send_str(f\"{NAME}: received {msg.data!r}\")\n    pusher.cancel()\n    return ws\n\n\nasync def count(request):\n    return web.Response(text=f\"{NAME}: {stats['requests']} requests served\\n\")\n\n\napp = web.Application()\napp.router.add_routes([web.post(\"/publish\", publish), web.get(\"/poll\", poll),\n                       web.get(\"/long-poll\", long_poll), web.get(\"/events\", sse),\n                       web.get(\"/ws\", websocket), web.get(\"/count\", count)])\nif BACKPLANE:\n    app.on_startup.append(follow_backplane)\nweb.run_app(app, port=8000, print=None)", "note": "WebSocket: after an HTTP upgrade, a connection both sides can send on. The server pushes every new event; anything the client sends is answered, which a chat or a live auction would need and an order-status page does not."}]}
```

`watch.py`, a WebSocket client:

```schooling-example
{"language": "python", "file": "watch.py", "parts": [{"code": "\"\"\"Watch a WebSocket for a few seconds.\"\"\"\nimport asyncio, sys\nimport aiohttp\n\n\nasync def main(url, seconds):\n    async with aiohttp.ClientSession() as session:\n        async with session.ws_connect(url) as ws:\n            await ws.send_str(\"hello\")\n            try:\n                async with asyncio.timeout(seconds):\n                    async for msg in ws:\n                        print(msg.data, flush=True)\n            except TimeoutError:\n                pass\n\n\nasyncio.run(main(sys.argv[1], float(sys.argv[2])))", "note": "A WebSocket client, standing in for the order page in a browser: it connects, says hello, and prints everything the server sends for a number of seconds."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir aiohttp==3.12.15 redis==5.2.1\nWORKDIR /app\nCOPY *.py .", "note": "Python with aiohttp, which serves plain HTTP, streams and WebSockets from one program, and the Redis client for the backplane."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-live: &live\n  build: .\n  command: python live.py\n  depends_on:\n    - redis\nservices:\n  live-a:\n    <<: *live\n    environment: {NAME: a, BACKPLANE: \"${BACKPLANE:-}\"}\n    ports: [\"8001:8000\"]\n  live-b:\n    <<: *live\n    environment: {NAME: b, BACKPLANE: \"${BACKPLANE:-}\"}\n    ports: [\"8002:8000\"]\n  redis:\n    image: redis:7.4-alpine\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"watch.py\"]", "note": "Two instances of the service, as a shop behind a load balancer would run, on ports 8001 and 8002 of the machine; a Redis for the backplane; and the WebSocket client. `BACKPLANE` comes from the shell and is empty unless set."}]}
```

Start it, and keep the command for the WebSocket client in a variable:

```sh
docker compose up -d --build
W="docker compose --progress quiet run --rm tools"
```

Instance `a` answers on port 8001 and instance `b` on 8002, and `curl` is enough for every technique but
the WebSocket.
