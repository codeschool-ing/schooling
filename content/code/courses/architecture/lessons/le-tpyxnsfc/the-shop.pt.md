---
title: A Quitanda, como um programa só
version: 1
---

A loja começa como um **monólito**: um programa, construído numa imagem, rodando como um processo,
com um banco de dados. Isso não é uma fase da qual ela não conseguiu sair. É o formato que quase todo
sistema tem no primeiro dia, e muitos ficam com ele para sempre.

Crie o diretório da aula e entre nele:

```sh
mkdir -p ~/lab/monolith && cd ~/lab/monolith
```

Depois salve três arquivos ali. Copie cada um com o botão no canto e cole num editor; `nano app.py`
abre um, `Ctrl+O` salva e `Ctrl+X` sai.

`app.py`, a loja. Está escrita em Python porque Python se lê perto do inglês comum, e não usa nada
fora da biblioteca padrão. **Você não precisa saber Python neste curso**: as notas ao lado do código
dizem o que cada parte faz, e cada ideia dele é a mesma em Java, Go ou JavaScript.

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"Quitanda, a grocery shop, as one program.\"\"\"\nimport json, os, sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nDB = os.environ.get(\"QUITANDA_DB\", \"/data/quitanda.db\")", "note": "A loja inteira é um programa só: a biblioteca padrão do Python e um arquivo SQLite, nada para instalar. Cada parte abaixo é um módulo da loja, separado por convenção e por nada mais forte."}, {"code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS products (sku TEXT PRIMARY KEY, name TEXT, price_cents INTEGER);\nCREATE TABLE IF NOT EXISTS stock (sku TEXT PRIMARY KEY, units INTEGER CHECK (units >= 0));\nCREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, sku TEXT, qty INTEGER, total_cents INTEGER);\nCREATE TABLE IF NOT EXISTS payments (order_id INTEGER, card TEXT, amount_cents INTEGER);\n\"\"\"\nPRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899, 40), (\"banana\", \"Bananas, 1 kg\", 649, 25),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290, 12), (\"cheese\", \"Minas cheese, 500 g\", 2450, 8),\n            (\"bread\", \"Bread rolls, 6\", 990, 30)]\n\n\ndef db():\n    con = sqlite3.connect(DB)\n    con.row_factory = sqlite3.Row\n    return con\n\n", "note": "Um banco para todos os módulos. O esquema e os cinco produtos são criados na primeira partida."}, {"code": "def catalogue_list(con):\n    rows = con.execute(\"SELECT p.sku, p.name, p.price_cents, s.units FROM products p JOIN stock s USING (sku)\")\n    return [dict(r) for r in rows]\n\n", "note": "O módulo de catálogo: o que está à venda e por quanto."}, {"code": "def stock_take(con, sku, qty):\n    con.execute(\"UPDATE stock SET units = units - ? WHERE sku = ?\", (qty, sku))\n\n", "note": "O módulo de estoque. O CHECK da tabela recusa uma contagem negativa, então tirar mais do que existe levanta um erro em vez de vender o que a loja não tem."}, {"code": "class Declined(Exception):\n    pass\n\n\ndef payments_charge(con, order_id, card, amount):\n    if card.endswith(\"0002\"):\n        raise Declined(\"card declined\")\n    con.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (order_id, card[-4:], amount))\n\n", "note": "O módulo de pagamentos faz as vezes de uma operadora de cartão: um cartão terminado em 0002 é recusado, qualquer outro é aceito."}, {"code": "def orders_place(sku, qty, card):\n    con = db()\n    try:\n        with con:\n            price = con.execute(\"SELECT price_cents FROM products WHERE sku = ?\", (sku,)).fetchone()[0]\n            total = price * qty\n            cur = con.execute(\"INSERT INTO orders (sku, qty, total_cents) VALUES (?, ?, ?)\", (sku, qty, total))\n            stock_take(con, sku, qty)\n            payments_charge(con, cur.lastrowid, card, total)\n            return {\"order\": cur.lastrowid, \"sku\": sku, \"qty\": qty, \"total_cents\": total}\n    finally:\n        con.close()\n\n", "note": "O módulo de pedidos chama os outros três, e tudo acontece dentro de UMA transação: `with con` confirma se o bloco termina e desfaz tudo se qualquer coisa dentro dele levantar um erro."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        if isinstance(body, list):  # one item per line, easier to read in a terminal\n            text = \"[\\n\" + \",\\n\".join(json.dumps(x) for x in body) + \"\\n]\"\n        else:\n            text = json.dumps(body)\n        data = (text + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        con = db()\n        if self.path == \"/products\":\n            self.reply(200, catalogue_list(con))\n        elif self.path == \"/orders\":\n            self.reply(200, [dict(r) for r in con.execute(\"SELECT * FROM orders\")])\n        else:\n            self.reply(404, {\"error\": \"not found\"})\n        con.close()\n\n    def do_POST(self):\n        if self.path != \"/orders\":\n            return self.reply(404, {\"error\": \"not found\"})\n        req = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        try:\n            self.reply(201, orders_place(req[\"sku\"], req[\"qty\"], req[\"card\"]))\n        except Declined as e:\n            self.reply(402, {\"error\": str(e)})\n        except sqlite3.IntegrityError:\n            self.reply(409, {\"error\": \"not enough stock\"})\n\n", "note": "HTTP na frente: três rotas, JSON na entrada e na saída, e um processo só respondendo a todas."}, {"code": "if __name__ == \"__main__\":\n    con = db()\n    con.executescript(SCHEMA)\n    if not con.execute(\"SELECT 1 FROM products\").fetchone():\n        with con:\n            for sku, name, price, units in PRODUCTS:\n                con.execute(\"INSERT INTO products VALUES (?, ?, ?)\", (sku, name, price))\n                con.execute(\"INSERT INTO stock VALUES (?, ?)\", (sku, units))\n    con.close()\n    print(\"quitanda listening on :8000\", flush=True)\n    ThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "Ao iniciar: cria as tabelas, cadastra os produtos se a loja estiver vazia e escuta na porta 8000."}]}
```

`Dockerfile`, que transforma o programa numa imagem:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY app.py .\nCMD [\"python\", \"app.py\"]", "note": "A imagem: a imagem oficial do Python e o arquivo único. Nada é instalado."}]}
```

E `compose.yaml`, que diz como rodá-lo:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  shop:\n    build: .\n    ports:\n      - \"127.0.0.1:8000:8000\"\n    volumes:\n      - data:/data\nvolumes:\n  data:", "note": "Um serviço, a loja inteira. O volume nomeado guarda o arquivo SQLite quando o contêiner é substituído, e a porta 8000 é publicada só no loopback da própria máquina."}]}
```

## Iniciando

`docker compose up -d --build --quiet-build` constrói a imagem, cria o volume e inicia o contêiner
em segundo plano, e `--quiet-build` tira da tela a lista de passos do próprio build.
`docker compose ps` mostra o contêiner rodando:

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

Num terminal o Compose desenha esses eventos como uma lista que se atualiza no lugar; a transcrição
é o que ele imprime quando a saída vai para qualquer outro lugar, uma linha por evento, algumas
repetidas.

O catálogo, cinco produtos com os preços em centavos e as unidades em estoque:

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

**Dinheiro fica em centavos inteiros**, nunca num número de ponto flutuante, que não representa
exatamente a maior parte das frações decimais: `0.1 + 0.2` dá `0.30000000000000004` em quase toda
linguagem. Um preço de R$ 32,90 é `3290`.

Um pedido de dois pacotes de café, pago com um cartão que a operadora de mentira aceita:

```
ana@vm:~/lab/monolith$ curl -s -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 2, "card": "4111111111111111"}'
{"order": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
```

O pedido voltou com o número e um total de `6580`, duas vezes `3290`. Cada requisição que o processo
atendeu está no log dele, que `docker compose logs` mostra:

```
ana@vm:~/lab/monolith$ docker compose logs shop
shop-1  | quitanda listening on :8000
shop-1  | 172.18.0.1 - - [10/Oct/2026 04:10:24] "GET /products HTTP/1.1" 200 -
shop-1  | 172.18.0.1 - - [10/Oct/2026 04:10:24] "POST /orders HTTP/1.1" 201 -
```

**Um processo atendeu tudo isso.** O catálogo, o estoque, o pagamento e o pedido foram quatro chamadas
de função dentro do mesmo programa, cada uma levando nanossegundos, sem rede entre elas. A próxima
seção mostra a propriedade que decorre disso, e a aula 2 o que custa abrir mão dela.
