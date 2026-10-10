---
title: O laboratório: estoque, pagamentos e entregas
version: 1
---

Três serviços, cada um guardando o estado em memória e respondendo JSON sobre HTTP, mais um broker para a
segunda metade da aula. O café começa com **três pacotes na prateleira**. Um cartão terminado em `0002` é
recusado, e as entregas só vão para Recife, Olinda e Jaboatão. Ele fica em `~/lab/saga`:

```sh
mkdir -p ~/lab/saga && cd ~/lab/saga
```

`common.py`, o que os serviços compartilham:

```schooling-example
{"language": "python", "file": "common.py", "parts": [{"code": "\"\"\"HTTP and events for the lab's services.\"\"\"\nimport json, os, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nimport pika\n\nNAME = os.environ[\"NAME\"]\nlock = threading.Lock()\n\n\ndef connect():\n    params = pika.URLParameters(os.environ[\"RABBIT_URL\"])\n    while True:\n        try:\n            conn = pika.BlockingConnection(params)\n            break\n        except pika.exceptions.AMQPConnectionError:\n            time.sleep(1)\n    ch = conn.channel()\n    ch.exchange_declare(\"checkout\", exchange_type=\"fanout\", durable=True)\n    return conn, ch\n\n", "note": "O que os três serviços compartilham: um servidor pequeno de JSON sobre HTTP para a saga orquestrada, e a exchange `checkout` para a coreografada. Cada serviço escuta a sua própria fila, ligada à exchange, então todo serviço vê todo evento e escolhe os que lhe interessam."}, {"code": "def publish(type_, **data):\n    conn, ch = connect()\n    ch.basic_publish(\"checkout\", \"\", json.dumps({**data, \"type\": type_}))\n    conn.close()\n    print(f\"{time.strftime('%H:%M:%S')}.{int(time.time() * 1000) % 1000:03d} \"\n          f\"{NAME}: {type_} {data['order']}\")\n\n", "note": "Todo evento que um serviço publica é impresso com a hora até o milissegundo, para os logs de todos os serviços, ordenados juntos, mostrarem a ordem em que as coisas aconteceram."}, {"code": "def listen(handlers):\n    def run():\n        conn, ch = connect()\n        ch.queue_declare(NAME, durable=True)\n        ch.queue_bind(NAME, \"checkout\")\n        for method, props, body in ch.consume(NAME):\n            event = json.loads(body)\n            if event[\"type\"] in handlers:\n                with lock:\n                    handlers[event[\"type\"]](event)\n            ch.basic_ack(method.delivery_tag)\n    threading.Thread(target=run, daemon=True).start()\n\n\ndef serve(routes):\n    class Handler(BaseHTTPRequestHandler):\n        def answer(self, code, body):\n            data = json.dumps(body).encode()\n            self.send_response(code)\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            self.wfile.write(data)\n\n        def do_GET(self):\n            with lock:\n                self.answer(200, routes[\"/\"]())\n\n        def do_POST(self):\n            body = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n            with lock:\n                self.answer(*routes[self.path](body))\n\n        def log_message(self, *args):\n            pass\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`listen` roda os tratadores de eventos do serviço, um evento de cada vez, sob a mesma trava dos tratadores HTTP, para os dois jeitos de entrar nunca mudarem o estado ao mesmo tempo."}]}
```

`stock.py`:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"Stock: reserve, release and confirm units of coffee.\"\"\"\nfrom common import listen, publish, serve\n\nshelf = {\"coffee\": 3}\nreservations = {}  # order -> {\"sku\", \"units\", \"status\"}\n\n\ndef reserve(b):\n    if shelf[b[\"sku\"]] < b[\"units\"]:\n        return 409, {\"error\": f\"only {shelf[b['sku']]} {b['sku']} left\"}\n    shelf[b[\"sku\"]] -= b[\"units\"]\n    reservations[b[\"order\"]] = {\"sku\": b[\"sku\"], \"units\": b[\"units\"], \"status\": \"reserved\"}\n    return 200, {\"reserved\": b[\"units\"]}\n\n", "note": "O serviço de estoque. Uma reserva é a **trava semântica** da aula: as unidades saem do que pode ser vendido no momento em que são reservadas, antes de qualquer pagamento, e são confirmadas quando o pedido se completa ou liberadas quando não se completa."}, {"code": "def release(b):\n    r = reservations.get(b[\"order\"])\n    if r and r[\"status\"] == \"reserved\":\n        shelf[r[\"sku\"]] += r[\"units\"]\n        r[\"status\"] = \"released\"\n    return 200, {\"released\": b[\"order\"]}\n\n\ndef confirm(b):\n    reservations[b[\"order\"]][\"status\"] = \"sold\"\n    return 200, {\"sold\": b[\"order\"]}\n\n\ndef on_placed(e):\n    code, _ = reserve(e)\n    publish(\"StockReserved\" if code == 200 else \"StockRefused\", **e)\n\n\nlisten({\"OrderPlaced\": on_placed,\n        \"PaymentFailed\": lambda e: (release(e), publish(\"StockReleased\", **e)),\n        \"PaymentRefunded\": lambda e: (release(e), publish(\"StockReleased\", **e)),\n        \"ShippingScheduled\": lambda e: confirm(e)})\nserve({\"/\": lambda: {\"shelf\": shelf, \"reservations\": reservations},\n       \"/reserve\": reserve, \"/release\": release, \"/confirm\": confirm})", "note": "Liberar é a compensação de reservar. Pode ser chamada duas vezes, e pode ser chamada para um pedido que nunca reservou nada, porque uma compensação pode ser repetida depois de uma queda como qualquer outro passo."}]}
```

`payments.py`:

```schooling-example
{"language": "python", "file": "payments.py", "parts": [{"code": "\"\"\"Payments: charge and refund.\"\"\"\nfrom common import listen, publish, serve\n\ncharges = {}  # order -> {\"cents\", \"status\"}\n\n\ndef charge(b):\n    if b[\"card\"].endswith(\"0002\"):\n        return 402, {\"error\": \"card declined\"}\n    charges[b[\"order\"]] = {\"cents\": b[\"cents\"], \"status\": \"charged\"}\n    return 200, {\"charged\": b[\"cents\"]}\n\n\ndef refund(b):\n    c = charges.get(b[\"order\"])\n    if c and c[\"status\"] == \"charged\":\n        c[\"status\"] = \"refunded\"\n    return 200, {\"refunded\": b[\"order\"]}\n\n\ndef on_reserved(e):\n    code, _ = charge(e)\n    publish(\"PaymentCharged\" if code == 200 else \"PaymentFailed\", **e)\n\n\nlisten({\"StockReserved\": on_reserved,\n        \"ShippingFailed\": lambda e: (refund(e), publish(\"PaymentRefunded\", **e))})\nserve({\"/\": lambda: charges, \"/charge\": charge, \"/refund\": refund})", "note": "O serviço de pagamentos. Um cartão terminado em 0002 é recusado, como funcionam os números de cartão de teste nos gateways de pagamento de verdade. Reembolsar é a compensação de cobrar; como liberar estoque, não faz nada para um pedido sem nada a reembolsar."}]}
```

`shipping.py`:

```schooling-example
{"language": "python", "file": "shipping.py", "parts": [{"code": "\"\"\"Shipping: schedule a delivery.\"\"\"\nfrom common import listen, publish, serve\n\nSERVED = {\"Recife\", \"Olinda\", \"Jaboatão\"}\ndeliveries = {}  # order -> city\n\n\ndef schedule(b):\n    if b[\"city\"] not in SERVED:\n        return 422, {\"error\": f\"no deliveries to {b['city']}\"}\n    deliveries[b[\"order\"]] = b[\"city\"]\n    return 200, {\"scheduled\": b[\"city\"]}\n\n\ndef on_charged(e):\n    code, _ = schedule(e)\n    publish(\"ShippingScheduled\" if code == 200 else \"ShippingFailed\", **e)\n\n\nlisten({\"PaymentCharged\": on_charged})\nserve({\"/\": lambda: deliveries, \"/schedule\": schedule})", "note": "O serviço de entregas. Ele entrega em três cidades. Agendar é o último passo do checkout, então não tem compensação: se falhar, os passos anteriores são desfeitos, e se der certo, o pedido está completo."}]}
```

`saga.py`, o orquestrador:

```schooling-example
{"language": "python", "file": "saga.py", "parts": [{"code": "\"\"\"Run the checkout as an orchestrated saga.\"\"\"\nimport argparse, json, time, urllib.error, urllib.request\n\np = argparse.ArgumentParser()\np.add_argument(\"order\")\np.add_argument(\"--units\", type=int, default=1)\np.add_argument(\"--card\", default=\"4111-1111\")\np.add_argument(\"--city\", default=\"Recife\")\np.add_argument(\"--pause\", type=float, default=0, help=\"seconds to wait after reserving\")\na = p.parse_args()\norder = {\"order\": a.order, \"sku\": \"coffee\", \"units\": a.units, \"cents\": 2490 * a.units,\n         \"card\": a.card, \"city\": a.city}\n\n\ndef call(service, action):\n    req = urllib.request.Request(f\"http://{service}:8000/{action}\", data=json.dumps(order).encode(),\n                                 headers={\"Content-Type\": \"application/json\"})\n    try:\n        with urllib.request.urlopen(req) as r:\n            print(f\"  {service} {action}: ok {json.load(r)}\")\n            return True\n    except urllib.error.HTTPError as e:\n        print(f\"  {service} {action}: failed {json.load(e)}\")\n        return False\n\n\nSTEPS = [(\"stock\", \"reserve\", \"release\"), (\"payments\", \"charge\", \"refund\"),\n         (\"shipping\", \"schedule\", None), (\"stock\", \"confirm\", None)]\ndone = []\nprint(f\"{a.order}: saga started\")\nfor service, action, compensation in STEPS:\n    if not call(service, action):\n        print(f\"{a.order}: compensating\")\n        for s, c in reversed(done):\n            call(s, c)\n        print(f\"{a.order}: failed, everything undone\")\n        break\n    if compensation:\n        done.append((service, compensation))\n    if action == \"reserve\" and a.pause:\n        time.sleep(a.pause)\nelse:\n    print(f\"{a.order}: completed\")", "note": "O orquestrador. A saga do checkout é uma lista de passos, cada um com o passo que o desfaz. Eles rodam em ordem; quando um falha, os que já foram feitos são compensados em ordem inversa. Todo passo e compensação é impresso, que é o log que um orquestrador de verdade gravaria num banco antes de cada chamada, para uma queda no meio poder ser retomada."}]}
```

`place.py`, o começo da coreografia:

```schooling-example
{"language": "python", "file": "place.py", "parts": [{"code": "\"\"\"Place an order by publishing OrderPlaced.\"\"\"\nimport argparse\nfrom common import publish\n\np = argparse.ArgumentParser()\np.add_argument(\"order\")\np.add_argument(\"--units\", type=int, default=1)\np.add_argument(\"--card\", default=\"4111-1111\")\np.add_argument(\"--city\", default=\"Recife\")\na = p.parse_args()\npublish(\"OrderPlaced\", order=a.order, sku=\"coffee\", units=a.units, cents=2490 * a.units,\n        card=a.card, city=a.city)", "note": "O checkout coreografado começa com um evento e nenhum orquestrador: isto publica `OrderPlaced` e termina. O que acontece depois é decidido pelos serviços que reagirem."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "Python e pika, como nas aulas 6, 7 e 9."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-service: &service\n  build: .\n  environment: &env\n    RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    PYTHONUNBUFFERED: \"1\"\n  depends_on:\n    - rabbitmq\nservices:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  stock:\n    <<: *service\n    command: python stock.py\n    environment: {<<: *env, NAME: stock}\n    ports: [\"8001:8000\"]\n  payments:\n    <<: *service\n    command: python payments.py\n    environment: {<<: *env, NAME: payments}\n    ports: [\"8002:8000\"]\n  shipping:\n    <<: *service\n    command: python shipping.py\n    environment: {<<: *env, NAME: shipping}\n    ports: [\"8003:8000\"]\n  tools:\n    <<: *service\n    profiles: [\"tools\"]\n    environment: {<<: *env, NAME: checkout}\n    depends_on: []", "note": "O broker, os três serviços, e a imagem para os dois jeitos de começar um checkout. Todo serviço é acessível da máquina, da 8001 à 8003, para o `curl` mostrar o que cada um guarda."}]}
```

Suba tudo, dê ao broker uns quinze segundos, e guarde numa variável o comando que roda um script:

```sh
docker compose up -d --build
R="docker compose --progress quiet run --rm tools python"
```
