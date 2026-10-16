---
title: O shelf
version: 1
---

A API que este curso constrói é de uma pequena livraria, e se chama **shelf**. São dois arquivos de
Python e um banco SQLite, e você digita tudo. Nada nela vem de um framework, e esse é o ponto: um
framework escolheria os códigos de status e os cabeçalhos por você, e esta aula é sobre escolhê-los.

Python não é requisito do curso. A trilha de back-end deixa você escolher uma entre quatro linguagens,
e qualquer que tenha escolhido, você consegue ler estes arquivos, porque são curtos e dizem o que
fazem. O que o curso ensina sobre um recurso, um token ou um cabeçalho é igual em qualquer uma delas, e
toda requisição aqui é feita com `curl`, que não se importa com quem respondeu.

Crie um diretório para ela e entre nele:

```sh
mkdir -p ~/shelf && cd ~/shelf
```

## O banco de dados

O `db.py` cria o `shelf.db` na primeira vez que alguém pede uma conexão, com duas tabelas e os livros
já dentro delas. Abra o editor com `nano db.py`, copie o arquivo abaixo com o botão no canto do bloco,
cole, depois `Ctrl+O` para salvar e `Ctrl+X` para sair.

```python
# shelf/db.py
"""The bookshop's database: one SQLite file, created and filled on first use."""
import os
import sqlite3

PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shelf.db")

SCHEMA = """
CREATE TABLE authors (
    id      INTEGER PRIMARY KEY,
    name    TEXT NOT NULL,
    country TEXT NOT NULL
);
CREATE TABLE books (
    id          INTEGER PRIMARY KEY,
    isbn        TEXT NOT NULL UNIQUE,
    title       TEXT NOT NULL,
    author_id   INTEGER NOT NULL REFERENCES authors (id),
    year        INTEGER NOT NULL,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);
"""

AUTHORS = [
    (1, "Machado de Assis", "BR"),
    (2, "Clarice Lispector", "BR"),
    (3, "José Saramago", "PT"),
    (4, "Chimamanda Ngozi Adichie", "NG"),
]

BOOKS = [
    (1, "9786500000016", "Dom Casmurro", 1, 1899, 3990, 12),
    (2, "9786500000023", "Memórias Póstumas de Brás Cubas", 1, 1881, 4490, 7),
    (3, "9786500000030", "A Hora da Estrela", 2, 1977, 3490, 0),
    (4, "9786500000047", "Perto do Coração Selvagem", 2, 1943, 4290, 3),
    (5, "9786500000054", "Ensaio sobre a Cegueira", 3, 1995, 5990, 9),
    (6, "9786500000061", "Americanah", 4, 2013, 6490, 4),
]


def connect():
    """A connection to shelf.db, with the tables and the books in it."""
    new = not os.path.exists(PATH)
    db = sqlite3.connect(PATH)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA foreign_keys = ON")
    if new:
        db.executescript(SCHEMA)
        db.executemany("INSERT INTO authors VALUES (?, ?, ?)", AUTHORS)
        db.executemany("INSERT INTO books VALUES (?, ?, ?, ?, ?, ?, ?)", BOOKS)
        db.commit()
    return db
```

A **primeira linha de todo arquivo que este curso entrega é o caminho dele**, como comentário. Ela não
muda nada quando o programa roda, e significa que um arquivo copiado sempre consegue dizer onde mora.

## A API

O `rest.py` é a API propriamente dita. Ele é mais longo, então cada parte tem uma nota ao lado; o botão
de copiar continua levando o programa inteiro, sem as notas. Salve como `rest.py` do mesmo jeito.

```schooling-example
{
  "language": "python",
  "file": "shelf/rest.py",
  "parts": [
    {
      "code": "# shelf/rest.py\n\"\"\"The bookshop's REST API, version 1 and a version 2 of one resource.\n\nRun it with `python3 rest.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport json\nimport re\nimport sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlsplit\n\nimport db",
      "note": "Só a biblioteca padrão do Python e o `db.py` do mesmo diretório. Não há nada para instalar com pip, nem nada escondido atrás de um framework: todo código de status e todo cabeçalho que esta API envia está escrito aqui embaixo."
    },
    {
      "code": "\nFIELDS = {\"isbn\": str, \"title\": str, \"author_id\": int, \"year\": int,\n          \"price_cents\": int, \"stock\": int}",
      "note": "Os campos que um cliente pode enviar e o tipo que cada um precisa ter. Toda escrita é conferida contra esta tabela, então acrescentar um campo é uma linha."
    },
    {
      "code": "\n\ndef book_v1(row):\n    return {\"id\": row[\"id\"], \"isbn\": row[\"isbn\"], \"title\": row[\"title\"],\n            \"author_id\": row[\"author_id\"], \"year\": row[\"year\"],\n            \"price_cents\": row[\"price_cents\"], \"stock\": row[\"stock\"]}\n\n\ndef book_v2(row):\n    v = book_v1(row)\n    v[\"price\"] = {\"amount_cents\": v.pop(\"price_cents\"), \"currency\": \"BRL\"}\n    return v",
      "note": "A **representação**: o que o cliente recebe é montado a partir da linha, e não é a linha. A versão 2 muda uma coisa só, o formato do preço, e a seção sobre versionamento explica por que isso exige uma versão nova."
    },
    {
      "code": "\n\nclass Shelf(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        \"\"\"Read the whole request, body included, before anything answers it.\"\"\"\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True",
      "note": "A classe começa lendo a requisição **inteira**, corpo incluído, antes que qualquer método decida algo. Responda com um corpo ainda por ler e os bytes dele ficam na conexão, onde o servidor os lê como a próxima requisição. Isso aconteceu enquanto este arquivo era escrito: um formulário recusado voltou como uma requisição chamada `title=Quincas`."
    },
    {
      "code": "\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)",
      "note": "Toda resposta sai por `reply`: a linha de status, `Content-Type`, `Content-Length`, os cabeçalhos extras e depois o corpo. O `protocol_version` acima faz dela HTTP/1.1, que mantém a conexão aberta entre requisições."
    },
    {
      "code": "\n    def body(self):\n        \"\"\"The request's JSON object, or None after answering 415 or 400.\"\"\"\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            self.error(415, \"send the book as application/json\")\n            return None\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            self.error(400, \"the body is not valid JSON\")\n            return None\n        if not isinstance(value, dict):\n            self.error(400, \"the body must be a JSON object\")\n            return None\n        return value",
      "note": "A leitura do corpo da requisição. Um corpo que não se declara JSON é recusado com **415**; um que não faz parse, ou não é um objeto, com **400**."
    },
    {
      "code": "\n    def route(self):\n        \"\"\"(version, collection, id or None, sub-collection or None) for the path.\"\"\"\n        m = re.fullmatch(r\"/(v[12])/(books|authors)(?:/(\\d+))?(?:/(books))?/?\", urlsplit(self.path).path)\n        if not m:\n            return None\n        version, coll, ident, sub = m.groups()\n        return version, coll, int(ident) if ident else None, sub",
      "note": "Todo o esquema de endereços numa expressão regular: uma versão, uma coleção, um id opcional e um `books` opcional debaixo de um autor. Qualquer outra coisa é 404 antes de ler uma única linha."
    },
    {
      "code": "\n    def do_GET(self):\n        r = self.route()\n        if r is None:\n            return self.error(404, \"no such resource\")\n        version, coll, ident, sub = r\n        show = book_v2 if version == \"v2\" else book_v1\n        with db.connect() as conn:\n            if coll == \"books\" and ident is None:\n                query = parse_qs(urlsplit(self.path).query)\n                if \"author_id\" in query:\n                    rows = conn.execute(\"SELECT * FROM books WHERE author_id = ? ORDER BY id\",\n                                        (query[\"author_id\"][0],)).fetchall()\n                else:\n                    rows = conn.execute(\"SELECT * FROM books ORDER BY id\").fetchall()\n                return self.reply(200, [show(row) for row in rows])\n            if coll == \"books\" and sub is None:\n                row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n                return self.reply(200, show(row)) if row else self.error(404, f\"no book {ident}\")\n            if coll == \"authors\" and version == \"v1\":\n                author = conn.execute(\"SELECT * FROM authors WHERE id = ?\", (ident,)).fetchone()\n                if ident is None or author is None:\n                    return self.error(404, \"no such author\")\n                if sub == \"books\":\n                    rows = conn.execute(\"SELECT * FROM books WHERE author_id = ? ORDER BY id\",\n                                        (ident,)).fetchall()\n                    return self.reply(200, [show(row) for row in rows])\n                return self.reply(200, dict(author))\n        return self.error(404, \"no such resource\")",
      "note": "GET em três formas: a coleção, filtrada por uma query string quando há uma; um item; e os livros de um autor, uma coleção dentro de um item."
    },
    {
      "code": "\n    def write(self, ident, value, partial):\n        \"\"\"Shared by POST, PUT and PATCH: check the fields, then store them.\"\"\"\n        unknown = sorted(set(value) - set(FIELDS))\n        if unknown:\n            return self.error(422, f\"unknown fields: {', '.join(unknown)}\")\n        wrong = sorted(k for k, v in value.items() if type(v) is not FIELDS[k])\n        if wrong:\n            return self.error(422, f\"wrong type for: {', '.join(wrong)}\")\n        missing = [] if partial else sorted(set(FIELDS) - set(value) - {\"stock\"})\n        if missing:\n            return self.error(422, f\"missing fields: {', '.join(missing)}\")\n        with db.connect() as conn:\n            if ident is not None:\n                old = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n                if old is None:\n                    return self.error(404, f\"no book {ident}\")\n                new = {**book_v1(old), **value} if partial else {\"stock\": 0, **value}\n                new[\"id\"] = ident\n            else:\n                new = {\"stock\": 0, **value}\n            try:\n                if ident is None:\n                    ident = conn.execute(\n                        \"INSERT INTO books (isbn, title, author_id, year, price_cents, stock)\"\n                        \" VALUES (:isbn, :title, :author_id, :year, :price_cents, :stock)\",\n                        new).lastrowid\n                    created = True\n                else:\n                    conn.execute(\n                        \"UPDATE books SET isbn = :isbn, title = :title, author_id = :author_id,\"\n                        \" year = :year, price_cents = :price_cents, stock = :stock WHERE id = :id\",\n                        new)\n                    created = False\n            except sqlite3.IntegrityError as e:\n                if \"UNIQUE\" in str(e):\n                    return self.error(409, f\"conflict: {e}\")\n                return self.error(422, f\"rejected: {e}\")\n            row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n        if created:\n            return self.reply(201, book_v1(row), [(\"Location\", f\"/v1/books/{row['id']}\")])\n        return self.reply(200, book_v1(row))",
      "note": "Uma função para os três métodos que escrevem, porque eles diferem em dois pontos só. `partial` é a diferença entre PUT e PATCH. Um livro novo responde **201** com `Location`. Uma regra violada responde **422**, tenha sido este código a pegá-la ou o próprio `CHECK` e a chave estrangeira do banco; um choque com o ISBN de outro livro responde **409**."
    },
    {
      "code": "\n    def item(self):\n        \"\"\"The book id for a /v1/books/<id> path, or None after answering.\"\"\"\n        r = self.route()\n        if r is None or r[1] != \"books\" or r[3] is not None:\n            self.error(404, \"no such resource\")\n            return None\n        if r[0] != \"v1\":\n            self.error(405, \"version 2 is read-only\", [(\"Allow\", \"GET\")])\n            return None\n        if r[2] is None:\n            self.error(405, f\"{self.command} needs a book's address\",\n                       [(\"Allow\", \"GET, POST\")])\n            return None\n        return r[2]",
      "note": "PUT, PATCH e DELETE precisam do endereço de um livro. Enviados a qualquer outro lugar, recebem **405**, e o cabeçalho `Allow` diz quais métodos aquele endereço aceita."
    },
    {
      "code": "\n    def do_POST(self):\n        r = self.route()\n        if r is None or r[1:] != (\"books\", None, None) or r[0] != \"v1\":\n            allow = \"GET, PUT, PATCH, DELETE\" if r and r[2] is not None else \"GET\"\n            return self.error(405, \"POST creates a book in /v1/books\", [(\"Allow\", allow)])\n        value = self.body()\n        if value is not None:\n            self.write(None, value, partial=False)\n\n    def do_PUT(self):\n        ident = self.item()\n        if ident is not None:\n            value = self.body()\n            if value is not None:\n                self.write(ident, value, partial=False)\n\n    def do_PATCH(self):\n        ident = self.item()\n        if ident is not None:\n            value = self.body()\n            if value is not None:\n                self.write(ident, value, partial=True)\n\n    def do_DELETE(self):\n        ident = self.item()\n        if ident is None:\n            return\n        with db.connect() as conn:\n            gone = conn.execute(\"DELETE FROM books WHERE id = ?\", (ident,)).rowcount\n        return self.reply(204) if gone else self.error(404, f\"no book {ident}\")",
      "note": "Os quatro métodos que mudam alguma coisa. DELETE responde **204** sem corpo na primeira vez, e **404** na segunda."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Shelf)\n    print(\"shelf on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "Escuta só em 127.0.0.1, então nada fora da máquina o alcança. Uma thread por requisição."
    }
  ]
}
```

## Rodando

Um servidor roda até você pará-lo, então precisa de um terminal só dele. Abra um segundo terminal (com
o Multipass, `multipass shell api` de novo numa janela nova) e, nele:

```sh
cd ~/shelf && python3 rest.py
```

Ele imprime `shelf on http://127.0.0.1:8000` e fica esperando. Deixe-o lá. **Todo comando daqui para
a frente é digitado no primeiro terminal**, e cada requisição que você enviar imprime uma linha no
segundo. `Ctrl+C` para o servidor; `python3 rest.py` o inicia de novo, e nada se perde, porque os
livros moram no `shelf.db` e não no programa.

Antes da primeira requisição, só existem os dois arquivos que você escreveu:

```
ana@api:~/shelf$ ls
db.py
rest.py
```

Peça o primeiro livro e olhe de novo:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price_cents": 3990, "stock": 12}
ana@api:~/shelf$ ls
__pycache__
db.py
rest.py
shelf.db
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id, title, price_cents, stock FROM books'
1|Dom Casmurro|3990|12
2|Memórias Póstumas de Brás Cubas|4490|7
3|A Hora da Estrela|3490|0
4|Perto do Coração Selvagem|4290|3
5|Ensaio sobre a Cegueira|5990|9
6|Americanah|6490|4
```

A primeira requisição criou o `shelf.db`, com os seis livros que o `db.py` colocou lá, e o
`__pycache__` é o Python guardando uma cópia compilada do `db.py` para o próximo import ser mais
rápido. O segundo terminal imprimiu uma linha para essa requisição: quem pediu, quando, a linha da
requisição e o status.

```
shelf on http://127.0.0.1:8000
127.0.0.1 - - [10/Oct/2026 01:07:52] "GET /v1/books/1 HTTP/1.1" 200 -
```

Quando quiser recomeçar com os seis livros, pare o servidor, apague o `shelf.db` e inicie o servidor de
novo.
