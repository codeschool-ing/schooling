---
title: A API de pedidos
version: 1
---

O resto da aula roda sobre um arquivo novo, o `orders.py`: os pedidos da livraria, as pessoas que
fazem e cuidam deles, e todas as checagens da figura da primeira seção. Ele guarda as tabelas dele
no `shelf.db`, ao lado dos livros, e não mexe nas duas tabelas que o `rest.py` usa.

**A autenticação aqui é falsa de propósito.** Seis tokens estão escritos no arquivo, um por pessoa e
mais um para um aplicativo, para que esta aula possa tratar do que acontece depois que um token foi
conferido. As aulas 7 e 8 mostram como um token de verdade é emitido e verificado, e nada neste
arquivo é um jeito de fazer isso.

Salve como `orders.py` em `~/shelf`, do mesmo jeito que o `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/orders.py",
  "parts": [
    {
      "code": "# shelf/orders.py\n\"\"\"The bookshop's orders, and who may do what with them.\n\nRun it with `python3 orders.py` after stopping rest.py: both use port 8000.\n\"\"\"\nimport json\nimport re\nfrom datetime import date, timedelta\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Biblioteca padrão e `db.py` de novo, como no `rest.py`. Os pedidos ficam no mesmo `shelf.db`, ao lado dos livros, para que um pedido aponte para um livro que existe."
    },
    {
      "code": "\nROLES = {\n    \"customer\": {\"orders:read\", \"orders:create\", \"orders:cancel\"},\n    \"staff\": {\"orders:read\", \"orders:read_all\", \"orders:refund\"},\n    \"admin\": {\"orders:read\", \"orders:read_all\", \"orders:refund\", \"people:read\"},\n}",
      "note": "A **tabela de papel para permissão**, e o único lugar em que um papel significa alguma coisa. Nada abaixo pergunta qual é o papel de alguém; pergunta se uma permissão está no conjunto dele."
    },
    {
      "code": "\n# Fixed demo tokens: who each one belongs to, and the scopes it carries.\n# Lessons 7 and 8 are how a real token is issued and checked.\nTOKENS = {\n    \"demo-ana\": (\"ana\", {\"orders:read\", \"orders:create\", \"orders:cancel\"}),\n    \"demo-ana-app\": (\"ana\", {\"orders:read\"}),\n    \"demo-bruno\": (\"bruno\", {\"orders:read\", \"orders:create\", \"orders:cancel\", \"orders:refund\"}),\n    \"demo-carla\": (\"carla\", {\"orders:read\", \"orders:read_all\", \"orders:refund\"}),\n    \"demo-dora\": (\"dora\", {\"orders:read\", \"orders:read_all\", \"orders:refund\", \"people:read\"}),\n    \"demo-eva\": (\"eva\", {\"orders:read\"}),\n}",
      "note": "Seis tokens fixos, para que esta aula trate do que acontece depois que o token é conferido. Cada um diz de quem é e quais **escopos** carrega. `demo-ana-app` é o token que a Ana deu a um aplicativo que só lê os pedidos dela; `demo-bruno` alega `orders:refund`, que o papel dele não tem."
    },
    {
      "code": "\nREFUND_DAYS = 30\n\nSCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS people (\n    name TEXT PRIMARY KEY,\n    role TEXT NOT NULL\n);\nCREATE TABLE IF NOT EXISTS orders (\n    id          INTEGER PRIMARY KEY,\n    customer    TEXT NOT NULL REFERENCES people (name),\n    book_id     INTEGER NOT NULL REFERENCES books (id),\n    quantity    INTEGER NOT NULL CHECK (quantity > 0),\n    total_cents INTEGER NOT NULL,\n    status      TEXT NOT NULL,\n    placed_on   TEXT NOT NULL,\n    note        TEXT NOT NULL DEFAULT ''\n);\n\"\"\"\n\n\ndef setup():\n    \"\"\"Create the two tables and put the same people and orders in them.\"\"\"\n    def ago(days):\n        return str(date.today() - timedelta(days=days))\n    with db.connect() as conn:\n        conn.executescript(SCHEMA)\n        conn.executemany(\"INSERT OR IGNORE INTO people VALUES (?, ?)\", [\n            (\"ana\", \"customer\"), (\"bruno\", \"customer\"), (\"carla\", \"staff\"),\n            (\"dora\", \"admin\"), (\"eva\", \"auditor\")])\n        conn.executemany(\"INSERT OR IGNORE INTO orders VALUES (?, ?, ?, ?, ?, ?, ?, ?)\", [\n            (1, \"ana\", 1, 1, 3990, \"placed\", ago(2), \"gift wrap\"),\n            (2, \"ana\", 5, 2, 11980, \"shipped\", ago(10), \"\"),\n            (3, \"bruno\", 6, 1, 6490, \"placed\", ago(1), \"phoned: new address\"),\n            (4, \"bruno\", 2, 1, 4490, \"shipped\", ago(45), \"\")])",
      "note": "Duas tabelas, criadas só se faltarem, e as mesmas cinco pessoas e quatro pedidos a cada início. O papel da Eva é `auditor`, que a tabela acima nunca menciona. As datas dos pedidos são contadas a partir de hoje, então o pedido 4 sempre tem 45 dias."
    },
    {
      "code": "\n\ndef show(order, perms):\n    \"\"\"What a caller sees of an order. The note is for the shop's eyes only.\"\"\"\n    v = {k: order[k] for k in (\"id\", \"customer\", \"book_id\", \"quantity\", \"total_cents\",\n                               \"status\", \"placed_on\")}\n    if \"orders:read_all\" in perms:\n        v[\"note\"] = order[\"note\"]\n    return v",
      "note": "A representação decide quais **propriedades** quem chama enxerga. Um cliente nunca recebe `note`, seja o que for que o banco guarde."
    },
    {
      "code": "\n\ndef find(conn, ident, me, perms):\n    \"\"\"The order, if it exists and this caller may see it; None in both other cases.\"\"\"\n    order = conn.execute(\"SELECT * FROM orders WHERE id = ?\", (ident,)).fetchone()\n    if order is None:\n        return None\n    if order[\"customer\"] != me and \"orders:read_all\" not in perms:\n        return None\n    return order",
      "note": "A **checagem de dono**, escrita uma vez. Todo handler que recebe o id de um pedido passa por `find`, e um pedido que é de outra pessoa volta como `None`, exatamente como um que não existe."
    },
    {
      "code": "\n\nROUTES = [\n    (\"GET\", r\"/orders\", \"orders:read\", \"list_orders\"),\n    (\"POST\", r\"/orders\", \"orders:create\", \"create_order\"),\n    (\"GET\", r\"/orders/(\\d+)\", \"orders:read\", \"get_order\"),\n    (\"POST\", r\"/orders/(\\d+)/cancel\", \"orders:cancel\", \"cancel_order\"),\n    (\"POST\", r\"/orders/(\\d+)/refund\", \"orders:refund\", \"refund_order\"),\n    (\"GET\", r\"/admin/people\", \"people:read\", \"list_people\"),\n]",
      "note": "Todo endereço que a API tem, cada um com a única permissão de que precisa. Uma rota não pode ser chamada sem nomear uma, e uma requisição que não casa com nenhuma linha é recusada antes de qualquer código rodar."
    },
    {
      "code": "\n\nclass Orders(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)",
      "note": "Ler a requisição inteira primeiro e responder em JSON, do mesmo jeito que o `rest.py`."
    },
    {
      "code": "\n    def caller(self):\n        \"\"\"(name, role, permissions) for the request's token, or None after a 401.\"\"\"\n        auth = self.headers.get(\"Authorization\", \"\")\n        token = auth[len(\"Bearer \"):] if auth.startswith(\"Bearer \") else None\n        if token not in TOKENS:\n            self.error(401, \"send a valid token: Authorization: Bearer <token>\",\n                       [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\"')])\n            return None\n        name, scopes = TOKENS[token]\n        with db.connect() as conn:\n            role = conn.execute(\"SELECT role FROM people WHERE name = ?\", (name,)).fetchone()[0]\n        return name, role, ROLES.get(role, set()) & scopes",
      "note": "**Autenticação**: quem está pedindo. Sem token, ou com um que esta API nunca emitiu, a resposta é **401** com `WWW-Authenticate`. As permissões efetivas são o que o papel concede E o token carrega: uma interseção de conjuntos, `&`, e um papel desconhecido concede o conjunto vazio."
    },
    {
      "code": "\n    def dispatch(self):\n        who = self.caller()\n        if who is None:\n            return\n        path = self.path.split(\"?\")[0]\n        matches = [(r, re.fullmatch(r[1], path)) for r in ROUTES]\n        matches = [(r, m) for r, m in matches if m]\n        if not matches:\n            return self.error(404, \"no such resource\")\n        hit = [(r, m) for r, m in matches if r[0] == self.command]\n        if not hit:\n            allow = \", \".join(r[0] for r, m in matches)\n            return self.error(405, f\"{self.command} is not allowed here\", [(\"Allow\", allow)])\n        (method, pattern, need, handler), m = hit[0]\n        name, role, perms = who\n        if need not in perms:\n            if need in ROLES.get(role, set()):\n                return self.error(403, f\"this token's scope lacks {need}\", [(\n                    \"WWW-Authenticate\", f'Bearer error=\"insufficient_scope\", scope=\"{need}\"')])\n            return self.error(403, f\"the role {role} lacks {need}\")\n        getattr(self, handler)(name, perms, *m.groups())\n\n    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = dispatch",
      "note": "O **único lugar** por onde toda requisição passa: quem, depois qual rota, depois se a permissão está no conjunto. Um 403 diz qual metade recusou, o papel ou o escopo do token. GET, POST, PUT, PATCH e DELETE terminam todos aqui, então um deles sem rota naquele endereço recebe 405, e não uma página da biblioteca."
    },
    {
      "code": "\n    def list_orders(self, me, perms):\n        with db.connect() as conn:\n            if \"orders:read_all\" in perms:\n                rows = conn.execute(\"SELECT * FROM orders ORDER BY id\").fetchall()\n            else:\n                rows = conn.execute(\"SELECT * FROM orders WHERE customer = ? ORDER BY id\",\n                                    (me,)).fetchall()\n        self.reply(200, [show(row, perms) for row in rows])\n\n    def get_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n        if order is None:\n            return self.error(404, f\"no order {ident}\")\n        self.reply(200, show(order, perms))",
      "note": "A listagem filtra no SQL: a consulta de um cliente nomeia o cliente, então o pedido de outra pessoa nem chega a ser lido."
    },
    {
      "code": "\n    def create_order(self, me, perms):\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            value = None\n        if not isinstance(value, dict):\n            return self.error(400, \"send a JSON object\")\n        extra = sorted(set(value) - {\"book_id\", \"quantity\"})\n        if extra:\n            return self.error(422, f\"fields you may not set: {', '.join(extra)}\")\n        book_id, quantity = value.get(\"book_id\"), value.get(\"quantity\")\n        if type(book_id) is not int or type(quantity) is not int or quantity < 1:\n            return self.error(422, \"book_id and quantity must be whole numbers above 0\")\n        with db.connect() as conn:\n            book = conn.execute(\"SELECT price_cents FROM books WHERE id = ?\",\n                                (book_id,)).fetchone()\n            if book is None:\n                return self.error(422, f\"no book {book_id}\")\n            ident = conn.execute(\n                \"INSERT INTO orders (customer, book_id, quantity, total_cents, status, placed_on)\"\n                \" VALUES (?, ?, ?, ?, 'placed', ?)\",\n                (me, book_id, quantity, book[0] * quantity, str(date.today()))).lastrowid\n            order = find(conn, ident, me, perms)\n        self.reply(201, show(order, perms), [(\"Location\", f\"/orders/{ident}\")])",
      "note": "Criar um pedido aceita **dois campos e nenhum outro**. O cliente, o total, o status e a data são decisões do servidor, e um corpo que nomeie qualquer um deles é recusado em vez de obedecido pela metade."
    },
    {
      "code": "\n    def cancel_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n            if order is None:\n                return self.error(404, f\"no order {ident}\")\n            if order[\"status\"] != \"placed\":\n                return self.error(409, f\"order {ident} is {order['status']}; \"\n                                       \"only a placed order can be cancelled\")\n            conn.execute(\"UPDATE orders SET status = 'cancelled' WHERE id = ?\", (ident,))\n            order = find(conn, int(ident), me, perms)\n        self.reply(200, show(order, perms))",
      "note": "Cancelar passa por `find` como ler passa, então um cliente não consegue cancelar o que não consegue ver."
    },
    {
      "code": "\n    def refund_order(self, me, perms, ident):\n        with db.connect() as conn:\n            order = find(conn, int(ident), me, perms)\n            if order is None:\n                return self.error(404, f\"no order {ident}\")\n            if order[\"status\"] not in (\"placed\", \"shipped\"):\n                return self.error(409, f\"order {ident} is {order['status']}\")\n            age = (date.today() - date.fromisoformat(order[\"placed_on\"])).days\n            if age > REFUND_DAYS:\n                return self.error(403, f\"refunds close {REFUND_DAYS} days after an order; \"\n                                       f\"order {ident} is {age} days old\")\n            conn.execute(\"UPDATE orders SET status = 'refunded' WHERE id = ?\", (ident,))\n            order = find(conn, int(ident), me, perms)\n        self.reply(200, show(order, perms))",
      "note": "A **regra de atributo**. Ter `orders:refund` deixa você pedir; se este pedido pode ser estornado depende da idade dele, que nenhum papel tem como saber."
    },
    {
      "code": "\n    def list_people(self, me, perms):\n        with db.connect() as conn:\n            rows = conn.execute(\"SELECT name, role FROM people ORDER BY name\").fetchall()\n        self.reply(200, [dict(row) for row in rows])",
      "note": "A função administrativa. O endereço começa com `/admin`, e isso não protege nada: quem protege é o `people:read` na tabela de rotas."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    setup()\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Orders)\n    print(\"orders on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "Cria as tabelas antes da primeira requisição e escuta em 127.0.0.1:8000, a porta que o `rest.py` usa."
    }
  ]
}
```

## Rodando

O `orders.py` escuta na porta 8000 como o `rest.py`, então os dois não rodam ao mesmo tempo. No
segundo terminal, pare o `rest.py` com `Ctrl+C` e inicie o arquivo novo:

```sh
python3 orders.py
```

Ele imprime uma linha e espera:

```
orders on http://127.0.0.1:8000
```

A primeira requisição não leva token, e é recusada antes de qualquer outra coisa ser olhada:

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

**Um 401 vem com `WWW-Authenticate`**, o cabeçalho que diz ao cliente que tipo de credencial
serviria, aqui um bearer token. Com o token da Ana o mesmo endereço responde, e responde só com os
pedidos da Ana:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders | jq -c '.[]'
{"id":1,"customer":"ana","book_id":1,"quantity":1,"total_cents":3990,"status":"placed","placed_on":"2026-10-08"}
{"id":2,"customer":"ana","book_id":5,"quantity":2,"total_cents":11980,"status":"shipped","placed_on":"2026-09-30"}
```

O `setup()` acrescentou duas tabelas ao `shelf.db` e pôs cinco pessoas numa delas:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM people'
ana|customer
bruno|customer
carla|staff
dora|admin
eva|auditor
```

O papel da Eva é `auditor`, que `ROLES` não menciona. Negar por padrão diz que ela não recebe nada,
e ela não recebe nada. Um token que ninguém emitiu, e uma requisição para um endereço que não existe,
também são recusados, cada um no seu portão:

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

**Sem token, um endereço que não existe responde 401, exatamente como um que existe.** Quem está
pedindo é a primeira pergunta, então um estranho não aprende nada sobre quais endereços são reais.
Com o token da Ana, o mesmo endereço é um 404.

As datas em `placed_on` são contadas para trás a partir do dia em que o servidor iniciou pela
primeira vez, então as suas são diferentes destas. As idades são as mesmas para todo mundo, e são as
idades que a regra de estorno lê. Para voltar aos quatro pedidos como eram no começo, pare o
servidor, apague o `shelf.db` e inicie de novo, como na aula 1.
