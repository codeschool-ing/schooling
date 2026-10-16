---
title: O laboratório: o estoque e duas cópias dele
version: 1
---

O laboratório é o arranjo que a aula 5 descreveu. O **serviço de estoque** é o dono do número de
unidades de cada produto. A **loja** desenha as páginas de produto a partir da sua própria cópia desses
números, atualizada pelos eventos que o serviço de estoque publica. Há **duas cópias da loja**, `a` e
`b`, como uma loja de verdade roda mais de uma cópia atrás de um balanceador de carga, e a `b` é mais
lenta para tratar um evento, como muitas vezes uma cópia está mais ocupada que outra.

Tudo fica em memória, então reiniciar começa do zero. Três programas pequenos em Python dividem uma
imagem. Ele fica em `~/lab/eventual`:

```sh
mkdir -p ~/lab/eventual && cd ~/lab/eventual
```

`bus.py`, a exchange que os serviços compartilham:

```schooling-example
{"language": "python", "file": "bus.py", "parts": [{"code": "\"\"\"The exchange the lab's services share, and how to publish to it.\"\"\"\nimport json, os\nimport pika\n\n\ndef connect():\n    conn = pika.BlockingConnection(pika.URLParameters(os.environ[\"RABBIT_URL\"]))\n    ch = conn.channel()\n    ch.exchange_declare(\"quitanda\", exchange_type=\"fanout\", durable=True)\n    return conn, ch\n\n", "note": "A única exchange em que todo serviço do laboratório publica. É uma fanout, então cada loja recebe a sua cópia de todo evento, de estoque e de cestas."}, {"code": "def publish(event):\n    conn, ch = connect()\n    ch.basic_publish(\"quitanda\", \"\", json.dumps(event))\n    conn.close()", "note": "Uma conexão por evento é lenta e simples. Cada requisição HTTP roda numa thread própria, e uma conexão do pika não pode ser compartilhada entre threads."}]}
```

`stock.py`, o serviço de estoque:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"The stock service: the owner of how many units of each product there are.\"\"\"\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom bus import publish\n\nstock = {}    # sku -> (units, version)\nsent = {}     # (sku, version) -> the event, so it can be sent again\nlock = threading.Lock()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"text/plain\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        sku = self.path.split(\"/\")[-1]\n        with lock:\n            if sku not in stock:\n                return self.reply(404, f\"{sku}: no such product\")\n            units, version = stock[sku]\n        self.reply(200, f\"{sku}: {units} in stock, version {version}\")\n", "note": "O serviço de estoque, o único lugar que decide quantas unidades existem. Ele as guarda em memória, o que basta para um laboratório, e dá a toda mudança de um produto uma versão: 1, 2, 3, e assim por diante."}, {"code": "    def do_PUT(self):\n        sku = self.path.split(\"/\")[-1]\n        units = int(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        with lock:\n            version = stock.get(sku, (0, 0))[1] + 1\n            event = {\"kind\": \"stock\", \"sku\": sku, \"units\": units, \"version\": version}\n            try:\n                publish(event)\n            except Exception as e:\n                return self.reply(503, f\"not changed, the broker refused the event: {e!r}\")\n            stock[sku] = (units, version)\n            sent[(sku, version)] = event\n        self.reply(200, f\"{sku}: {units} in stock, version {version}\")\n", "note": "`PUT /stock/coffee` com um número no corpo define as unidades. O evento é publicado antes de a mudança ser guardada, então um broker fora do ar não deixa nada mudado e quem chamou vê um 503. Segurar a trava nas duas coisas mantém os eventos na ordem das versões."}, {"code": "    def do_POST(self):\n        _, _, sku, version = self.path.split(\"/\")\n        event = sent[(sku, int(version))]\n        publish(event)\n        self.reply(200, f\"sent again: {sku} = {event['units']}, version {version}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`POST /resend/coffee/3` publica de novo a versão 3 do café, atrasada. É o que uma reentrega faz depois de um consumidor cair, e o que um segundo consumidor na mesma fila faz quando é mais lento que o primeiro."}]}
```

`shop.py`, a loja:

```schooling-example
{"language": "python", "file": "shop.py", "parts": [{"code": "\"\"\"One copy of the shop: a product page drawn from its own copy of the stock, and baskets.\"\"\"\nimport json, os, threading, time, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nimport pika\nfrom bus import connect, publish\n\nNAME = os.environ[\"NAME\"]\nLAG = float(os.environ[\"LAG\"])\nCHECK_VERSION = os.environ[\"CHECK_VERSION\"] == \"1\"\nMERGE = os.environ[\"MERGE\"]\ncopy = {}      # sku -> (units, version)\nbaskets = {}   # customer -> (items, time of the last change)\nlock = threading.Lock()\n\n", "note": "A loja. Ela nunca pergunta ao serviço de estoque quantas unidades existem quando desenha a página de um produto: mantém a sua própria cópia, alimentada pelos eventos do serviço de estoque. `LAG` é quanto ela leva para tratar cada evento, fazendo o papel de um consumidor ocupado, e as duas chaves decidem como ela trata um evento velho ou uma cesta que mudou em dois lugares."}, {"code": "def apply_stock(e):\n    held = copy.get(e[\"sku\"], (None, 0))[1]\n    if CHECK_VERSION and e[\"version\"] <= held:\n        print(f\"shop-{NAME}: ignored {e['sku']} version {e['version']}, already at {held}\")\n        return\n    copy[e[\"sku\"]] = (e[\"units\"], e[\"version\"])\n    print(f\"shop-{NAME}: {e['sku']} = {e['units']}, version {e['version']}\")\n\n", "note": "Com `CHECK_VERSION=0` a cópia aceita o que chegar por último. Com `1` ela recusa um evento mais velho do que o que já tem."}, {"code": "def apply_basket(e):\n    if e[\"from\"] == NAME:\n        return\n    mine, at = baskets.get(e[\"customer\"], (set(), 0))\n    if MERGE == \"union\":\n        baskets[e[\"customer\"]] = (mine | set(e[\"items\"]), max(at, e[\"at\"]))\n    elif e[\"at\"] > at:\n        baskets[e[\"customer\"]] = (set(e[\"items\"]), e[\"at\"])\n    print(f\"shop-{NAME}: basket {e['customer']} = {', '.join(sorted(baskets[e['customer']][0]))}\")\n\n", "note": "Uma cesta pode mudar em qualquer uma das lojas, e cada uma avisa a outra publicando a cesta inteira. `MERGE=lww` fica com a que mudou por último; `MERGE=union` fica com todo item que qualquer um dos lados tem."}, {"code": "def follow():\n    while True:\n        try:\n            conn, ch = connect()\n            break\n        except pika.exceptions.AMQPConnectionError:\n            time.sleep(1)\n    ch.queue_declare(f\"shop-{NAME}\", durable=True)\n    ch.queue_bind(f\"shop-{NAME}\", \"quitanda\")\n    for method, props, body in ch.consume(f\"shop-{NAME}\"):\n        time.sleep(LAG)\n        event = json.loads(body)\n        with lock:\n            apply_stock(event) if event[\"kind\"] == \"stock\" else apply_basket(event)\n        ch.basic_ack(method.delivery_tag)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"text/plain\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n", "note": "A loja pode subir antes de o broker estar pronto, então tenta de novo a cada segundo até conectar. A fila dela é durável: eventos publicados com a loja fora do ar esperam por ela."}, {"code": "    def do_GET(self):\n        kind, key = self.path.split(\"?\")[0].split(\"/\")[1:3]\n        after = int(self.path.split(\"after=\")[1]) if \"after=\" in self.path else 0\n        with lock:\n            if kind == \"basket\":\n                items = baskets.get(key, (set(), 0))[0]\n                return self.reply(200, f\"shop-{NAME}: basket {key} = {', '.join(sorted(items)) or 'empty'}\")\n            units, version = copy.get(key, (None, 0))\n        if version < after:\n            with urllib.request.urlopen(f\"http://stock:8000/stock/{key}\") as r:\n                return self.reply(200, f\"shop-{NAME}: {r.read().decode().strip()} (copy behind, asked the stock service)\")\n        if units is None:\n            return self.reply(404, f\"shop-{NAME}: {key}: no copy yet\")\n        self.reply(200, f\"shop-{NAME}: {key}: {units} left, version {version}\")\n", "note": "`GET /product/coffee` responde a partir da cópia. `?after=N` diz \"eu já vi a versão N\": se a cópia for mais velha que isso, a página pergunta ao serviço de estoque, e diz isso."}, {"code": "    def change_basket(self, add):\n        _, _, customer, item = self.path.split(\"/\")\n        with lock:\n            items = set(baskets.get(customer, (set(), 0))[0])\n            items.add(item) if add else items.discard(item)\n            baskets[customer] = (items, time.time())\n            event = {\"kind\": \"basket\", \"customer\": customer, \"items\": sorted(items),\n                     \"at\": baskets[customer][1], \"from\": NAME}\n        publish(event)\n        self.reply(200, f\"shop-{NAME}: basket {customer} = {', '.join(sorted(items)) or 'empty'}\")\n\n    def do_PUT(self):\n        self.change_basket(add=True)\n\n    def do_DELETE(self):\n        self.change_basket(add=False)\n\n    def log_message(self, *args):\n        pass\n\n\nthreading.Thread(target=follow, daemon=True).start()\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`PUT /basket/ana/tea` põe chá na cesta da ana nesta loja e `DELETE` o tira. Nos dois casos a loja publica a cesta inteira, carimbada com o relógio desta máquina."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir pika==1.4.4\nWORKDIR /app\nCOPY *.py .", "note": "A imagem que os três serviços rodam: Python e pika, como nas aulas 6 e 7."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-app: &app\n  build: .\n  depends_on:\n    - rabbitmq\nservices:\n  rabbitmq:\n    image: rabbitmq:4.1-management\n    hostname: rabbit\n  stock:\n    <<: *app\n    command: python stock.py\n    environment:\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n    ports:\n      - \"8001:8000\"\n  shop-a:\n    <<: *app\n    command: python shop.py\n    environment: &shop\n      RABBIT_URL: amqp://guest:guest@rabbitmq:5672/\n      PYTHONUNBUFFERED: \"1\"\n      NAME: a\n      LAG: \"0.2\"\n      CHECK_VERSION: ${CHECK_VERSION:-0}\n      MERGE: ${MERGE:-lww}\n    ports:\n      - \"8002:8000\"\n  shop-b:\n    <<: *app\n    command: python shop.py\n    environment:\n      <<: *shop\n      NAME: b\n      LAG: \"2\"\n    ports:\n      - \"8003:8000\"", "note": "O broker, o serviço de estoque na porta 8001, e duas cópias da loja na 8002 e na 8003. A loja a trata um evento em um quinto de segundo e a loja b leva dois segundos, como se estivesse mais ocupada. As duas chaves vêm do shell e têm como padrão o comportamento ingênuo: `CHECK_VERSION=1 docker compose up -d` reinicia as lojas com a verificação ligada."}]}
```

Construa e suba tudo, e dê ao broker uns quinze segundos antes da primeira requisição:

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

O serviço de estoque responde na porta 8001, a loja `a` na 8002 e a loja `b` na 8003, e toda resposta é
uma linha de texto simples, então o `curl` basta. Defina o café como 12 e pergunte às duas lojas na
hora, depois pergunte de novo à loja `b` três segundos mais tarde:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 12; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
coffee: 12 in stock, version 1
shop-a: coffee: no copy yet
shop-b: coffee: no copy yet
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8003/product/coffee
shop-b: coffee: 12 left, version 1
```

O serviço de estoque disse 12 na hora, porque é o dono. Nenhuma das lojas sabia ainda: o evento estava
a caminho. Três segundos depois a loja `b` o tinha. **Nada falhou e nada estava mal configurado**, e por
um momento as duas respostas sobre um mesmo pacote de café discordaram. Esse momento é o assunto do
resto da aula.

Os logs mostram cada loja aplicando o evento, que é como você vai ver o que uma cópia fez com cada um:

```
ana@vm:~/lab/eventual$ docker compose logs shop-a shop-b
shop-b-1  | shop-b: coffee = 12, version 1
shop-a-1  | shop-a: coffee = 12, version 1
```
