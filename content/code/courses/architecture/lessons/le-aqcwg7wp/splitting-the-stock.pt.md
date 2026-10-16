---
title: Tirando o estoque
version: 1
---

O módulo de estoque da aula 1 vira um serviço: um programa próprio, num contêiner próprio, com um
banco que mais ninguém abre. A loja fica com o catálogo, os pedidos e os pagamentos, e pergunta ao
serviço de estoque sempre que precisa de uma contagem ou quer baixar unidades.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O laboratório depois da divisão. A porta 8000 do loopback da máquina leva ao contêiner da loja, que tem catálogo, pedidos e pagamentos e o seu próprio banco shop.db. A loja chama o contêiner de estoque pela rede do Compose em http://stock:8001; o contêiner de estoque tem o seu próprio banco stock.db e não publica porta.\"><defs><marker id=\"l2-split-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l2-split-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"24\" y=\"90\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"79\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">curl</text><text x=\"79\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8000</text><rect x=\"170\" y=\"40\" width=\"400\" height=\"190\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"186\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rede split_default</text><rect x=\"190\" y=\"70\" width=\"170\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">shop</text><text x=\"275\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">catálogo, pedidos,</text><text x=\"275\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pagamentos</text><rect x=\"215\" y=\"160\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><rect x=\"420\" y=\"70\" width=\"140\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">stock</text><text x=\"490\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">responde em :8001</text><text x=\"490\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem porta publicada</text><rect x=\"430\" y=\"160\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.db</text><path d=\"M136 115 L188 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-split-ah-wire)\"></path><path d=\"M362 140 L418 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-split-ah-phosphor)\"></path></svg>", "caption": "Dois programas, dois bancos, uma rede entre eles. O serviço de estoque só é alcançado pela loja, porque não publica porta própria."}
```

Esta aula trabalha em `~/lab/split`, com um diretório por serviço:

```sh
mkdir -p ~/lab/split/shop ~/lab/split/stock && cd ~/lab/split
```

## O serviço de estoque

`stock/stock.py`:

```schooling-example
{"language": "python", "file": "stock/stock.py", "parts": [{"code": "\"\"\"Quitanda's stock service.\"\"\"\nimport json, os, sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"STOCK_DB\", \"/data/stock.db\")\nUNITS = {\"tomato\": 40, \"banana\": 25, \"coffee\": 12, \"cheese\": 8, \"bread\": 30}\n\n\ndef db():\n    return sqlite3.connect(DB)\n\n", "note": "O serviço de estoque: o módulo de estoque da aula 1, levado para um programa próprio com um banco próprio. Mais ninguém lê a tabela dele."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        con = db()\n        if self.path == \"/stock\":\n            self.reply(200, dict(con.execute(\"SELECT sku, units FROM stock\").fetchall()))\n        else:\n            row = con.execute(\"SELECT units FROM stock WHERE sku = ?\", (self.path.split(\"/\")[-1],)).fetchone()\n            self.reply(200, {\"units\": row[0]}) if row else self.reply(404, {\"error\": \"no such sku\"})\n        con.close()\n\n    def do_POST(self):  # POST /stock/<sku>/take  {\"qty\": n}\n        sku = self.path.split(\"/\")[2]\n        qty = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))[\"qty\"]\n        con = db()\n        try:\n            with con:\n                con.execute(\"UPDATE stock SET units = units - ? WHERE sku = ?\", (qty, sku))\n            self.reply(200, {\"sku\": sku, \"taken\": qty})\n        except sqlite3.IntegrityError:\n            self.reply(409, {\"error\": \"not enough stock\"})\n        con.close()\n", "note": "Três rotas: todas as contagens, uma contagem, e baixar unidades. Uma baixa que deixaria o estoque abaixo de zero é recusada com 409, como o CHECK fazia dentro do monólito."}, {"code": "    def log_message(self, fmt, *args):\n        rid = self.headers.get(\"X-Request-Id\", \"-\") if hasattr(self, \"headers\") else \"-\"\n        print(f\"stock [{rid}] {fmt % args}\", flush=True)\n\n\nif __name__ == \"__main__\":\n    con = db()\n    con.execute(\"CREATE TABLE IF NOT EXISTS stock (sku TEXT PRIMARY KEY, units INTEGER CHECK (units >= 0))\")\n    with con:\n        con.executemany(\"INSERT OR IGNORE INTO stock VALUES (?, ?)\", UNITS.items())\n    con.close()\n    print(\"stock listening on :8001\", flush=True)\n    ThreadingHTTPServer((\"\", 8001), Handler).serve_forever()", "note": "Toda linha de log começa com o id de requisição que quem chamou mandou, para um pedido poder ser seguido pelos dois serviços."}]}
```

`stock/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "stock/Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"stock.py\"]", "note": "As mesmas três linhas da aula 1, para um programa cada; todo arquivo .py do diretório entra na imagem."}]}
```

## A loja

`shop/shop.py` é o `app.py` da aula 1 sem o módulo de estoque e com uma função, `stock_call`, no
lugar dele:

```schooling-example
{"language": "python", "file": "shop/shop.py", "parts": [{"code": "\"\"\"Quitanda's shop: catalogue, orders and payments. Stock is a service.\"\"\"\nimport json, os, sqlite3, urllib.error, urllib.request, uuid\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"SHOP_DB\", \"/data/shop.db\")\nSTOCK = os.environ.get(\"STOCK_URL\", \"http://stock:8001\")\nPRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899), (\"banana\", \"Bananas, 1 kg\", 649),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290), (\"cheese\", \"Minas cheese, 500 g\", 2450),\n            (\"bread\", \"Bread rolls, 6\", 990)]\n\n\ndef db():\n    con = sqlite3.connect(DB)\n    con.row_factory = sqlite3.Row\n    return con\n\n", "note": "A loja é o programa da aula 1 sem o módulo de estoque. Catálogo, pedidos e pagamentos continuam juntos, com banco próprio; o estoque agora é alcançado por HTTP, no endereço em STOCK_URL."}, {"code": "def stock_call(rid, method, path, body=None):\n    req = urllib.request.Request(STOCK + path, method=method, headers={\"X-Request-Id\": rid},\n                                 data=json.dumps(body).encode() if body is not None else None)\n    try:\n        with urllib.request.urlopen(req, timeout=2) as r:\n            return r.status, json.loads(r.read())\n    except urllib.error.HTTPError as e:\n        return e.code, json.loads(e.read())\n\n\nclass Declined(Exception):\n    pass\n\n\ndef payments_charge(con, order_id, card, amount):\n    if card.endswith(\"0002\"):\n        raise Declined(\"card declined\")\n    con.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (order_id, card[-4:], amount))\n\n", "note": "A única função que conversa com o outro serviço. Repassa o id de requisição, espera no máximo dois segundos e transforma um erro HTTP num status e num corpo como qualquer outra resposta."}, {"code": "def orders_place(rid, sku, qty, card):\n    con = db()\n    try:\n        price = con.execute(\"SELECT price_cents FROM products WHERE sku = ?\", (sku,)).fetchone()[0]\n        status, body = stock_call(rid, \"POST\", f\"/stock/{sku}/take\", {\"qty\": qty})\n        if status != 200:\n            return status, body\n        with con:\n            cur = con.execute(\"INSERT INTO orders (sku, qty, total_cents) VALUES (?, ?, ?)\", (sku, qty, price * qty))\n            payments_charge(con, cur.lastrowid, card, price * qty)\n        return 201, {\"order\": cur.lastrowid, \"sku\": sku, \"qty\": qty, \"total_cents\": price * qty}\n    except Declined as e:\n        return 402, {\"error\": str(e)}\n    finally:\n        con.close()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        if isinstance(body, list):\n            text = \"[\\n\" + \",\\n\".join(json.dumps(x) for x in body) + \"\\n]\"\n        else:\n            text = json.dumps(body)\n        data = (text + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"X-Request-Id\", self.rid)\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Fazer um pedido agora são duas transações em dois lugares. O estoque é baixado primeiro, pelo outro serviço, e confirmado lá; depois o pedido e o pagamento são gravados aqui. Um cartão recusado desfaz só este lado."}, {"code": "    def do_GET(self):\n        self.rid = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:8]\n        if self.path != \"/products\":\n            return self.reply(404, {\"error\": \"not found\"})\n        try:\n            _, units = stock_call(self.rid, \"GET\", \"/stock\")\n        except OSError:\n            return self.reply(503, {\"error\": \"stock unavailable\"})\n        con = db()\n        rows = [dict(r) | {\"units\": units.get(r[\"sku\"])} for r in con.execute(\"SELECT * FROM products\")]\n        con.close()\n        self.reply(200, rows)\n\n    def do_POST(self):\n        self.rid = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:8]\n        req = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        try:\n            self.reply(*orders_place(self.rid, req[\"sku\"], req[\"qty\"], req[\"card\"]))\n        except OSError:\n            self.reply(503, {\"error\": \"stock unavailable\"})\n\n    def log_message(self, fmt, *args):\n        print(f\"shop  [{getattr(self, 'rid', '-')}] {fmt % args}\", flush=True)\n\n\nif __name__ == \"__main__\":\n    con = db()\n    con.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS products (sku TEXT PRIMARY KEY, name TEXT, price_cents INTEGER);\n    CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, sku TEXT, qty INTEGER, total_cents INTEGER);\n    CREATE TABLE IF NOT EXISTS payments (order_id INTEGER, card TEXT, amount_cents INTEGER);\n    \"\"\")\n    with con:\n        con.executemany(\"INSERT OR IGNORE INTO products VALUES (?, ?, ?)\", PRODUCTS)\n    con.close()\n    print(\"shop listening on :8000\", flush=True)\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "Cada requisição ganha um id aqui, na borda, a não ser que quem chamou tenha mandado um. O catálogo precisa das unidades, então listar produtos agora também é uma chamada ao serviço de estoque."}]}
```

`shop/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "shop/Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"shop.py\"]", "note": "As mesmas três linhas da aula 1, para um programa cada; todo arquivo .py do diretório entra na imagem."}]}
```

`shop/bench.py` é uma pequena medição que a próxima seção roda. Salve agora, para que ele esteja na
imagem:

```schooling-example
{"language": "python", "file": "shop/bench.py", "parts": [{"code": "\"\"\"How long does asking another service take, against asking yourself?\"\"\"\nimport os, time, urllib.request\n\nSTOCK = os.environ.get(\"STOCK_URL\", \"http://stock:8001\")\nN = 1000\nunits = {\"coffee\": 12}\n\n\ndef local(sku):\n    return units[sku]\n\n\ndef remote(sku):\n    with urllib.request.urlopen(f\"{STOCK}/stock/{sku}\") as r:\n        return r.read()\n\n", "note": "Mil leituras de uma contagem de estoque, feitas duas vezes: como chamada de função sobre um dicionário neste processo, e como requisição HTTP ao serviço de estoque. Cada requisição abre uma conexão nova, como o `urllib` faz por padrão."}, {"code": "for name, fn in ((\"function call\", local), (\"HTTP call\", remote)):\n    start = time.perf_counter()\n    for _ in range(N):\n        fn(\"coffee\")\n    per_call = (time.perf_counter() - start) / N * 1e6\n    print(f\"{name:14} {per_call:10.2f} µs per call\")", "note": "O resultado sai em microssegundos por chamada, a média das mil."}]}
```

## O arquivo compose

`compose.yaml`, no próprio `~/lab/split`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  shop:\n    build: ./shop\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    environment:\n      STOCK_URL: http://stock:8001\n    volumes:\n      - shop-data:/data\n    depends_on:\n      - stock\n  stock:\n    build: ./stock\n    volumes:\n      - stock-data:/data\nvolumes:\n  shop-data:\n  stock-data:", "note": "Dois serviços, dois volumes, dois bancos. Só a loja publica uma porta; o serviço de estoque é alcançável pela loja pelo nome, `stock`, na rede que o Compose cria para o projeto, e de nenhum outro lugar."}]}
```

## Rodando

```
ana@vm:~/lab/split$ find . -type f | sort
./compose.yaml
./shop/Dockerfile
./shop/bench.py
./shop/shop.py
./stock/Dockerfile
./stock/stock.py
ana@vm:~/lab/split$ docker compose up -d --build --quiet-build
 Image split-shop Building 
 Image split-stock Building 
 Image split-stock Built 
 Image split-shop Built 
 Volume split_shop-data Creating 
 Network split_default Creating 
 Volume split_shop-data Creating 
 Network split_default Creating 
 Volume split_stock-data Creating 
 Volume split_stock-data Creating 
 Volume split_shop-data Created 
 Volume split_shop-data Created 
 Volume split_stock-data Created 
 Volume split_stock-data Created 
 Network split_default Created 
 Network split_default Created 
 Container split-stock-1 Creating 
 Container split-stock-1 Created 
 Container split-shop-1 Creating 
 Container split-shop-1 Created 
 Container split-stock-1 Starting 
 Container split-stock-1 Started 
 Container split-shop-1 Starting 
 Container split-shop-1 Started 
ana@vm:~/lab/split$ docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
SERVICE   STATUS                  PORTS
shop      Up Less than a second   127.0.0.1:8000->8000/tcp
stock     Up Less than a second   
```

O catálogo continua listando cinco produtos com as unidades, e essas unidades agora vêm de outro
programa:

```
ana@vm:~/lab/split$ curl -s localhost:8000/products
[
{"sku": "tomato", "name": "Tomatoes, 1 kg", "price_cents": 899, "units": 40},
{"sku": "banana", "name": "Bananas, 1 kg", "price_cents": 649, "units": 25},
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 12},
{"sku": "cheese", "name": "Minas cheese, 500 g", "price_cents": 2450, "units": 8},
{"sku": "bread", "name": "Bread rolls, 6", "price_cents": 990, "units": 30}
]
```

**Toda requisição carrega um id da borda para dentro.** A loja dá um a cada requisição, ou mantém o
que quem chamou mandou, e o repassa ao serviço de estoque no cabeçalho `X-Request-Id`; os dois o
escrevem no começo de cada linha de log. Mandar um id reconhecível facilita seguir um pedido pelos
dois logs:

```
ana@vm:~/lab/split$ curl -s -H 'X-Request-Id: order-1' -X POST localhost:8000/orders -d '{"sku": "tomato", "qty": 3, "card": "4111111111111111"}'
{"order": 1, "sku": "tomato", "qty": 3, "total_cents": 2697}
ana@vm:~/lab/split$ docker compose logs --no-log-prefix | grep order-1
stock [order-1] "POST /stock/tomato/take HTTP/1.1" 200 -
shop  [order-1] "POST /orders HTTP/1.1" 201 -
```

Dois serviços registraram cada um a sua metade do mesmo pedido, e o id é o que as junta. Com dois
serviços dá para viver sem ele. Com vinte, e cem requisições por segundo, é o único jeito de saber
que linha de um log combina com que linha de outro, e a aula 7 de `scale` constrói a versão completa
disso, um trace.
