---
title: O catálogo
version: 1
---

**O `catalogue.py` é a API da mesma livraria escrita de novo pensando no contrato.** Ele serve os
mesmos livros do mesmo `shelf.db`, pelo `db.py`, e põe em código as decisões desta aula: os formatos
das seções anteriores, o schema, erros que um programa consegue ler, páginas, filtros e chaves de
idempotência. Ele não substitui o `rest.py`, que fica como a aula 1 o deixou; fica ao lado dele.

Ele responde na mesma porta, 8000, então só um dos dois pode rodar de cada vez. No segundo terminal,
pare o `rest.py` com `Ctrl+C`. Depois, no primeiro, abra o editor com `nano catalogue.py`, cole o
arquivo abaixo e salve. O botão de copiar leva o programa inteiro, sem as notas.

```schooling-example
{
  "language": "python",
  "file": "shelf/catalogue.py",
  "parts": [
    {
      "code": "# shelf/catalogue.py\n\"\"\"The bookshop's catalogue, with its contract written down.\n\nStop rest.py first, then run `python3 catalogue.py`; it answers on\nhttp://127.0.0.1:8000.\n\"\"\"\nimport base64\nimport hashlib\nimport json\nimport os\nimport re\nimport sqlite3\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlencode, urlsplit\n\nimport jsonschema\n\nimport db\n\nHERE = os.path.dirname(os.path.abspath(__file__))\nwith open(os.path.join(HERE, \"book.schema.json\"), encoding=\"utf-8\") as f:\n    BOOK = jsonschema.Draft202012Validator(json.load(f))",
      "note": "A biblioteca padrão de novo, mais o `jsonschema` do pacote `python3-jsonschema` do Ubuntu, que a aula 1 instalou. O schema é lido **uma vez, na partida**: um `book.schema.json` ausente ou quebrado derruba o servidor antes que ele responda a alguém, em vez de falhar no primeiro POST."
    },
    {
      "code": "\nPROBLEMS = \"https://shelf.example/problems/\"\nSORTS = {\"id\": \"id\", \"title\": \"title\", \"year\": \"year\", \"price\": \"price_cents\"}\nPARAMS = {\"author_id\", \"in_stock\", \"sort\", \"limit\", \"after\"}\nPAGE, MOST = 20, 100",
      "note": "Quatro decisões escritas como dados. Os tipos de problema compartilham um prefixo. `SORTS` é a **lista permitida** de campos de ordenação, ligando o nome público à coluna, então `price` ordena por `price_cents` e nada que o cliente digita vira parte do SQL. `PARAMS` são todos os parâmetros de query que a coleção entende. Uma página traz 20 livros, a menos que o cliente peça até 100."
    },
    {
      "code": "\nKEYS = \"\"\"CREATE TABLE IF NOT EXISTS idempotency_keys (\n    key         TEXT PRIMARY KEY,\n    fingerprint TEXT NOT NULL,\n    location    TEXT NOT NULL,\n    body        TEXT NOT NULL,\n    created_at  TEXT NOT NULL\n)\"\"\"",
      "note": "A única tabela que o `db.py` não cria. Ela guarda cada chave de idempotência com uma impressão digital do corpo que veio junto e a resposta que recebeu. O `catalogue.py` a cria na primeira vez que um livro é enviado por POST."
    },
    {
      "code": "\n\ndef book(row):\n    return {\"id\": row[\"id\"], \"isbn\": row[\"isbn\"], \"title\": row[\"title\"],\n            \"author_id\": row[\"author_id\"], \"year\": row[\"year\"],\n            \"price\": {\"amount_cents\": row[\"price_cents\"], \"currency\": \"BRL\"},\n            \"stock\": row[\"stock\"], \"in_stock\": row[\"stock\"] > 0}",
      "note": "A representação, no formato que a seção sobre nomes defende: snake_case em tudo, dinheiro em centavos inteiros **com a moeda**, e `in_stock` como booleano de verdade, calculado a partir de `stock` para que os dois nunca discordem."
    },
    {
      "code": "\n\ndef cursor(sort, row):\n    raw = json.dumps([sort, row[SORTS[sort.lstrip(\"-\")]], row[\"id\"]], ensure_ascii=False)\n    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip(\"=\")\n\n\ndef uncursor(text):\n    return json.loads(base64.urlsafe_b64decode(text + \"=\" * (-len(text) % 4)))",
      "note": "Um cursor é a ordenação, o valor da última linha para essa ordenação e o id da última linha, em JSON codificado em base64 seguro para URL. Opaco quer dizer que o cliente não deve montar nem ler um. Não quer dizer secreto, e a seção sobre páginas decodifica um."
    },
    {
      "code": "\n\ndef pointer(path):\n    return \"#\" + \"\".join(\"/\" + str(p).replace(\"~\", \"~0\").replace(\"/\", \"~1\") for p in path)",
      "note": "Transforma o caminho que o `jsonschema` informa, como `price` e depois `amount_cents`, num JSON Pointer, `#/price/amount_cents`. As duas substituições são os escapes da RFC 6901 para um `~` ou uma `/` dentro do nome de um campo."
    },
    {
      "code": "\n\nclass Catalogue(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value, headers=(), kind=\"application/json\"):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "Ler a requisição inteira primeiro e mandar toda resposta por `reply` funcionam como no `rest.py`. Agora `reply` recebe o tipo de mídia, porque os erros saem com outro."
    },
    {
      "code": "\n    def problem(self, status, kind, title, detail, headers=(), **extra):\n        value = {\"type\": PROBLEMS + kind if kind else \"about:blank\", \"title\": title,\n                 \"status\": status, \"detail\": detail, \"instance\": urlsplit(self.path).path, **extra}\n        self.reply(status, value, headers, \"application/problem+json\")",
      "note": "**Todo erro sai por aqui**, como um problema da RFC 9457: `type`, `title`, `status`, `detail` e `instance`, mais qualquer membro de extensão, como `errors`, passado por nome. Sem um tipo próprio, o problema é `about:blank`, e o título é o nome do código de status."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        m = re.fullmatch(r\"/v1/books(?:/(\\d+))?\", url.path)\n        if not m:\n            return self.problem(404, None, \"Not Found\", f\"nothing lives at {url.path}\")\n        if m.group(1) is None:\n            return self.page({k: v[0] for k, v in parse_qs(url.query).items()})\n        with db.connect() as conn:\n            row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (int(m.group(1)),)).fetchone()\n        if row is None:\n            return self.problem(404, None, \"Not Found\", f\"there is no book {m.group(1)}\")\n        return self.reply(200, book(row))",
      "note": "Dois endereços: a coleção e um livro. Qualquer outra coisa é um 404 no mesmo formato de problema de todos os outros erros."
    },
    {
      "code": "\n    def page(self, q):\n        unknown = sorted(set(q) - PARAMS)\n        if unknown:\n            return self.problem(400, \"unknown-parameter\", \"Unknown query parameter\",\n                                f\"/v1/books does not take: {', '.join(unknown)}\")\n        sort = q.get(\"sort\", \"id\")\n        if sort.lstrip(\"-\") not in SORTS:\n            return self.problem(400, \"unsortable\", \"Cannot sort by that\",\n                                f\"sort takes {', '.join(SORTS)}, with a leading - for descending\")\n        limit = q.get(\"limit\", str(PAGE))\n        if not limit.isdigit() or not 1 <= int(limit) <= MOST:\n            return self.problem(400, \"bad-limit\", \"Page size out of range\",\n                                f\"limit is a whole number from 1 to {MOST}\")\n        limit = int(limit)",
      "note": "A query string é conferida antes de qualquer leitura. Um parâmetro desconhecido, uma ordenação fora da lista permitida e um tamanho de página fora de 1 a 100 são cada um um 400 que diz o que é aceito, então um erro de digitação num filtro nunca volta como o catálogo inteiro."
    },
    {
      "code": "        where, args = [], []\n        if \"author_id\" in q:\n            if not q[\"author_id\"].isdigit():\n                return self.problem(400, \"bad-filter\", \"Invalid filter\", \"author_id is a number\")\n            where.append(\"author_id = ?\")\n            args.append(int(q[\"author_id\"]))\n        if \"in_stock\" in q:\n            if q[\"in_stock\"] not in (\"true\", \"false\"):\n                return self.problem(400, \"bad-filter\", \"Invalid filter\", \"in_stock is true or false\")\n            where.append(\"stock > 0\" if q[\"in_stock\"] == \"true\" else \"stock = 0\")",
      "note": "Os dois filtros. Cada valor é conferido e depois **passado como parâmetro** (`?`) ou transformado numa condição fixa; nenhum é colado no SQL."
    },
    {
      "code": "        column, down = SORTS[sort.lstrip(\"-\")], sort.startswith(\"-\")\n        if \"after\" in q:\n            try:\n                was, value, ident = uncursor(q[\"after\"])\n            except (ValueError, TypeError):\n                was = None\n            if was != sort:\n                return self.problem(400, \"bad-cursor\", \"Invalid cursor\",\n                                    \"after takes the cursor of a next link, with the same sort\")\n            where.append(f\"({column}, id) {'<' if down else '>'} (?, ?)\")\n            args += [value, ident]\n        order = \"DESC\" if down else \"ASC\"\n        sql = (\"SELECT * FROM books\" + (\" WHERE \" + \" AND \".join(where) if where else \"\")\n               + f\" ORDER BY {column} {order}, id {order} LIMIT ?\")\n        with db.connect() as conn:\n            rows = conn.execute(sql, args + [limit + 1]).fetchall()\n        body, headers = {\"items\": [book(r) for r in rows[:limit]], \"next\": None}, []\n        if len(rows) > limit:\n            keep = {k: v for k, v in q.items() if k != \"after\"}\n            body[\"next\"] = \"/v1/books?\" + urlencode({**keep, \"after\": cursor(sort, rows[limit - 1])})\n            headers.append((\"Link\", f'<{body[\"next\"]}>; rel=\"next\"'))\n        return self.reply(200, body, headers)",
      "note": "Paginação por chave. O cursor vira uma condição, \"depois deste valor e deste id\", escrita como comparação de linhas que o SQLite entende. O id desempata, então dois livros do mesmo ano não podem ser pulados nem repetidos. Pedir uma linha a mais que a página diz se existe uma próxima, e o link `next` vai no corpo e num cabeçalho `Link`."
    },
    {
      "code": "\n    def do_POST(self):\n        path = urlsplit(self.path).path\n        if path != \"/v1/books\":\n            if re.fullmatch(r\"/v1/books/\\d+\", path):\n                return self.problem(405, None, \"Method Not Allowed\", \"POST goes to /v1/books\",\n                                    [(\"Allow\", \"GET\")])\n            return self.problem(404, None, \"Not Found\", f\"nothing lives at {path}\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.problem(415, None, \"Unsupported Media Type\", \"send the book as application/json\")\n        try:\n            value = json.loads(self.raw)\n        except ValueError as e:\n            return self.problem(400, \"malformed-json\", \"The body is not JSON\", str(e))\n        errors = sorted(({\"pointer\": pointer(e.absolute_path), \"detail\": e.message}\n                         for e in BOOK.iter_errors(value)), key=lambda e: e[\"pointer\"])\n        if errors:\n            return self.problem(422, \"invalid-book\", \"The book breaks the contract\",\n                                \"every problem with the book is listed in errors\", errors=errors)",
      "note": "Criar um livro: o endereço, o tipo de mídia e o JSON, como no `rest.py`. Depois o schema, e `iter_errors` devolve **todos** os erros em vez do primeiro, cada um transformado num ponteiro e numa frase."
    },
    {
      "code": "        key = self.headers.get(\"Idempotency-Key\")\n        if key is not None and not 1 <= len(key) <= 200:\n            return self.problem(400, \"bad-idempotency-key\", \"Invalid Idempotency-Key\",\n                                \"a key is 1 to 200 characters\")\n        fingerprint = hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()",
      "note": "O cabeçalho opcional `Idempotency-Key` e uma impressão digital do corpo: o SHA-256 do JSON com as chaves ordenadas, para que o mesmo livro enviado com os campos em outra ordem conte como a mesma requisição."
    },
    {
      "code": "        with db.connect() as conn:\n            conn.execute(KEYS)\n            conn.execute(\"BEGIN IMMEDIATE\")\n            seen = key and conn.execute(\"SELECT * FROM idempotency_keys WHERE key = ?\",\n                                        (key,)).fetchone()\n            if seen and seen[\"fingerprint\"] != fingerprint:\n                return self.problem(422, \"key-reused\", \"Idempotency-Key reused\",\n                                    \"this key came with a different book; use a new key\")\n            if seen:\n                return self.reply(201, json.loads(seen[\"body\"]),\n                                  [(\"Location\", seen[\"location\"]), (\"Idempotent-Replayed\", \"true\")])\n            try:\n                ident = conn.execute(\n                    \"INSERT INTO books (isbn, title, author_id, year, price_cents, stock)\"\n                    \" VALUES (?, ?, ?, ?, ?, ?)\",\n                    (value[\"isbn\"], value[\"title\"], value[\"author_id\"], value[\"year\"],\n                     value[\"price\"][\"amount_cents\"], value.get(\"stock\", 0))).lastrowid\n            except sqlite3.IntegrityError as e:\n                if \"UNIQUE\" in str(e):\n                    return self.problem(409, \"duplicate-isbn\", \"ISBN already in the catalogue\",\n                                        f\"another book has ISBN {value['isbn']}\")\n                return self.problem(422, \"invalid-book\", \"The book breaks the contract\",\n                                    \"every problem with the book is listed in errors\",\n                                    errors=[{\"pointer\": \"#/author_id\", \"detail\": \"no such author\"}])\n            created = book(conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone())\n            location = f\"/v1/books/{ident}\"\n            if key:\n                conn.execute(\"INSERT INTO idempotency_keys VALUES (?, ?, ?, ?, ?)\",\n                             (key, fingerprint, location, json.dumps(created, ensure_ascii=False),\n                              datetime.now(timezone.utc).isoformat(timespec=\"seconds\")))\n        return self.reply(201, created, [(\"Location\", location)])",
      "note": "**Uma transação só cobre a conferência da chave, o livro novo e a resposta guardada.** O `BEGIN IMMEDIATE` pega antes o lock de escrita do SQLite, então duas tentativas que chegam juntas fazem fila em vez de inserir as duas, e uma queda no meio não deixa nem livro sem chave nem chave sem livro. Uma chave já vista com o mesmo corpo repete a resposta guardada; com outro corpo, é um 422."
    },
    {
      "code": "\n    def refuse(self):\n        self.problem(405, None, \"Method Not Allowed\", f\"the catalogue does not take {self.command}\",\n                     [(\"Allow\", \"GET, POST\")])\n\n    do_PUT = do_PATCH = do_DELETE = do_OPTIONS = refuse",
      "note": "Os métodos que o catálogo não aceita recebem um 405 com `Allow`, no formato de problema, em vez do 501 em HTML que a biblioteca do Python mandou para `OPTIONS` na aula 1."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Catalogue)\n    print(\"catalogue on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "A mesma porta do `rest.py`, e é por isso que só um dos dois pode rodar de cada vez."
    }
  ]
}
```

O programa precisa do `book.schema.json` da seção anterior ao lado dele. Inicie-o no segundo
terminal:

```sh
cd ~/shelf && python3 catalogue.py
```

Ele imprime uma linha e espera, e a partir daí cada requisição acrescenta uma linha embaixo, como o
`rest.py` fazia:

```
catalogue on http://127.0.0.1:8000
127.0.0.1 - - [10/Oct/2026 01:29:41] "GET /v1/books/1 HTTP/1.1" 200 -
```

Ele tem três rotas:

| método e caminho | o que faz |
|---|---|
| `GET /v1/books/{id}` | um livro |
| `GET /v1/books` | uma página de livros; aceita `author_id`, `in_stock`, `sort`, `limit` e `after` |
| `POST /v1/books` | cria um livro que passa no schema; aceita um cabeçalho `Idempotency-Key` opcional |

## O mesmo livro, duas vezes

O `rest.py` da aula 1 respondia assim pelo primeiro livro:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price_cents": 3990, "stock": 12}
```

O `catalogue.py` responde pela mesma linha, uma vez como chega e outra pelo `jq .`, que a indenta:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price": {"amount_cents": 3990, "currency": "BRL"}, "stock": 12, "in_stock": true}
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1 | jq .
{
  "id": 1,
  "isbn": "9786500000016",
  "title": "Dom Casmurro",
  "author_id": 1,
  "year": 1899,
  "price": {
    "amount_cents": 3990,
    "currency": "BRL"
  },
  "stock": 12,
  "in_stock": true
}
```

Duas coisas mudaram. O preço é um objeto que carrega a moeda, e `in_stock` é um booleano calculado
a partir de `stock`. **As duas são mudanças incompatíveis para um cliente do `rest.py`**: quem lê
`price_cents` não encontra nada. É por isso que o catálogo é um programa separado, e não uma edição
do `rest.py`. Se fosse a próxima versão da mesma API, teria saído sob `/v2`, como a versão 2 da
aula 1 fez exatamente para essa mudança no preço. O `catalogue.py` usa `/v1` porque, como API, ele
é novo.
