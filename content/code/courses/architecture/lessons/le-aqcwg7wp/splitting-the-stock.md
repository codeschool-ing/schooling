---
title: Moving the stock out
version: 1
---

The stock module of lesson 1 becomes a service: a program of its own, in a container of its own,
with a database nobody else opens. The shop keeps the catalogue, the orders and the payments, and
asks the stock service whenever it needs a count or wants units taken.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The lab after the split. The machine&#x27;s loopback port 8000 leads to the shop container, which holds catalogue, orders and payments and its own database shop.db. The shop calls the stock container over the Compose network at http://stock:8001; the stock container holds its own database stock.db and publishes no port.\"><defs><marker id=\"l2-split-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l2-split-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"24\" y=\"90\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"79\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">curl</text><text x=\"79\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8000</text><rect x=\"170\" y=\"40\" width=\"400\" height=\"190\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"186\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">network split_default</text><rect x=\"190\" y=\"70\" width=\"170\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">shop</text><text x=\"275\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">catalogue, orders,</text><text x=\"275\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payments</text><rect x=\"215\" y=\"160\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><rect x=\"420\" y=\"70\" width=\"140\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">stock</text><text x=\"490\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answers on :8001</text><text x=\"490\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no published port</text><rect x=\"430\" y=\"160\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.db</text><path d=\"M136 115 L188 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-split-ah-wire)\"></path><path d=\"M362 140 L418 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-split-ah-phosphor)\"></path></svg>", "caption": "Two programs, two databases, one network between them. The stock service can only be reached through the shop, because it publishes no port of its own."}
```

This lesson works in `~/lab/split`, with one directory per service:

```sh
mkdir -p ~/lab/split/shop ~/lab/split/stock && cd ~/lab/split
```

## The stock service

`stock/stock.py`:

```schooling-example
{"language": "python", "file": "stock/stock.py", "parts": [{"code": "\"\"\"Quitanda's stock service.\"\"\"\nimport json, os, sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"STOCK_DB\", \"/data/stock.db\")\nUNITS = {\"tomato\": 40, \"banana\": 25, \"coffee\": 12, \"cheese\": 8, \"bread\": 30}\n\n\ndef db():\n    return sqlite3.connect(DB)\n\n", "note": "The stock service: the stock module of lesson 1, moved into a program of its own with a database of its own. Nothing else reads its table."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        con = db()\n        if self.path == \"/stock\":\n            self.reply(200, dict(con.execute(\"SELECT sku, units FROM stock\").fetchall()))\n        else:\n            row = con.execute(\"SELECT units FROM stock WHERE sku = ?\", (self.path.split(\"/\")[-1],)).fetchone()\n            self.reply(200, {\"units\": row[0]}) if row else self.reply(404, {\"error\": \"no such sku\"})\n        con.close()\n\n    def do_POST(self):  # POST /stock/<sku>/take  {\"qty\": n}\n        sku = self.path.split(\"/\")[2]\n        qty = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))[\"qty\"]\n        con = db()\n        try:\n            with con:\n                con.execute(\"UPDATE stock SET units = units - ? WHERE sku = ?\", (qty, sku))\n            self.reply(200, {\"sku\": sku, \"taken\": qty})\n        except sqlite3.IntegrityError:\n            self.reply(409, {\"error\": \"not enough stock\"})\n        con.close()\n", "note": "Three routes: every count, one count, and taking units. A take that would go below zero is refused with 409, as the CHECK did inside the monolith."}, {"code": "    def log_message(self, fmt, *args):\n        rid = self.headers.get(\"X-Request-Id\", \"-\") if hasattr(self, \"headers\") else \"-\"\n        print(f\"stock [{rid}] {fmt % args}\", flush=True)\n\n\nif __name__ == \"__main__\":\n    con = db()\n    con.execute(\"CREATE TABLE IF NOT EXISTS stock (sku TEXT PRIMARY KEY, units INTEGER CHECK (units >= 0))\")\n    with con:\n        con.executemany(\"INSERT OR IGNORE INTO stock VALUES (?, ?)\", UNITS.items())\n    con.close()\n    print(\"stock listening on :8001\", flush=True)\n    ThreadingHTTPServer((\"\", 8001), Handler).serve_forever()", "note": "Every log line starts with the request id the caller sent, so one order can be followed across both services."}]}
```

`stock/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "stock/Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"stock.py\"]", "note": "The same three lines as lesson 1's, for one program each; every .py file in the directory goes into the image."}]}
```

## The shop

`shop/shop.py` is lesson 1's `app.py` with the stock module removed and one function,
`stock_call`, in its place:

```schooling-example
{"language": "python", "file": "shop/shop.py", "parts": [{"code": "\"\"\"Quitanda's shop: catalogue, orders and payments. Stock is a service.\"\"\"\nimport json, os, sqlite3, urllib.error, urllib.request, uuid\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"SHOP_DB\", \"/data/shop.db\")\nSTOCK = os.environ.get(\"STOCK_URL\", \"http://stock:8001\")\nPRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899), (\"banana\", \"Bananas, 1 kg\", 649),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290), (\"cheese\", \"Minas cheese, 500 g\", 2450),\n            (\"bread\", \"Bread rolls, 6\", 990)]\n\n\ndef db():\n    con = sqlite3.connect(DB)\n    con.row_factory = sqlite3.Row\n    return con\n\n", "note": "The shop is lesson 1's program with the stock module taken out. Catalogue, orders and payments stay together, with their own database; stock is now reached over HTTP, at the address in STOCK_URL."}, {"code": "def stock_call(rid, method, path, body=None):\n    req = urllib.request.Request(STOCK + path, method=method, headers={\"X-Request-Id\": rid},\n                                 data=json.dumps(body).encode() if body is not None else None)\n    try:\n        with urllib.request.urlopen(req, timeout=2) as r:\n            return r.status, json.loads(r.read())\n    except urllib.error.HTTPError as e:\n        return e.code, json.loads(e.read())\n\n\nclass Declined(Exception):\n    pass\n\n\ndef payments_charge(con, order_id, card, amount):\n    if card.endswith(\"0002\"):\n        raise Declined(\"card declined\")\n    con.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (order_id, card[-4:], amount))\n\n", "note": "The one function that talks to the other service. It passes the request id along, waits at most two seconds, and turns an HTTP error into a status and a body like any other answer."}, {"code": "def orders_place(rid, sku, qty, card):\n    con = db()\n    try:\n        price = con.execute(\"SELECT price_cents FROM products WHERE sku = ?\", (sku,)).fetchone()[0]\n        status, body = stock_call(rid, \"POST\", f\"/stock/{sku}/take\", {\"qty\": qty})\n        if status != 200:\n            return status, body\n        with con:\n            cur = con.execute(\"INSERT INTO orders (sku, qty, total_cents) VALUES (?, ?, ?)\", (sku, qty, price * qty))\n            payments_charge(con, cur.lastrowid, card, price * qty)\n        return 201, {\"order\": cur.lastrowid, \"sku\": sku, \"qty\": qty, \"total_cents\": price * qty}\n    except Declined as e:\n        return 402, {\"error\": str(e)}\n    finally:\n        con.close()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        if isinstance(body, list):\n            text = \"[\\n\" + \",\\n\".join(json.dumps(x) for x in body) + \"\\n]\"\n        else:\n            text = json.dumps(body)\n        data = (text + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"X-Request-Id\", self.rid)\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Placing an order is now two transactions in two places. The stock is taken first, by the other service, and committed there; then the order and the payment are written here. A declined card rolls back this side only."}, {"code": "    def do_GET(self):\n        self.rid = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:8]\n        if self.path != \"/products\":\n            return self.reply(404, {\"error\": \"not found\"})\n        try:\n            _, units = stock_call(self.rid, \"GET\", \"/stock\")\n        except OSError:\n            return self.reply(503, {\"error\": \"stock unavailable\"})\n        con = db()\n        rows = [dict(r) | {\"units\": units.get(r[\"sku\"])} for r in con.execute(\"SELECT * FROM products\")]\n        con.close()\n        self.reply(200, rows)\n\n    def do_POST(self):\n        self.rid = self.headers.get(\"X-Request-Id\") or uuid.uuid4().hex[:8]\n        req = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        try:\n            self.reply(*orders_place(self.rid, req[\"sku\"], req[\"qty\"], req[\"card\"]))\n        except OSError:\n            self.reply(503, {\"error\": \"stock unavailable\"})\n\n    def log_message(self, fmt, *args):\n        print(f\"shop  [{getattr(self, 'rid', '-')}] {fmt % args}\", flush=True)\n\n\nif __name__ == \"__main__\":\n    con = db()\n    con.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS products (sku TEXT PRIMARY KEY, name TEXT, price_cents INTEGER);\n    CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, sku TEXT, qty INTEGER, total_cents INTEGER);\n    CREATE TABLE IF NOT EXISTS payments (order_id INTEGER, card TEXT, amount_cents INTEGER);\n    \"\"\")\n    with con:\n        con.executemany(\"INSERT OR IGNORE INTO products VALUES (?, ?, ?)\", PRODUCTS)\n    con.close()\n    print(\"shop listening on :8000\", flush=True)\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "Each request gets an id here, at the edge, unless the caller sent one. The catalogue needs the units, so listing products is now a call to the stock service as well."}]}
```

`shop/Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "shop/Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"shop.py\"]", "note": "The same three lines as lesson 1's, for one program each; every .py file in the directory goes into the image."}]}
```

`shop/bench.py` is a small measurement that the next section runs. Save it now, so that it is in the
image:

```schooling-example
{"language": "python", "file": "shop/bench.py", "parts": [{"code": "\"\"\"How long does asking another service take, against asking yourself?\"\"\"\nimport os, time, urllib.request\n\nSTOCK = os.environ.get(\"STOCK_URL\", \"http://stock:8001\")\nN = 1000\nunits = {\"coffee\": 12}\n\n\ndef local(sku):\n    return units[sku]\n\n\ndef remote(sku):\n    with urllib.request.urlopen(f\"{STOCK}/stock/{sku}\") as r:\n        return r.read()\n\n", "note": "A thousand reads of one stock count, done twice: as a function call on a dictionary in this process, and as an HTTP request to the stock service. Each request opens a new connection, as `urllib` does by default."}, {"code": "for name, fn in ((\"function call\", local), (\"HTTP call\", remote)):\n    start = time.perf_counter()\n    for _ in range(N):\n        fn(\"coffee\")\n    per_call = (time.perf_counter() - start) / N * 1e6\n    print(f\"{name:14} {per_call:10.2f} µs per call\")", "note": "The result is printed in microseconds per call, the average over the thousand."}]}
```

## The compose file

`compose.yaml`, in `~/lab/split` itself:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  shop:\n    build: ./shop\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    environment:\n      STOCK_URL: http://stock:8001\n    volumes:\n      - shop-data:/data\n    depends_on:\n      - stock\n  stock:\n    build: ./stock\n    volumes:\n      - stock-data:/data\nvolumes:\n  shop-data:\n  stock-data:", "note": "Two services, two volumes, two databases. Only the shop publishes a port; the stock service is reachable from the shop by its name, `stock`, on the network Compose makes for the project, and from nowhere else."}]}
```

## Running it

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

The catalogue still lists five products with their units, and those units now come from another
program:

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

**Every request carries an id from the edge inward.** The shop gives each request one, or keeps the
one the caller sent, and passes it to the stock service in the `X-Request-Id` header; both write it
at the start of every log line. Sending a recognisable id makes one order easy to follow through
both logs:

```
ana@vm:~/lab/split$ curl -s -H 'X-Request-Id: order-1' -X POST localhost:8000/orders -d '{"sku": "tomato", "qty": 3, "card": "4111111111111111"}'
{"order": 1, "sku": "tomato", "qty": 3, "total_cents": 2697}
ana@vm:~/lab/split$ docker compose logs --no-log-prefix | grep order-1
stock [order-1] "POST /stock/tomato/take HTTP/1.1" 200 -
shop  [order-1] "POST /orders HTTP/1.1" 201 -
```

Two services each logged their half of the same order, and the id is what joins them. With two
services you could do without it. With twenty, and a hundred requests a second, it is the only
way to know which line in one log belongs with which line in another, and `scale` lesson 7 builds
the full version of it, a trace.
