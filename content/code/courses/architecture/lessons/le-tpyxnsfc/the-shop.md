---
title: Quitanda, as one program
version: 1
---

The shop starts as a **monolith**: one program, built into one image, run as one process, with one
database. That is not a stage it has failed to grow out of. It is the shape almost every system
has on its first day, and many keep it for good.

Make the lesson's directory and go into it:

```sh
mkdir -p ~/lab/monolith && cd ~/lab/monolith
```

Then save three files there. Copy each one with the button in its corner and paste it into an
editor; `nano app.py` opens one, `Ctrl+O` saves and `Ctrl+X` leaves.

`app.py`, the shop. It is written in Python because Python reads close to plain English, and it
uses nothing outside the standard library. **You do not need to know Python for this course**: the
notes beside the code say what each part does, and every idea in it is the same in Java, Go or
JavaScript.

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"Quitanda, a grocery shop, as one program.\"\"\"\nimport json, os, sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"QUITANDA_DB\", \"/data/quitanda.db\")", "note": "The whole shop is one program: Python's standard library and an SQLite file, nothing to install. Each section below is a module of the shop, kept apart by convention and nothing stronger."}, {"code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS products (sku TEXT PRIMARY KEY, name TEXT, price_cents INTEGER);\nCREATE TABLE IF NOT EXISTS stock (sku TEXT PRIMARY KEY, units INTEGER CHECK (units >= 0));\nCREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, sku TEXT, qty INTEGER, total_cents INTEGER);\nCREATE TABLE IF NOT EXISTS payments (order_id INTEGER, card TEXT, amount_cents INTEGER);\n\"\"\"\nPRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899, 40), (\"banana\", \"Bananas, 1 kg\", 649, 25),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290, 12), (\"cheese\", \"Minas cheese, 500 g\", 2450, 8),\n            (\"bread\", \"Bread rolls, 6\", 990, 30)]\n\n\ndef db():\n    con = sqlite3.connect(DB)\n    con.row_factory = sqlite3.Row\n    return con\n\n", "note": "One database for every module. Its schema and the five products are created on the first start."}, {"code": "def catalogue_list(con):\n    rows = con.execute(\"SELECT p.sku, p.name, p.price_cents, s.units FROM products p JOIN stock s USING (sku)\")\n    return [dict(r) for r in rows]\n\n", "note": "The catalogue module: what is for sale and at what price."}, {"code": "def stock_take(con, sku, qty):\n    con.execute(\"UPDATE stock SET units = units - ? WHERE sku = ?\", (qty, sku))\n\n", "note": "The stock module. The CHECK on the table refuses a negative count, so taking more than there is raises an error instead of selling what the shop does not have."}, {"code": "class Declined(Exception):\n    pass\n\n\ndef payments_charge(con, order_id, card, amount):\n    if card.endswith(\"0002\"):\n        raise Declined(\"card declined\")\n    con.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (order_id, card[-4:], amount))\n\n", "note": "The payments module stands in for a card processor: a card ending in 0002 is declined, every other one is accepted."}, {"code": "def orders_place(sku, qty, card):\n    con = db()\n    try:\n        with con:\n            price = con.execute(\"SELECT price_cents FROM products WHERE sku = ?\", (sku,)).fetchone()[0]\n            total = price * qty\n            cur = con.execute(\"INSERT INTO orders (sku, qty, total_cents) VALUES (?, ?, ?)\", (sku, qty, total))\n            stock_take(con, sku, qty)\n            payments_charge(con, cur.lastrowid, card, total)\n            return {\"order\": cur.lastrowid, \"sku\": sku, \"qty\": qty, \"total_cents\": total}\n    finally:\n        con.close()\n\n", "note": "The orders module calls the other three, and all of it happens inside ONE transaction: `with con` commits if the block ends and rolls everything back if anything in it raises."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        if isinstance(body, list):  # one item per line, easier to read in a terminal\n            text = \"[\\n\" + \",\\n\".join(json.dumps(x) for x in body) + \"\\n]\"\n        else:\n            text = json.dumps(body)\n        data = (text + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        con = db()\n        if self.path == \"/products\":\n            self.reply(200, catalogue_list(con))\n        elif self.path == \"/orders\":\n            self.reply(200, [dict(r) for r in con.execute(\"SELECT * FROM orders\")])\n        else:\n            self.reply(404, {\"error\": \"not found\"})\n        con.close()\n\n    def do_POST(self):\n        if self.path != \"/orders\":\n            return self.reply(404, {\"error\": \"not found\"})\n        req = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        try:\n            self.reply(201, orders_place(req[\"sku\"], req[\"qty\"], req[\"card\"]))\n        except Declined as e:\n            self.reply(402, {\"error\": str(e)})\n        except sqlite3.IntegrityError:\n            self.reply(409, {\"error\": \"not enough stock\"})\n\n", "note": "HTTP in front of it: three routes, JSON in and out, and one process answering all of them."}, {"code": "if __name__ == \"__main__\":\n    con = db()\n    con.executescript(SCHEMA)\n    if not con.execute(\"SELECT 1 FROM products\").fetchone():\n        with con:\n            for sku, name, price, units in PRODUCTS:\n                con.execute(\"INSERT INTO products VALUES (?, ?, ?)\", (sku, name, price))\n                con.execute(\"INSERT INTO stock VALUES (?, ?)\", (sku, units))\n    con.close()\n    print(\"quitanda listening on :8000\", flush=True)\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "On start: create the tables, add the products if the shop is empty, and listen on port 8000."}]}
```

`Dockerfile`, which turns it into an image:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY app.py .\nCMD [\"python\", \"app.py\"]", "note": "The image: the official Python image and the one file. Nothing is installed."}]}
```

And `compose.yaml`, which says how to run it:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  shop:\n    build: .\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    volumes:\n      - data:/data\nvolumes:\n  data:", "note": "One service, the whole shop. The named volume keeps the SQLite file when the container is replaced, and port 8000 is published on the machine's own loopback only."}]}
```

## Starting it

`docker compose up -d --build --quiet-build` builds the image, creates the volume and starts the
container in the background, and `--quiet-build` keeps the build's own list of steps off the screen.
`docker compose ps` shows the container running:

```
ana@vm:~/lab/monolith$ ls
Dockerfile
app.py
compose.yaml
ana@vm:~/lab/monolith$ docker compose up -d --build --quiet-build
 Image monolith-shop Building 
 Image monolith-shop Built 
 Volume monolith_data Creating 
 Network monolith_default Creating 
 Volume monolith_data Creating 
 Network monolith_default Creating 
 Volume monolith_data Created 
 Volume monolith_data Created 
 Network monolith_default Created 
 Network monolith_default Created 
 Container monolith-shop-1 Creating 
 Container monolith-shop-1 Created 
 Container monolith-shop-1 Starting 
 Container monolith-shop-1 Started 
ana@vm:~/lab/monolith$ docker compose ps
NAME              IMAGE           COMMAND           SERVICE   CREATED                  STATUS                  PORTS
monolith-shop-1   monolith-shop   "python app.py"   shop      Less than a second ago   Up Less than a second   127.0.0.1:8000->8000/tcp
```

In a terminal Compose draws those events as a list that updates in place; the transcript is what it
prints when its output goes anywhere else, one line per event, some of them twice.

The catalogue, five products with their prices in cents and the units in stock:

```
ana@vm:~/lab/monolith$ curl -s localhost:8000/products
[
{"sku": "tomato", "name": "Tomatoes, 1 kg", "price_cents": 899, "units": 40},
{"sku": "banana", "name": "Bananas, 1 kg", "price_cents": 649, "units": 25},
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 12},
{"sku": "cheese", "name": "Minas cheese, 500 g", "price_cents": 2450, "units": 8},
{"sku": "bread", "name": "Bread rolls, 6", "price_cents": 990, "units": 30}
]
```

**Money is held in integer cents**, never in a floating-point number, which cannot represent most
decimal fractions exactly: `0.1 + 0.2` is `0.30000000000000004` in nearly every language. A price
of R$ 32,90 is `3290`.

An order for two bags of coffee, paid with a card the fake processor accepts:

```
ana@vm:~/lab/monolith$ curl -s -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 2, "card": "4111111111111111"}'
{"order": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
```

The order came back with its number and a total of `6580`, two times `3290`. Every request the
process answered is in its log, which `docker compose logs` shows:

```
ana@vm:~/lab/monolith$ docker compose logs shop
shop-1  | quitanda listening on :8000
shop-1  | 172.18.0.1 - - [10/Oct/2026 04:10:24] "GET /products HTTP/1.1" 200 -
shop-1  | 172.18.0.1 - - [10/Oct/2026 04:10:24] "POST /orders HTTP/1.1" 201 -
```

**One process answered all of it.** The catalogue, the stock, the payment and the order were four
function calls inside the same program, each taking nanoseconds, with no network between them. The
next section shows the property that follows from that, and lesson 2 what it costs to give it up.
