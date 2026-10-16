---
title: The lab: the stock and two copies of it
version: 1
---

The lab is the arrangement lesson 5 described. The **stock service** owns the number of units of each
product. The **shop** draws product pages from its own copy of those numbers, kept up to date from the
events the stock service publishes. There are **two copies of the shop**, `a` and `b`, the way a real
shop runs more than one copy behind a load balancer, and `b` is slower to handle an event, the way one
copy often is busier than another.

Everything is in memory, so a restart starts over. Three small Python programs share one image. It
lives in `~/lab/eventual`:

```sh
mkdir -p ~/lab/eventual && cd ~/lab/eventual
```

`bus.py`, the exchange the services share:

```schooling-example
{"language": "python", "file": "bus.py", "parts": [{"code": "\"\"\"The exchange the lab's services share, and how to publish to it.\"\"\"\nimport json, os\nimport pika\n\n\ndef connect():\n    conn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\n    ch = conn.channel()\n    ch.exchange_declare(\"quitanda\", exchange_type=\"fanout\", durable=True)\n    return conn, ch\n\n", "note": "The one exchange every service in the lab publishes to. It is a fanout, so each shop gets its own copy of every event, stock and baskets alike."}, {"code": "def publish(event):\n    conn, ch = connect()\n    ch.basic_publish(\"quitanda\", \"\", json.dumps(event))\n    conn.close()", "note": "A connection per event is slow and simple. Each HTTP request runs in a thread of its own, and a pika connection must not be shared between threads."}]}
```

`stock.py`, the stock service:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"The stock service: the owner of how many units of each product there are.\"\"\"\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom bus import publish\n\nstock = {}    # sku -> (units, version)\nsent = {}     # (sku, version) -> the event, so it can be sent again\nlock = threading.Lock()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"text/plain\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        sku = self.path.split(\"/\")[-1]\n        with lock:\n            if sku not in stock:\n                return self.reply(404, f\"{sku}: no such product\")\n            units, version = stock[sku]\n        self.reply(200, f\"{sku}: {units} in stock, version {version}\")\n", "note": "The stock service, the one place that decides how many units there are. It keeps them in memory, which is enough for a lab, and gives every change to a product a version: 1, 2, 3, and so on."}, {"code": "    def do_PUT(self):\n        sku = self.path.split(\"/\")[-1]\n        units = int(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        with lock:\n            version = stock.get(sku, (0, 0))[1] + 1\n            event = {\"kind\": \"stock\", \"sku\": sku, \"units\": units, \"version\": version}\n            try:\n                publish(event)\n            except Exception as e:\n                return self.reply(503, f\"not changed, the broker refused the event: {e!r}\")\n            stock[sku] = (units, version)\n            sent[(sku, version)] = event\n        self.reply(200, f\"{sku}: {units} in stock, version {version}\")\n", "note": "`PUT /stock/coffee` with a number as the body sets the units. The event is published before the change is kept, so a broker that is down leaves nothing changed and the caller sees a 503. Holding the lock across both keeps the events in version order."}, {"code": "    def do_POST(self):\n        _, _, sku, version = self.path.split(\"/\")\n        event = sent[(sku, int(version))]\n        publish(event)\n        self.reply(200, f\"sent again: {sku} = {event['units']}, version {version}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`POST /resend/coffee/3` publishes version 3 of coffee again, late. That is what a redelivery does after a consumer crashes, and what a second consumer on the same queue does when it is slower than the first."}]}
```

`shop.py`, the shop:

```schooling-example
{"language": "python", "file": "shop.py", "parts": [{"code": "\"\"\"One copy of the shop: a product page drawn from its own copy of the stock, and baskets.\"\"\"\nimport json, os, threading, time, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nimport pika\nfrom bus import connect, publish\n\nNAME = os.environ[\"NAME\"]\nLAG = float(os.environ[\"LAG\"])\nCHECK_VERSION = os.environ[\"CHECK_VERSION\"] == \"1\"\nMERGE = os.environ[\"MERGE\"]\ncopy = {}      # sku -> (units, version)\nbaskets = {}   # customer -> (items, time of the last change)\nlock = threading.Lock()\n\n", "note": "The shop. It never asks the stock service how many units there are when it draws a product page: it keeps its own copy, fed by the stock service's events. `LAG` is how long it takes to handle each event, which stands in for a busy consumer, and the two switches decide how it handles an event that is old or a basket that changed in two places."}, {"code": "def apply_stock(e):\n    held = copy.get(e[\"sku\"], (None, 0))[1]\n    if CHECK_VERSION and e[\"version\"] <= held:\n        print(f\"shop-{NAME}: ignored {e['sku']} version {e['version']}, already at {held}\")\n        return\n    copy[e[\"sku\"]] = (e[\"units\"], e[\"version\"])\n    print(f\"shop-{NAME}: {e['sku']} = {e['units']}, version {e['version']}\")\n\n", "note": "With `CHECK_VERSION=0` the copy takes whatever arrives last. With `1` it refuses an event older than the one it already holds."}, {"code": "def apply_basket(e):\n    if e[\"from\"] == NAME:\n        return\n    mine, at = baskets.get(e[\"customer\"], (set(), 0))\n    if MERGE == \"union\":\n        baskets[e[\"customer\"]] = (mine | set(e[\"items\"]), max(at, e[\"at\"]))\n    elif e[\"at\"] > at:\n        baskets[e[\"customer\"]] = (set(e[\"items\"]), e[\"at\"])\n    print(f\"shop-{NAME}: basket {e['customer']} = {', '.join(sorted(baskets[e['customer']][0]))}\")\n\n", "note": "A basket can change in either shop, and each tells the other by publishing the whole basket. `MERGE=lww` keeps the one changed last; `MERGE=union` keeps every item either side has."}, {"code": "def follow():\n    while True:\n        try:\n            conn, ch = connect()\n            break\n        except pika.exceptions.AMQPConnectionError:\n            time.sleep(1)\n    ch.queue_declare(f\"shop-{NAME}\", durable=True)\n    ch.queue_bind(f\"shop-{NAME}\", \"quitanda\")\n    for method, props, body in ch.consume(f\"shop-{NAME}\"):\n        time.sleep(LAG)\n        event = json.loads(body)\n        with lock:\n            apply_stock(event) if event[\"kind\"] == \"stock\" else apply_basket(event)\n        ch.basic_ack(method.delivery_tag)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"text/plain\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n", "note": "The shop can start before the broker is ready, so it tries again every second until it connects. Its queue is durable: events published while the shop is down wait for it."}, {"code": "    def do_GET(self):\n        kind, key = self.path.split(\"?\")[0].split(\"/\")[1:3]\n        after = int(self.path.split(\"after=\")[1]) if \"after=\" in self.path else 0\n        with lock:\n            if kind == \"basket\":\n                items = baskets.get(key, (set(), 0))[0]\n                return self.reply(200, f\"shop-{NAME}: basket {key} = {', '.join(sorted(items)) or 'empty'}\")\n            units, version = copy.get(key, (None, 0))\n        if version < after:\n            with urllib.request.urlopen(f\"http://stock:8000/stock/{key}\") as r:\n                return self.reply(200, f\"shop-{NAME}: {r.read().decode().strip()} (copy behind, asked the stock service)\")\n        if units is None:\n            return self.reply(404, f\"shop-{NAME}: {key}: no copy yet\")\n        self.reply(200, f\"shop-{NAME}: {key}: {units} left, version {version}\")\n", "note": "`GET /product/coffee` answers from the copy. `?after=N` says \"I have already seen version N\": if the copy is older than that, the page asks the stock service instead, and says so."}, {"code": "    def change_basket(self, add):\n        _, _, customer, item = self.path.split(\"/\")\n        with lock:\n            items = set(baskets.get(customer, (set(), 0))[0])\n            items.add(item) if add else items.discard(item)\n            baskets[customer] = (items, time.time())\n            event = {\"kind\": \"basket\", \"customer\": customer, \"items\": sorted(items),\n                     \"at\": baskets[customer][1], \"from\": NAME}\n        publish(event)\n        self.reply(200, f\"shop-{NAME}: basket {customer} = {', '.join(sorted(items)) or 'empty'}\")\n\n    def do_PUT(self):\n        self.change_basket(add=True)\n\n    def do_DELETE(self):\n        self.change_basket(add=False)\n\n    def log_message(self, *args):\n        pass\n\n\nthreading.Thread(target=follow, daemon=True).start()\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`PUT /basket/ana/tea` adds tea to ana's basket in this shop and `DELETE` takes it out. Either way the shop publishes the whole basket, stamped with this machine's clock."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "The image all three services run: Python and pika, as in lessons 6 and 7."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-app: &app\n  build: .\n  depends_on:\n    - rabbitmq\nservices:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  stock:\n    <<: *app\n    command: python stock.py\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    ports:\n      - \"8001:8000\"\n  shop-a:\n    <<: *app\n    command: python shop.py\n    environment: &shop\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n      PYTHONUNBUFFERED: \"1\"\n      NAME: a\n      LAG: \"0.2\"\n      CHECK_VERSION: ${CHECK_VERSION:-0}\n      MERGE: ${MERGE:-lww}\n    ports:\n      - \"8002:8000\"\n  shop-b:\n    <<: *app\n    command: python shop.py\n    environment:\n      <<: *shop\n      NAME: b\n      LAG: \"2\"\n    ports:\n      - \"8003:8000\"", "note": "The broker, the stock service on port 8001, and two copies of the shop on 8002 and 8003. Shop a handles an event in a fifth of a second and shop b takes two seconds, as if it were busier. The two switches come from the shell and default to the naive behaviour: `CHECK_VERSION=1 docker compose up -d` restarts the shops with the check on."}]}
```

Build and start everything, and give the broker about fifteen seconds before the first request:

```
ana@vm:~/lab/eventual$ docker compose up -d --build --quiet-build
 Image eventual-stock Building 
 Image eventual-shop-a Building 
 Image eventual-shop-b Building 
 Image eventual-shop-a Built 
 Image eventual-shop-b Built 
 Image eventual-stock Built 
 Network eventual_default Creating 
 Network eventual_default Creating 
 Network eventual_default Created 
 Network eventual_default Created 
 Container eventual-rabbitmq-1 Creating 
 Container eventual-rabbitmq-1 Created 
 Container eventual-shop-b-1 Creating 
 Container eventual-stock-1 Creating 
 Container eventual-shop-a-1 Creating 
 Container eventual-stock-1 Created 
 Container eventual-shop-a-1 Created 
 Container eventual-shop-b-1 Created 
 Container eventual-rabbitmq-1 Starting 
 Container eventual-rabbitmq-1 Started 
 Container eventual-shop-b-1 Starting 
 Container eventual-stock-1 Starting 
 Container eventual-shop-a-1 Starting 
 Container eventual-shop-b-1 Started 
 Container eventual-stock-1 Started 
 Container eventual-shop-a-1 Started 
```

The stock service answers on port 8001, shop `a` on 8002 and shop `b` on 8003, and every answer is one
line of plain text, so `curl` is enough. Set the coffee to 12 and ask both shops straight away, then
ask shop `b` again three seconds later:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 12; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
coffee: 12 in stock, version 1
shop-a: coffee: no copy yet
shop-b: coffee: no copy yet
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8003/product/coffee
shop-b: coffee: 12 left, version 1
```

The stock service said 12 at once, because it is the owner. Neither shop knew yet: the event was on its
way. Three seconds later shop `b` had it. **Nothing failed and nothing was misconfigured**, and for a
moment the two answers about one bag of coffee disagreed. That moment is what the rest of the lesson
is about.

The logs show each shop applying the event, which is how you will see what a copy did with each one:

```
ana@vm:~/lab/eventual$ docker compose logs shop-a shop-b
shop-b-1  | shop-b: coffee = 12, version 1
shop-a-1  | shop-a: coffee = 12, version 1
```
