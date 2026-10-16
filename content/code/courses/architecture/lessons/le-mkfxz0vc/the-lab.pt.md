---
title: O laboratório: um serviço de status de pedidos
version: 1
---

Um serviço pequeno guarda os eventos de pedidos do dia em memória e os oferece dos quatro jeitos. Duas
instâncias dele rodam, como uma loja atrás de um balanceador as rodaria, e um Redis espera pela última
seção. Ele fica em `~/lab/live`:

```sh
mkdir -p ~/lab/live && cd ~/lab/live
```

`live.py`, o serviço:

```schooling-example
{"language": "python", "file": "live.py", "parts": [{"code": "\"\"\"Order-status events, by polling, long polling, SSE and WebSocket.\"\"\"\nimport asyncio, os\nfrom aiohttp import web, WSMsgType\n\nNAME = os.environ[\"NAME\"]\nBACKPLANE = os.environ.get(\"BACKPLANE\")\nevents = []                     # (id, text)\nchanged = asyncio.Condition()   # notified whenever an event is added\nstats = {\"requests\": 0}\n\n\nasync def add(text):\n    async with changed:\n        events.append((len(events) + 1, text))\n        changed.notify_all()\n\n\ndef after(since):\n    return [e for e in events if e[0] > since]\n\n", "note": "O serviço de status de pedidos. Ele guarda os eventos do dia em memória, cada um com um número, e os oferece de quatro jeitos: polling comum, long polling, um fluxo de Server-Sent Events, e um WebSocket. `POST /publish` acrescenta um evento, como o armazém faria quando um pedido sai."}, {"code": "async def publish(request):\n    text = await request.text()\n    if BACKPLANE:\n        await request.app[\"redis\"].publish(\"orders\", text)\n    else:\n        await add(text)\n    return web.Response(text=f\"{NAME}: published\\n\")\n\n\nasync def follow_backplane(app):\n    import redis.asyncio as redis\n    app[\"redis\"] = redis.from_url(BACKPLANE)\n    pubsub = app[\"redis\"].pubsub()\n    await pubsub.subscribe(\"orders\")\n\n    async def listen():\n        async for message in pubsub.listen():\n            if message[\"type\"] == \"message\":\n                await add(message[\"data\"].decode())\n    app[\"listener\"] = asyncio.create_task(listen())\n\n", "note": "Sem backplane um evento só existe na instância que o recebeu. Com `BACKPLANE` definida, `publish` o manda para o Redis, e toda instância, esta inclusive, o recebe do Redis e o acrescenta."}, {"code": "async def poll(request):\n    stats[\"requests\"] += 1\n    since = int(request.query.get(\"since\", 0))\n    return web.json_response([text for _, text in after(since)])\n\n", "note": "Polling: responde na hora com o que for mais novo que `since`, o que muitas vezes é nada."}, {"code": "async def long_poll(request):\n    stats[\"requests\"] += 1\n    since = int(request.query.get(\"since\", 0))\n    async with changed:\n        try:\n            await asyncio.wait_for(changed.wait_for(lambda: after(since)), 25)\n        except asyncio.TimeoutError:\n            pass\n    return web.json_response([text for _, text in after(since)])\n\n", "note": "Long polling: se não houver nada novo, segura a requisição aberta até haver, ou por 25 segundos, e responde então."}, {"code": "async def sse(request):\n    stats[\"requests\"] += 1\n    since = int(request.headers.get(\"Last-Event-ID\", request.query.get(\"since\", 0)))\n    resp = web.StreamResponse(headers={\"Content-Type\": \"text/event-stream\", \"Cache-Control\": \"no-cache\"})\n    await resp.prepare(request)\n    while True:\n        for id_, text in after(since):\n            await resp.write(f\"id: {id_}\\ndata: {NAME}: {text}\\n\\n\".encode())\n            since = id_\n        async with changed:\n            await changed.wait_for(lambda: after(since))\n\n", "note": "Server-Sent Events: uma resposta que nunca termina, uma linha `id:` e uma linha `data:` por evento. Um cliente que reconecta manda `Last-Event-ID`, e o fluxo começa depois dele, então nada se perde."}, {"code": "async def websocket(request):\n    stats[\"requests\"] += 1\n    ws = web.WebSocketResponse(heartbeat=20)\n    await ws.prepare(request)\n    since = len(events)\n\n    async def push():\n        nonlocal since\n        while True:\n            async with changed:\n                await changed.wait_for(lambda: after(since))\n            for id_, text in after(since):\n                await ws.send_str(f\"{NAME}: {text}\")\n                since = id_\n    pusher = asyncio.create_task(push())\n    async for msg in ws:\n        if msg.type == WSMsgType.TEXT:\n            await ws.send_str(f\"{NAME}: received {msg.data!r}\")\n    pusher.cancel()\n    return ws\n\n\nasync def count(request):\n    return web.Response(text=f\"{NAME}: {stats['requests']} requests served\\n\")\n\n\napp = web.Application()\napp.router.add_routes([web.post(\"/publish\", publish), web.get(\"/poll\", poll),\n                       web.get(\"/long-poll\", long_poll), web.get(\"/events\", sse),\n                       web.get(\"/ws\", websocket), web.get(\"/count\", count)])\nif BACKPLANE:\n    app.on_startup.append(follow_backplane)\nweb.run_app(app, port=8000, print=None)", "note": "WebSocket: depois de um upgrade de HTTP, uma conexão em que os dois lados podem mandar. O servidor empurra todo evento novo; o que o cliente mandar é respondido, o que um chat ou um leilão ao vivo precisariam e uma página de status de pedido não precisa."}]}
```

`watch.py`, um cliente WebSocket:

```schooling-example
{"language": "python", "file": "watch.py", "parts": [{"code": "\"\"\"Watch a WebSocket for a few seconds.\"\"\"\nimport asyncio, sys\nimport aiohttp\n\n\nasync def main(url, seconds):\n    async with aiohttp.ClientSession() as session:\n        async with session.ws_connect(url) as ws:\n            await ws.send_str(\"hello\")\n            try:\n                async with asyncio.timeout(seconds):\n                    async for msg in ws:\n                        print(msg.data, flush=True)\n            except TimeoutError:\n                pass\n\n\nasyncio.run(main(sys.argv[1], float(sys.argv[2])))", "note": "Um cliente WebSocket, fazendo o papel da página do pedido num navegador: ele conecta, diz olá, e imprime tudo o que o servidor manda por alguns segundos."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir aiohttp==3.12.15 redis==5.2.1\nWORKDIR /app\nCOPY *.py .", "note": "Python com aiohttp, que serve HTTP comum, fluxos e WebSockets a partir de um programa só, e o cliente Redis para o backplane."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-live: &live\n  build: .\n  command: python live.py\n  depends_on:\n    - redis\nservices:\n  live-a:\n    <<: *live\n    environment: {NAME: a, BACKPLANE: \"${BACKPLANE:-}\"}\n    ports: [\"8001:8000\"]\n  live-b:\n    <<: *live\n    environment: {NAME: b, BACKPLANE: \"${BACKPLANE:-}\"}\n    ports: [\"8002:8000\"]\n  redis:\n    image: redis:7.4-alpine\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"watch.py\"]", "note": "Duas instâncias do serviço, como uma loja atrás de um balanceador rodaria, nas portas 8001 e 8002 da máquina; um Redis para o backplane; e o cliente WebSocket. `BACKPLANE` vem do shell e fica vazia se não for definida."}]}
```

Suba tudo, e guarde numa variável o comando do cliente WebSocket:

```sh
docker compose up -d --build
W="docker compose --progress quiet run --rm tools"
```

A instância `a` responde na porta 8001 e a instância `b` na 8002, e o `curl` basta para toda técnica menos
o WebSocket.
