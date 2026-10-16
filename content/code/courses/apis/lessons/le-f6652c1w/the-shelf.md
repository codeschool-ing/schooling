---
title: The shelf
version: 1
---

The API this course builds belongs to a small bookshop, and it is called **shelf**. It is two files
of Python and one SQLite database, and you type all of it in. Nothing in it comes from a framework,
which is the point: a framework would choose the status codes and the headers for you, and this
lesson is about choosing them.

Python is not a requirement of the course. The back-end track lets you pick one of four languages,
and whichever you picked, you can read these files, because they are short and say what they do. What
the course teaches about a resource, a token or a header is the same in any of them, and every
request in it is made with `curl`, which does not care what answered.

Make a directory for it and go into it:

```sh
mkdir -p ~/shelf && cd ~/shelf
```

## The database

`db.py` creates `shelf.db` the first time anything asks for a connection, with two tables and the
books already in them. Open the editor with `nano db.py`, copy the file below with the button in its
corner, paste it, then `Ctrl+O` to save and `Ctrl+X` to leave.

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

The **first line of every file this course gives you is its path**, as a comment. It changes nothing
when the program runs, and it means a file you copied can always say where it belongs.

## The API

`rest.py` is the API itself. It is longer, so each part has a note beside it; the copy button still
takes the whole program, without the notes. Save it as `rest.py` the same way.

```schooling-example
{
  "language": "python",
  "file": "shelf/rest.py",
  "parts": [
    {
      "code": "# shelf/rest.py\n\"\"\"The bookshop's REST API, version 1 and a version 2 of one resource.\n\nRun it with `python3 rest.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport json\nimport re\nimport sqlite3\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlsplit\n\nimport db",
      "note": "Only Python's standard library and `db.py` from the same directory. There is nothing to install with pip, and nothing hidden behind a framework: every status code and header this API sends is written below."
    },
    {
      "code": "\nFIELDS = {\"isbn\": str, \"title\": str, \"author_id\": int, \"year\": int,\n          \"price_cents\": int, \"stock\": int}",
      "note": "The fields a client may send, and the type each one must have. Every write is checked against this one table, so adding a field is one line."
    },
    {
      "code": "\n\ndef book_v1(row):\n    return {\"id\": row[\"id\"], \"isbn\": row[\"isbn\"], \"title\": row[\"title\"],\n            \"author_id\": row[\"author_id\"], \"year\": row[\"year\"],\n            \"price_cents\": row[\"price_cents\"], \"stock\": row[\"stock\"]}\n\n\ndef book_v2(row):\n    v = book_v1(row)\n    v[\"price\"] = {\"amount_cents\": v.pop(\"price_cents\"), \"currency\": \"BRL\"}\n    return v",
      "note": "The **representation**: what a client receives is built from the row, and is not the row itself. Version 2 changes one thing, the shape of the price, and the section on versioning is about why that needs a new version."
    },
    {
      "code": "\n\nclass Shelf(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        \"\"\"Read the whole request, body included, before anything answers it.\"\"\"\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True",
      "note": "The class starts by reading the **whole** request, body included, before any method decides anything. Answer while a body still sits unread and its bytes stay in the connection, where the server reads them as the next request. That happened while this file was being written: a refused form came back as a request called `title=Quincas`."
    },
    {
      "code": "\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)",
      "note": "Every answer leaves through `reply`: the status line, `Content-Type`, `Content-Length`, any extra headers, then the body. `protocol_version` above makes it HTTP/1.1, which keeps the connection open between requests."
    },
    {
      "code": "\n    def body(self):\n        \"\"\"The request's JSON object, or None after answering 415 or 400.\"\"\"\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            self.error(415, \"send the book as application/json\")\n            return None\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            self.error(400, \"the body is not valid JSON\")\n            return None\n        if not isinstance(value, dict):\n            self.error(400, \"the body must be a JSON object\")\n            return None\n        return value",
      "note": "Reading a request's body. A body that is not declared as JSON is refused with **415**; one that does not parse, or is not an object, with **400**."
    },
    {
      "code": "\n    def route(self):\n        \"\"\"(version, collection, id or None, sub-collection or None) for the path.\"\"\"\n        m = re.fullmatch(r\"/(v[12])/(books|authors)(?:/(\\d+))?(?:/(books))?/?\", urlsplit(self.path).path)\n        if not m:\n            return None\n        version, coll, ident, sub = m.groups()\n        return version, coll, int(ident) if ident else None, sub",
      "note": "The whole address scheme in one regular expression: a version, a collection, an optional id, and an optional `books` under an author. Anything else is a 404 before a single row is read."
    },
    {
      "code": "\n    def do_GET(self):\n        r = self.route()\n        if r is None:\n            return self.error(404, \"no such resource\")\n        version, coll, ident, sub = r\n        show = book_v2 if version == \"v2\" else book_v1\n        with db.connect() as conn:\n            if coll == \"books\" and ident is None:\n                query = parse_qs(urlsplit(self.path).query)\n                if \"author_id\" in query:\n                    rows = conn.execute(\"SELECT * FROM books WHERE author_id = ? ORDER BY id\",\n                                        (query[\"author_id\"][0],)).fetchall()\n                else:\n                    rows = conn.execute(\"SELECT * FROM books ORDER BY id\").fetchall()\n                return self.reply(200, [show(row) for row in rows])\n            if coll == \"books\" and sub is None:\n                row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n                return self.reply(200, show(row)) if row else self.error(404, f\"no book {ident}\")\n            if coll == \"authors\" and version == \"v1\":\n                author = conn.execute(\"SELECT * FROM authors WHERE id = ?\", (ident,)).fetchone()\n                if ident is None or author is None:\n                    return self.error(404, \"no such author\")\n                if sub == \"books\":\n                    rows = conn.execute(\"SELECT * FROM books WHERE author_id = ? ORDER BY id\",\n                                        (ident,)).fetchall()\n                    return self.reply(200, [show(row) for row in rows])\n                return self.reply(200, dict(author))\n        return self.error(404, \"no such resource\")",
      "note": "GET in three shapes: the collection, filtered by a query string when one is given; one item; and the books of one author, a collection inside an item."
    },
    {
      "code": "\n    def write(self, ident, value, partial):\n        \"\"\"Shared by POST, PUT and PATCH: check the fields, then store them.\"\"\"\n        unknown = sorted(set(value) - set(FIELDS))\n        if unknown:\n            return self.error(422, f\"unknown fields: {', '.join(unknown)}\")\n        wrong = sorted(k for k, v in value.items() if type(v) is not FIELDS[k])\n        if wrong:\n            return self.error(422, f\"wrong type for: {', '.join(wrong)}\")\n        missing = [] if partial else sorted(set(FIELDS) - set(value) - {\"stock\"})\n        if missing:\n            return self.error(422, f\"missing fields: {', '.join(missing)}\")\n        with db.connect() as conn:\n            if ident is not None:\n                old = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n                if old is None:\n                    return self.error(404, f\"no book {ident}\")\n                new = {**book_v1(old), **value} if partial else {\"stock\": 0, **value}\n                new[\"id\"] = ident\n            else:\n                new = {\"stock\": 0, **value}\n            try:\n                if ident is None:\n                    ident = conn.execute(\n                        \"INSERT INTO books (isbn, title, author_id, year, price_cents, stock)\"\n                        \" VALUES (:isbn, :title, :author_id, :year, :price_cents, :stock)\",\n                        new).lastrowid\n                    created = True\n                else:\n                    conn.execute(\n                        \"UPDATE books SET isbn = :isbn, title = :title, author_id = :author_id,\"\n                        \" year = :year, price_cents = :price_cents, stock = :stock WHERE id = :id\",\n                        new)\n                    created = False\n            except sqlite3.IntegrityError as e:\n                if \"UNIQUE\" in str(e):\n                    return self.error(409, f\"conflict: {e}\")\n                return self.error(422, f\"rejected: {e}\")\n            row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone()\n        if created:\n            return self.reply(201, book_v1(row), [(\"Location\", f\"/v1/books/{row['id']}\")])\n        return self.reply(200, book_v1(row))",
      "note": "One function for the three methods that write, because they differ in only two places. `partial` is the difference between PUT and PATCH. A new book answers **201** with a `Location`. A broken rule answers **422**, whether this code caught it or the database's own `CHECK` and foreign key did; a clash with another book's ISBN answers **409**."
    },
    {
      "code": "\n    def item(self):\n        \"\"\"The book id for a /v1/books/<id> path, or None after answering.\"\"\"\n        r = self.route()\n        if r is None or r[1] != \"books\" or r[3] is not None:\n            self.error(404, \"no such resource\")\n            return None\n        if r[0] != \"v1\":\n            self.error(405, \"version 2 is read-only\", [(\"Allow\", \"GET\")])\n            return None\n        if r[2] is None:\n            self.error(405, f\"{self.command} needs a book's address\",\n                       [(\"Allow\", \"GET, POST\")])\n            return None\n        return r[2]",
      "note": "PUT, PATCH and DELETE need one book's address. Sent anywhere else they get **405**, and the `Allow` header says which methods that address does take."
    },
    {
      "code": "\n    def do_POST(self):\n        r = self.route()\n        if r is None or r[1:] != (\"books\", None, None) or r[0] != \"v1\":\n            allow = \"GET, PUT, PATCH, DELETE\" if r and r[2] is not None else \"GET\"\n            return self.error(405, \"POST creates a book in /v1/books\", [(\"Allow\", allow)])\n        value = self.body()\n        if value is not None:\n            self.write(None, value, partial=False)\n\n    def do_PUT(self):\n        ident = self.item()\n        if ident is not None:\n            value = self.body()\n            if value is not None:\n                self.write(ident, value, partial=False)\n\n    def do_PATCH(self):\n        ident = self.item()\n        if ident is not None:\n            value = self.body()\n            if value is not None:\n                self.write(ident, value, partial=True)\n\n    def do_DELETE(self):\n        ident = self.item()\n        if ident is None:\n            return\n        with db.connect() as conn:\n            gone = conn.execute(\"DELETE FROM books WHERE id = ?\", (ident,)).rowcount\n        return self.reply(204) if gone else self.error(404, f\"no book {ident}\")",
      "note": "The four methods that change something. DELETE answers **204** and no body the first time, and **404** the second."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Shelf)\n    print(\"shelf on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "Listening on 127.0.0.1 only, so nothing outside the machine can reach it. One thread per request."
    }
  ]
}
```

## Running it

A server runs until you stop it, so it needs a terminal of its own. Open a second one (with Multipass,
`multipass shell api` again in a new window), and in it:

```sh
cd ~/shelf && python3 rest.py
```

It prints `shelf on http://127.0.0.1:8000` and waits. Leave it there. **Every command from now on is
typed in the first terminal**, and each request you send prints one line in the second. `Ctrl+C`
stops the server; `python3 rest.py` starts it again, and nothing is lost, because the books live in
`shelf.db` and not in the program.

Before the first request there are only the two files you wrote:

```
ana@api:~/shelf$ ls
db.py
rest.py
```

Ask for the first book, then look again:

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

The first request created `shelf.db`, with the six books `db.py` put there, and `__pycache__` is
Python keeping a compiled copy of `db.py` so the next import is quicker. The second terminal printed
one line for that request: who asked, when, the request line and the status.

```
shelf on http://127.0.0.1:8000
127.0.0.1 - - [10/Oct/2026 01:07:52] "GET /v1/books/1 HTTP/1.1" 200 -
```

When you want to start again from the six books, stop the server, delete `shelf.db` and start the
server again.
