---
title: The orders API
version: 1
---

The rest of the lesson runs against one new file, `orders.py`: the bookshop's orders, the people
who place and handle them, and every check in the figure of the first section. It keeps its tables
in `shelf.db`, beside the books, and leaves the two tables `rest.py` uses alone.

**Authentication here is deliberately fake.** Six tokens are written into the file, one per person
and one more for an app, so that this lesson can be about what happens after a token has been
checked. Lessons 7 and 8 are how a real one is issued and verified, and nothing in this file is a
way to do it.

Save it as `orders.py` in `~/shelf`, the same way as `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/orders.py",
  "parts": [
    {
      "code": "# shelf/orders.py\n\"\"\"The bookshop's orders, and who may do what with them.\n\nRun it with `python3 orders.py` after stopping rest.py: both use port 8000.\n\"\"\"\nimport json\nimport re\nfrom datetime import date, timedelta\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Standard library and `db.py` again, like `rest.py`. The orders live in the same `shelf.db`, beside the books, so an order can point at a book that exists."
    },
    {
      "code": "\nROLES = {\n    \"customer\": {\"orders:read\", \"orders:create\", \"orders:cancel\"},\n    \"staff\": {\"orders:read\", \"orders:read_all\", \"orders:refund\"},\n    \"admin\": {\"orders:read\", \"orders:read_all\", \"orders:refund\", \"people:read\"},\n}",
      "note": "The **role to permission table**, and the only place a role means anything. Nothing below asks what role somebody has; it asks whether a permission is in their set."
    },
    {
      "code": "\n# Fixed demo tokens: who each one belongs to, and the scopes it carries.\n# Lessons 7 and 8 are how a real token is issued and checked.\nTOKENS = {\n    \"demo-ana\": (\"ana\", {\"orders:read\", \"orders:create\", \"orders:cancel\"}),\n    \"demo-ana-app\": (\"ana\", {\"orders:read\"}),\n    \"demo-bruno\": (\"bruno\", {\"orders:read\", \"orders:create\", \"orders:cancel\", \"orders:refund\"}),\n    \"demo-carla\": (\"carla\", {\"orders:read\", \"orders:read_all\", \"orders:refund\"}),\n    \"demo-dora\": (\"dora\", {\"orders:read\", \"orders:read_all\", \"orders:refund\", \"people:read\"}),\n    \"demo-eva\": (\"eva\", {\"orders:read\"}),\n}",
      "note": "Six fixed tokens, so this lesson can be about what happens after the token is checked. Each says whose it is and which **scopes** it carries. `demo-ana-app` is the token Ana gave an app that only reads her orders; `demo-bruno` claims `orders:refund`, which his role does not have."
    },
    {
      "code": "\nREFUND_DAYS = 30\n\nSCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS people (\n    name TEXT PRIMARY KEY,\n    role TEXT NOT NULL\n);\nCREATE TABLE IF NOT EXISTS orders (\n    id          INTEGER PRIMARY KEY,\n    customer    TEXT NOT NULL REFERENCES people (name),\n    book_id     INTEGER NOT NULL REFERENCES books (id),\n    quantity    INTEGER NOT NULL CHECK (quantity > 0),\n    total_cents INTEGER NOT NULL,\n    status      TEXT NOT NULL,\n    placed_on   TEXT NOT NULL,\n    note        TEXT NOT NULL DEFAULT ''\n);\n\"\"\"\n\n\ndef setup():\n    \"\"\"Create the two tables and put the same people and orders in them.\"\"\"\n    def ago(days):\n        return str(date.today() - timedelta(days=days))\n    with db.connect() as conn:\n        conn.executescript(SCHEMA)\n        conn.executemany(\"INSERT OR IGNORE INTO people VALUES (?, ?)\", [\n            (\"ana\", \"customer\"), (\"bruno\", \"customer\"), (\"carla\", \"staff\"),\n            (\"dora\", \"admin\"), (\"eva\", \"auditor\")])\n        conn.executemany(\"INSERT OR IGNORE INTO orders VALUES (?, ?, ?, ?, ?, ?, ?, ?)\", [\n            (1, \"ana\", 1, 1, 3990, \"placed\", ago(2), \"gift wrap\"),\n            (2, \"ana\", 5, 2, 11980, \"shipped\", ago(10), \"\"),\n            (3, \"bruno\", 6, 1, 6490, \"placed\", ago(1), \"phoned: new address\"),\n            (4, \"bruno\", 2, 1, 4490, \"shipped\", ago(45), \"\")])",
      "note": "Two tables, created only if they are missing, and the same five people and four orders on every start. Eva's role is `auditor`, which the table above never mentions. The order dates are counted back from today, so order 4 is always 45 days old."
    },
    {
      "code": "\n\ndef show(order, perms):\n    \"\"\"What a caller sees of an order. The note is for the shop's eyes only.\"\"\"\n    v = {k: order[k] for k in (\"id\", \"customer\", \"book_id\", \"quantity\", \"total_cents\",\n                               \"status\", \"placed_on\")}\n    if \"orders:read_all\" in perms:\n        v[\"note\"] = order[\"note\"]\n    return v",
      "note": "The representation decides which **properties** a caller sees. A customer never receives `note`, whatever the database holds."
    },
    {
      "code": "\n\ndef find(conn, ident, me, perms):\n    \"\"\"The order, if it exists and this caller may see it; None in both other cases.\"\"\"\n    order = conn.execute(\"SELECT * FROM orders WHERE id = ?\", (ident,)).fetchone()\n    if order is None:\n        return None\n    if order[\"customer\"] != me and \"orders:read_all\" not in perms:\n        return None\n    return order",
      "note": "The **ownership check**, written once. Every handler that takes an order id goes through `find`, and an order that is somebody else's comes back as `None`, exactly like one that does not exist."
    },
    {
      "code": "\n\nROUTES = [\n    (\"GET\", r\"/orders\", \"orders:read\", \"list_orders\"),\n    (\"POST\", r\"/orders\", \"orders:create\", \"create_order\"),\n    (\"GET\", r\"/orders/(\\d+)\", \"orders:read\", \"get_order\"),\n    (\"POST\", r\"/orders/(\\d+)/cancel\", \"orders:cancel\", \"cancel_order\"),\n    (\"POST\", r\"/orders/(\\d+)/refund\", \"orders:refund\", \"refund_order\"),\n    (\"GET\", r\"/admin/people\", \"people:read\", \"list_people\"),\n]",
      "note": "Every address the API has, each with the one permission it needs. A route is not callable without naming one, and a request that matches no row is refused before any code runs."
    },
    {
      "code": "\n\nclass Orders(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)",
      "note": "Reading the whole request first and answering in JSON, the same as `rest.py` does."
    },
    {
      "code": "\n    def caller(self):\n        \"\"\"(name, role, permissions) for the request's token, or None after a 401.\"\"\"\n        auth = self.headers.get(\"Authorization\", \"\")\n        token = auth[len(\"Bearer \"):] if auth.startswith(\"Bearer \") else None\n        if token not in TOKENS:\n            self.error(401, \"send a valid token: Authorization: Bearer <token>\",\n                       [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\"')])\n            return None\n        name, scopes = TOKENS[token]\n        with db.connect() as conn:\n            role = conn.execute(\"SELECT role FROM people WHERE name = ?\", (name,)).fetchone()[0]\n        return name, role, ROLES.get(role, set()) & scopes",
      "note": "**Authentication**: who is asking. No token, or one this API never issued, is a **401** with `WWW-Authenticate`. The effective permissions are what the role grants AND the token carries: a set intersection, `&`, and an unknown role grants the empty set."
    },
    {
      "code": "\n    def dispatch(self):\n        who = self.caller()\n        if who is None:\n            return\n        path = self.path.split(\"?\")[0]\n        matches = [(r, re.fullmatch(r[1], path)) for r in ROUTES]\n        matches = [(r, m) for r, m in matches if m]\n        if not matches:\n            return self.error(404, \"no such resource\")\n        hit = [(r, m) for r, m in matches if r[0] == self.command]\n        if not hit:\n            allow = \", \".join(r[0] for r, m in matches)\n            return self.error(405, f\"{self.command} is not allowed here\", [(\"Allow\", allow)])\n        (method, pattern, need, handler), m = hit[0]\n        name, role, perms = who\n        if need not in perms:\n            if need in ROLES.get(role, set()):\n                return self.error(403, f\"this token's scope lacks {need}\", [(\n                    \"WWW-Authenticate\", f'Bearer error=\"insufficient_scope\", scope=\"{need}\"')])\n            return self.error(403, f\"the role {role} lacks {need}\")\n        getattr(self, handler)(name, perms, *m.groups())\n\n    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = dispatch",
      "note": "The **one place** every request passes through: who, then which route, then whether the permission is in the set. A 403 says which half refused, the role or the token's scope. GET, POST, PUT, PATCH and DELETE all end here, so one with no route at that address gets 405 rather than a page from the library."
    },
    {
      "code": "\n    def list_orders(self, me, perms):\n        with db.connect() as conn:\n            if \"orders:read_all\" in perms:\n                rows = conn.execute(\"SELECT * FROM orders ORDER BY id\").fetchall()\n            else:\n                rows = conn.execute(\"SELECT * FROM orders WHERE customer = ? ORDER BY id\",\n                                    (me,)).fetchall()\n        self.reply(200, [show(row, perms) for row in rows])\n\n    def get_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n        if order is None:\n            return self.error(404, f\"no order {ident}\")\n        self.reply(200, show(order, perms))",
      "note": "Listing filters in SQL: a customer's query names the customer, so somebody else's order is never read at all."
    },
    {
      "code": "\n    def create_order(self, me, perms):\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            value = None\n        if not isinstance(value, dict):\n            return self.error(400, \"send a JSON object\")\n        extra = sorted(set(value) - {\"book_id\", \"quantity\"})\n        if extra:\n            return self.error(422, f\"fields you may not set: {', '.join(extra)}\")\n        book_id, quantity = value.get(\"book_id\"), value.get(\"quantity\")\n        if type(book_id) is not int or type(quantity) is not int or quantity < 1:\n            return self.error(422, \"book_id and quantity must be whole numbers above 0\")\n        with db.connect() as conn:\n            book = conn.execute(\"SELECT price_cents FROM books WHERE id = ?\",\n                                (book_id,)).fetchone()\n            if book is None:\n                return self.error(422, f\"no book {book_id}\")\n            ident = conn.execute(\n                \"INSERT INTO orders (customer, book_id, quantity, total_cents, status, placed_on)\"\n                \" VALUES (?, ?, ?, ?, 'placed', ?)\",\n                (me, book_id, quantity, book[0] * quantity, str(date.today()))).lastrowid\n            order = find(conn, ident, me, perms)\n        self.reply(201, show(order, perms), [(\"Location\", f\"/orders/{ident}\")])",
      "note": "Creating an order accepts **two fields and no more**. The customer, the total, the status and the date are the server's to decide, and a body naming any of them is refused rather than half obeyed."
    },
    {
      "code": "\n    def cancel_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n            if order is None:\n                return self.error(404, f\"no order {ident}\")\n            if order[\"status\"] != \"placed\":\n                return self.error(409, f\"order {ident} is {order['status']}; \"\n                                       \"only a placed order can be cancelled\")\n            conn.execute(\"UPDATE orders SET status = 'cancelled' WHERE id = ?\", (ident,))\n            order = find(conn, int(ident), me, perms)\n        self.reply(200, show(order, perms))",
      "note": "Cancelling goes through `find` like reading does, so a customer cannot cancel what they cannot see."
    },
    {
      "code": "\n    def refund_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n            if order is None:\n                return self.error(404, f\"no order {ident}\")\n            if order[\"status\"] not in (\"placed\", \"shipped\"):\n                return self.error(409, f\"order {ident} is {order['status']}\")\n            age = (date.today() - date.fromisoformat(order[\"placed_on\"])).days\n            if age > REFUND_DAYS:\n                return self.error(403, f\"refunds close {REFUND_DAYS} days after an order; \"\n                                       f\"order {ident} is {age} days old\")\n            conn.execute(\"UPDATE orders SET status = 'refunded' WHERE id = ?\", (ident,))\n            order = find(conn, int(ident), me, perms)\n        self.reply(200, show(order, perms))",
      "note": "The **attribute rule**. Having `orders:refund` lets you ask; whether this order may be refunded depends on its age, which no role can know."
    },
    {
      "code": "\n    def list_people(self, me, perms):\n        with db.connect() as conn:\n            rows = conn.execute(\"SELECT name, role FROM people ORDER BY name\").fetchall()\n        self.reply(200, [dict(row) for row in rows])",
      "note": "The administrative function. Its address starts with `/admin`, and that protects nothing: `people:read` in the route table does."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    setup()\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Orders)\n    print(\"orders on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "Creates the tables before the first request, and listens on 127.0.0.1:8000, the port `rest.py` uses."
    }
  ]
}
```

## Running it

`orders.py` listens on port 8000 like `rest.py`, so the two cannot run at once. In the second
terminal, stop `rest.py` with `Ctrl+C` and start the new file:

```sh
python3 orders.py
```

It prints one line and waits:

```
orders on http://127.0.0.1:8000
```

The first request carries no token, and it is refused before anything else is looked at:

```
ana@api:~/shelf$ curl -si localhost:8000/orders
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:56 GMT
Content-Type: application/json
Content-Length: 63
WWW-Authenticate: Bearer realm="shelf"

{"error": "send a valid token: Authorization: Bearer <token>"}
```

**A 401 comes with `WWW-Authenticate`**, the header that tells the client what kind of credential
would do, here a bearer token. With Ana's token the same address answers, and it answers with Ana's
orders only:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders | jq -c '.[]'
{"id":1,"customer":"ana","book_id":1,"quantity":1,"total_cents":3990,"status":"placed","placed_on":"2026-10-08"}
{"id":2,"customer":"ana","book_id":5,"quantity":2,"total_cents":11980,"status":"shipped","placed_on":"2026-09-30"}
```

`setup()` added two tables to `shelf.db` and put five people in one of them:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM people'
ana|customer
bruno|customer
carla|staff
dora|admin
eva|auditor
```

Eva's role is `auditor`, which `ROLES` does not mention. Deny by default says she gets nothing, and
she gets nothing. A token nobody issued, and a request for an address that does not exist, are
refused too, each at its own gate:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-eva' localhost:8000/orders
{"error": "the role auditor lacks orders:read"}
403
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-nobody' localhost:8000/orders
{"error": "send a valid token: Authorization: Bearer <token>"}
401
ana@api:~/shelf$ curl -s -w '%{http_code}\n' localhost:8000/no/such/thing
{"error": "send a valid token: Authorization: Bearer <token>"}
401
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-ana' localhost:8000/no/such/thing
{"error": "no such resource"}
404
```

**Without a token, an address that does not exist answers 401, exactly like one that does.** Who is
asking is the first question, so a stranger learns nothing about which addresses are real. With
Ana's token the same address is a 404.

The dates in `placed_on` are counted back from the day the server first started, so yours differ
from these. The ages are the same for everybody, and the ages are what the refund rule reads. To go
back to the four orders as they started, stop the server, delete `shelf.db` and start it again, as
in lesson 1.
