---
title: The lab: stock, payments and shipping
version: 1
---

Three services, each keeping its state in memory and answering JSON over HTTP, plus a broker for the
second half of the lesson. The coffee starts with **three bags on the shelf**. A card ending in `0002`
is declined, and shipping delivers only to Recife, Olinda and Jaboatão. It lives in `~/lab/saga`:

```sh
mkdir -p ~/lab/saga && cd ~/lab/saga
```

`common.py`, what the services share:

```schooling-example
{"language": "python", "file": "common.py", "parts": [{"code": "\"\"\"HTTP and events for the lab's services.\"\"\"\nimport json, os, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nimport pika\n\nNAME = os.environ[\"NAME\"]\nlock = threading.Lock()\n\n\ndef connect():\n    params = pika.URLParameters(os.environ[\"RABBIT_URL\"])\n    while True:\n        try:\n            conn = pika.BlockingConnection(params)\n            break\n        except pika.exceptions.AMQPConnectionError:\n            time.sleep(1)\n    ch = conn.channel()\n    ch.exchange_declare(\"checkout\", exchange_type=\"fanout\", durable=True)\n    return conn, ch\n\n", "note": "What the three services share: a small JSON-over-HTTP server for the orchestrated saga, and the exchange `checkout` for the choreographed one. Each service listens on its own queue, bound to the exchange, so every service sees every event and picks out the ones it cares about."}, {"code": "def publish(type_, **data):\n    conn, ch = connect()\n    ch.basic_publish(\"checkout\", \"\", json.dumps({**data, \"type\": type_}))\n    conn.close()\n    print(f\"{time.strftime('%H:%M:%S')}.{int(time.time() * 1000) % 1000:03d} \"\n          f\"{NAME}: {type_} {data['order']}\")\n\n", "note": "Every event a service publishes is printed with the time to the millisecond, so that the logs of all the services, sorted together, show the order things happened in."}, {"code": "def listen(handlers):\n    def run():\n        conn, ch = connect()\n        ch.queue_declare(NAME, durable=True)\n        ch.queue_bind(NAME, \"checkout\")\n        for method, props, body in ch.consume(NAME):\n            event = json.loads(body)\n            if event[\"type\"] in handlers:\n                with lock:\n                    handlers[event[\"type\"]](event)\n            ch.basic_ack(method.delivery_tag)\n    threading.Thread(target=run, daemon=True).start()\n\n\ndef serve(routes):\n    class Handler(BaseHTTPRequestHandler):\n        def answer(self, code, body):\n            data = json.dumps(body).encode()\n            self.send_response(code)\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            self.wfile.write(data)\n\n        def do_GET(self):\n            with lock:\n                self.answer(200, routes[\"/\"]())\n\n        def do_POST(self):\n            body = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n            with lock:\n                self.answer(*routes[self.path](body))\n\n        def log_message(self, *args):\n            pass\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`listen` runs the service's event handlers, one event at a time, under the same lock as the HTTP handlers, so the two ways in never change the state at once."}]}
```

`stock.py`:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"Stock: reserve, release and confirm units of coffee.\"\"\"\nfrom common import listen, publish, serve\n\nshelf = {\"coffee\": 3}\nreservations = {}  # order -> {\"sku\", \"units\", \"status\"}\n\n\ndef reserve(b):\n    if shelf[b[\"sku\"]] < b[\"units\"]:\n        return 409, {\"error\": f\"only {shelf[b['sku']]} {b['sku']} left\"}\n    shelf[b[\"sku\"]] -= b[\"units\"]\n    reservations[b[\"order\"]] = {\"sku\": b[\"sku\"], \"units\": b[\"units\"], \"status\": \"reserved\"}\n    return 200, {\"reserved\": b[\"units\"]}\n\n", "note": "The stock service. A reservation is the **semantic lock** of the lesson: the units leave what can be sold the moment they are reserved, before anything is paid, and they are either confirmed when the order completes or released when it does not."}, {"code": "def release(b):\n    r = reservations.get(b[\"order\"])\n    if r and r[\"status\"] == \"reserved\":\n        shelf[r[\"sku\"]] += r[\"units\"]\n        r[\"status\"] = \"released\"\n    return 200, {\"released\": b[\"order\"]}\n\n\ndef confirm(b):\n    reservations[b[\"order\"]][\"status\"] = \"sold\"\n    return 200, {\"sold\": b[\"order\"]}\n\n\ndef on_placed(e):\n    code, _ = reserve(e)\n    publish(\"StockReserved\" if code == 200 else \"StockRefused\", **e)\n\n\nlisten({\"OrderPlaced\": on_placed,\n        \"PaymentFailed\": lambda e: (release(e), publish(\"StockReleased\", **e)),\n        \"PaymentRefunded\": lambda e: (release(e), publish(\"StockReleased\", **e)),\n        \"ShippingScheduled\": lambda e: confirm(e)})\nserve({\"/\": lambda: {\"shelf\": shelf, \"reservations\": reservations},\n       \"/reserve\": reserve, \"/release\": release, \"/confirm\": confirm})", "note": "Releasing is the compensation for reserving. It is safe to call twice, and safe to call for an order that never reserved anything, because a compensation may be retried after a crash just like any other step."}]}
```

`payments.py`:

```schooling-example
{"language": "python", "file": "payments.py", "parts": [{"code": "\"\"\"Payments: charge and refund.\"\"\"\nfrom common import listen, publish, serve\n\ncharges = {}  # order -> {\"cents\", \"status\"}\n\n\ndef charge(b):\n    if b[\"card\"].endswith(\"0002\"):\n        return 402, {\"error\": \"card declined\"}\n    charges[b[\"order\"]] = {\"cents\": b[\"cents\"], \"status\": \"charged\"}\n    return 200, {\"charged\": b[\"cents\"]}\n\n\ndef refund(b):\n    c = charges.get(b[\"order\"])\n    if c and c[\"status\"] == \"charged\":\n        c[\"status\"] = \"refunded\"\n    return 200, {\"refunded\": b[\"order\"]}\n\n\ndef on_reserved(e):\n    code, _ = charge(e)\n    publish(\"PaymentCharged\" if code == 200 else \"PaymentFailed\", **e)\n\n\nlisten({\"StockReserved\": on_reserved,\n        \"ShippingFailed\": lambda e: (refund(e), publish(\"PaymentRefunded\", **e))})\nserve({\"/\": lambda: charges, \"/charge\": charge, \"/refund\": refund})", "note": "The payments service. A card ending in 0002 is declined, the way test card numbers work at real payment gateways. Refunding is the compensation for charging; like releasing stock, it does nothing for an order with nothing to refund."}]}
```

`shipping.py`:

```schooling-example
{"language": "python", "file": "shipping.py", "parts": [{"code": "\"\"\"Shipping: schedule a delivery.\"\"\"\nfrom common import listen, publish, serve\n\nSERVED = {\"Recife\", \"Olinda\", \"Jaboatão\"}\ndeliveries = {}  # order -> city\n\n\ndef schedule(b):\n    if b[\"city\"] not in SERVED:\n        return 422, {\"error\": f\"no deliveries to {b['city']}\"}\n    deliveries[b[\"order\"]] = b[\"city\"]\n    return 200, {\"scheduled\": b[\"city\"]}\n\n\ndef on_charged(e):\n    code, _ = schedule(e)\n    publish(\"ShippingScheduled\" if code == 200 else \"ShippingFailed\", **e)\n\n\nlisten({\"PaymentCharged\": on_charged})\nserve({\"/\": lambda: deliveries, \"/schedule\": schedule})", "note": "The shipping service. It delivers to three cities. Scheduling is the last step of the checkout, so it has no compensation: if it fails, the steps before it are undone, and if it succeeds, the order is complete."}]}
```

`saga.py`, the orchestrator:

```schooling-example
{"language": "python", "file": "saga.py", "parts": [{"code": "\"\"\"Run the checkout as an orchestrated saga.\"\"\"\nimport argparse, json, time, urllib.error, urllib.request\n\np = argparse.ArgumentParser()\np.add_argument(\"order\")\np.add_argument(\"--units\", type=int, default=1)\np.add_argument(\"--card\", default=\"4111-1111\")\np.add_argument(\"--city\", default=\"Recife\")\np.add_argument(\"--pause\", type=float, default=0, help=\"seconds to wait after reserving\")\na = p.parse_args()\norder = {\"order\": a.order, \"sku\": \"coffee\", \"units\": a.units, \"cents\": 2490 * a.units,\n         \"card\": a.card, \"city\": a.city}\n\n\ndef call(service, action):\n    req = urllib.request.Request(f\"http://{service}:8000/{action}\", data=json.dumps(order).encode(),\n                                 headers={\"Content-Type\": \"application/json\"})\n    try:\n        with urllib.request.urlopen(req) as r:\n            print(f\"  {service} {action}: ok {json.load(r)}\")\n            return True\n    except urllib.error.HTTPError as e:\n        print(f\"  {service} {action}: failed {json.load(e)}\")\n        return False\n\n\nSTEPS = [(\"stock\", \"reserve\", \"release\"), (\"payments\", \"charge\", \"refund\"),\n         (\"shipping\", \"schedule\", None), (\"stock\", \"confirm\", None)]\ndone = []\nprint(f\"{a.order}: saga started\")\nfor service, action, compensation in STEPS:\n    if not call(service, action):\n        print(f\"{a.order}: compensating\")\n        for s, c in reversed(done):\n            call(s, c)\n        print(f\"{a.order}: failed, everything undone\")\n        break\n    if compensation:\n        done.append((service, compensation))\n    if action == \"reserve\" and a.pause:\n        time.sleep(a.pause)\nelse:\n    print(f\"{a.order}: completed\")", "note": "The orchestrator. The checkout's saga is a list of steps, each with the step that undoes it. They run in order; when one fails, the ones already done are compensated in reverse order. Every step and compensation is printed, which is the log a real orchestrator would write to a database before each call, so that a crash halfway can be resumed."}]}
```

`place.py`, the start of the choreography:

```schooling-example
{"language": "python", "file": "place.py", "parts": [{"code": "\"\"\"Place an order by publishing OrderPlaced.\"\"\"\nimport argparse\nfrom common import publish\n\np = argparse.ArgumentParser()\np.add_argument(\"order\")\np.add_argument(\"--units\", type=int, default=1)\np.add_argument(\"--card\", default=\"4111-1111\")\np.add_argument(\"--city\", default=\"Recife\")\na = p.parse_args()\npublish(\"OrderPlaced\", order=a.order, sku=\"coffee\", units=a.units, cents=2490 * a.units,\n        card=a.card, city=a.city)", "note": "The choreographed checkout starts with one event and no orchestrator: this publishes `OrderPlaced` and exits. What happens next is decided by whichever services react."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "Python and pika, as in lessons 6, 7 and 9."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-service: &service\n  build: .\n  environment: &env\n    RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    PYTHONUNBUFFERED: \"1\"\n  depends_on:\n    - rabbitmq\nservices:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  stock:\n    <<: *service\n    command: python stock.py\n    environment: {<<: *env, NAME: stock}\n    ports: [\"8001:8000\"]\n  payments:\n    <<: *service\n    command: python payments.py\n    environment: {<<: *env, NAME: payments}\n    ports: [\"8002:8000\"]\n  shipping:\n    <<: *service\n    command: python shipping.py\n    environment: {<<: *env, NAME: shipping}\n    ports: [\"8003:8000\"]\n  tools:\n    <<: *service\n    profiles: [\"tools\"]\n    environment: {<<: *env, NAME: checkout}\n    depends_on: []", "note": "The broker, the three services, and the image for the two ways of starting a checkout. Every service is reachable from the machine, on 8001 to 8003, so `curl` can show what each one holds."}]}
```

Start everything, give the broker about fifteen seconds, and keep the command that runs a script in a
variable:

```sh
docker compose up -d --build
R="docker compose --progress quiet run --rm tools python"
```
