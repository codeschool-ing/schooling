---
title: The catalogue
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "shelf/catalogue.py",
  "parts": [
    {
      "code": "# shelf/catalogue.py\n\"\"\"The bookshop's catalogue, with its contract written down.\n\nStop rest.py first, then run `python3 catalogue.py`; it answers on\nhttp://127.0.0.1:8000.\n\"\"\"\nimport base64\nimport hashlib\nimport json\nimport os\nimport re\nimport sqlite3\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlencode, urlsplit\n\nimport jsonschema\n\nimport db\n\nHERE = os.path.dirname(os.path.abspath(__file__))\nwith open(os.path.join(HERE, \"book.schema.json\"), encoding=\"utf-8\") as f:\n    BOOK = jsonschema.Draft202012Validator(json.load(f))",
      "note": "The standard library again, plus `jsonschema` from Ubuntu's `python3-jsonschema`, which lesson 1 installed. The schema is read **once, at start-up**: a missing or broken `book.schema.json` stops the server before it answers anybody, instead of failing on the first POST."
    },
    {
      "code": "\nPROBLEMS = \"https://shelf.example/problems/\"\nSORTS = {\"id\": \"id\", \"title\": \"title\", \"year\": \"year\", \"price\": \"price_cents\"}\nPARAMS = {\"author_id\", \"in_stock\", \"sort\", \"limit\", \"after\"}\nPAGE, MOST = 20, 100",
      "note": "Four decisions written as data. Problem types share one prefix. `SORTS` is the **allowlist** of sortable fields, mapping the public name to the column, so `price` sorts by `price_cents` and nothing a client types ever becomes part of the SQL. `PARAMS` is every query parameter the collection understands. A page holds 20 books unless the client asks for up to 100."
    },
    {
      "code": "\nKEYS = \"\"\"CREATE TABLE IF NOT EXISTS idempotency_keys (\n    key         TEXT PRIMARY KEY,\n    fingerprint TEXT NOT NULL,\n    location    TEXT NOT NULL,\n    body        TEXT NOT NULL,\n    created_at  TEXT NOT NULL\n)\"\"\"",
      "note": "The one table `db.py` does not create. It remembers each idempotency key with a fingerprint of the body it came with and the answer it got. `catalogue.py` creates it the first time a book is posted."
    },
    {
      "code": "\n\ndef book(row):\n    return {\"id\": row[\"id\"], \"isbn\": row[\"isbn\"], \"title\": row[\"title\"],\n            \"author_id\": row[\"author_id\"], \"year\": row[\"year\"],\n            \"price\": {\"amount_cents\": row[\"price_cents\"], \"currency\": \"BRL\"},\n            \"stock\": row[\"stock\"], \"in_stock\": row[\"stock\"] > 0}",
      "note": "The representation, in the shape the section on names argues for: snake_case throughout, money as integer cents **with its currency**, and `in_stock` as a real boolean, worked out from `stock` so that the two can never disagree."
    },
    {
      "code": "\n\ndef cursor(sort, row):\n    raw = json.dumps([sort, row[SORTS[sort.lstrip(\"-\")]], row[\"id\"]], ensure_ascii=False)\n    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip(\"=\")\n\n\ndef uncursor(text):\n    return json.loads(base64.urlsafe_b64decode(text + \"=\" * (-len(text) % 4)))",
      "note": "A cursor is the sort, the last row's value for that sort and the last row's id, as JSON in URL-safe base64. Opaque means the client must not build or read one. It does not mean secret, and the section on pages decodes one."
    },
    {
      "code": "\n\ndef pointer(path):\n    return \"#\" + \"\".join(\"/\" + str(p).replace(\"~\", \"~0\").replace(\"/\", \"~1\") for p in path)",
      "note": "Turns the path `jsonschema` reports, such as `price` then `amount_cents`, into a JSON Pointer, `#/price/amount_cents`. The two replacements are RFC 6901's escapes for a `~` or a `/` inside a field's name."
    },
    {
      "code": "\n\nclass Catalogue(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value, headers=(), kind=\"application/json\"):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "Reading the whole request first and sending every answer through `reply` work as they did in `rest.py`. `reply` now takes the media type, because errors go out with a different one."
    },
    {
      "code": "\n    def problem(self, status, kind, title, detail, headers=(), **extra):\n        value = {\"type\": PROBLEMS + kind if kind else \"about:blank\", \"title\": title,\n                 \"status\": status, \"detail\": detail, \"instance\": urlsplit(self.path).path, **extra}\n        self.reply(status, value, headers, \"application/problem+json\")",
      "note": "**Every error leaves through here**, as an RFC 9457 problem: `type`, `title`, `status`, `detail` and `instance`, plus any extension member, such as `errors`, passed as a keyword. With no type of its own a problem is `about:blank`, and its title is the status code's name."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        m = re.fullmatch(r\"/v1/books(?:/(\\d+))?\", url.path)\n        if not m:\n            return self.problem(404, None, \"Not Found\", f\"nothing lives at {url.path}\")\n        if m.group(1) is None:\n            return self.page({k: v[0] for k, v in parse_qs(url.query).items()})\n        with db.connect() as conn:\n            row = conn.execute(\"SELECT * FROM books WHERE id = ?\", (int(m.group(1)),)).fetchone()\n        if row is None:\n            return self.problem(404, None, \"Not Found\", f\"there is no book {m.group(1)}\")\n        return self.reply(200, book(row))",
      "note": "Two addresses: the collection and one book. Anything else is a 404 in the same problem shape as every other error."
    },
    {
      "code": "\n    def page(self, q):\n        unknown = sorted(set(q) - PARAMS)\n        if unknown:\n            return self.problem(400, \"unknown-parameter\", \"Unknown query parameter\",\n                                f\"/v1/books does not take: {', '.join(unknown)}\")\n        sort = q.get(\"sort\", \"id\")\n        if sort.lstrip(\"-\") not in SORTS:\n            return self.problem(400, \"unsortable\", \"Cannot sort by that\",\n                                f\"sort takes {', '.join(SORTS)}, with a leading - for descending\")\n        limit = q.get(\"limit\", str(PAGE))\n        if not limit.isdigit() or not 1 <= int(limit) <= MOST:\n            return self.problem(400, \"bad-limit\", \"Page size out of range\",\n                                f\"limit is a whole number from 1 to {MOST}\")\n        limit = int(limit)",
      "note": "The query string is checked before anything is read. An unknown parameter, a sort that is not in the allowlist and a page size outside 1 to 100 are each a 400 that says what is accepted, so a typo in a filter never comes back as the whole catalogue."
    },
    {
      "code": "        where, args = [], []\n        if \"author_id\" in q:\n            if not q[\"author_id\"].isdigit():\n                return self.problem(400, \"bad-filter\", \"Invalid filter\", \"author_id is a number\")\n            where.append(\"author_id = ?\")\n            args.append(int(q[\"author_id\"]))\n        if \"in_stock\" in q:\n            if q[\"in_stock\"] not in (\"true\", \"false\"):\n                return self.problem(400, \"bad-filter\", \"Invalid filter\", \"in_stock is true or false\")\n            where.append(\"stock > 0\" if q[\"in_stock\"] == \"true\" else \"stock = 0\")",
      "note": "The two filters. Each value is checked and then **bound as a parameter** (`?`) or turned into a fixed condition; none is pasted into the SQL."
    },
    {
      "code": "        column, down = SORTS[sort.lstrip(\"-\")], sort.startswith(\"-\")\n        if \"after\" in q:\n            try:\n                was, value, ident = uncursor(q[\"after\"])\n            except (ValueError, TypeError):\n                was = None\n            if was != sort:\n                return self.problem(400, \"bad-cursor\", \"Invalid cursor\",\n                                    \"after takes the cursor of a next link, with the same sort\")\n            where.append(f\"({column}, id) {'<' if down else '>'} (?, ?)\")\n            args += [value, ident]\n        order = \"DESC\" if down else \"ASC\"\n        sql = (\"SELECT * FROM books\" + (\" WHERE \" + \" AND \".join(where) if where else \"\")\n               + f\" ORDER BY {column} {order}, id {order} LIMIT ?\")\n        with db.connect() as conn:\n            rows = conn.execute(sql, args + [limit + 1]).fetchall()\n        body, headers = {\"items\": [book(r) for r in rows[:limit]], \"next\": None}, []\n        if len(rows) > limit:\n            keep = {k: v for k, v in q.items() if k != \"after\"}\n            body[\"next\"] = \"/v1/books?\" + urlencode({**keep, \"after\": cursor(sort, rows[limit - 1])})\n            headers.append((\"Link\", f'<{body[\"next\"]}>; rel=\"next\"'))\n        return self.reply(200, body, headers)",
      "note": "Keyset pagination. The cursor becomes a condition, \"after this value and this id\", written as a row comparison SQLite understands. The id breaks ties, so two books of the same year cannot be skipped or repeated. Asking for one row more than the page says whether a next page exists, and the `next` link travels both in the body and in a `Link` header."
    },
    {
      "code": "\n    def do_POST(self):\n        path = urlsplit(self.path).path\n        if path != \"/v1/books\":\n            if re.fullmatch(r\"/v1/books/\\d+\", path):\n                return self.problem(405, None, \"Method Not Allowed\", \"POST goes to /v1/books\",\n                                    [(\"Allow\", \"GET\")])\n            return self.problem(404, None, \"Not Found\", f\"nothing lives at {path}\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.problem(415, None, \"Unsupported Media Type\", \"send the book as application/json\")\n        try:\n            value = json.loads(self.raw)\n        except ValueError as e:\n            return self.problem(400, \"malformed-json\", \"The body is not JSON\", str(e))\n        errors = sorted(({\"pointer\": pointer(e.absolute_path), \"detail\": e.message}\n                         for e in BOOK.iter_errors(value)), key=lambda e: e[\"pointer\"])\n        if errors:\n            return self.problem(422, \"invalid-book\", \"The book breaks the contract\",\n                                \"every problem with the book is listed in errors\", errors=errors)",
      "note": "Creating a book: the address, the media type and the JSON, as in `rest.py`. Then the schema, and `iter_errors` returns **every** error rather than the first, each one turned into a pointer and a sentence."
    },
    {
      "code": "        key = self.headers.get(\"Idempotency-Key\")\n        if key is not None and not 1 <= len(key) <= 200:\n            return self.problem(400, \"bad-idempotency-key\", \"Invalid Idempotency-Key\",\n                                \"a key is 1 to 200 characters\")\n        fingerprint = hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()",
      "note": "The optional `Idempotency-Key` header, and a fingerprint of the body: SHA-256 of the JSON with its keys sorted, so the same book sent with its fields in another order counts as the same request."
    },
    {
      "code": "        with db.connect() as conn:\n            conn.execute(KEYS)\n            conn.execute(\"BEGIN IMMEDIATE\")\n            seen = key and conn.execute(\"SELECT * FROM idempotency_keys WHERE key = ?\",\n                                        (key,)).fetchone()\n            if seen and seen[\"fingerprint\"] != fingerprint:\n                return self.problem(422, \"key-reused\", \"Idempotency-Key reused\",\n                                    \"this key came with a different book; use a new key\")\n            if seen:\n                return self.reply(201, json.loads(seen[\"body\"]),\n                                  [(\"Location\", seen[\"location\"]), (\"Idempotent-Replayed\", \"true\")])\n            try:\n                ident = conn.execute(\n                    \"INSERT INTO books (isbn, title, author_id, year, price_cents, stock)\"\n                    \" VALUES (?, ?, ?, ?, ?, ?)\",\n                    (value[\"isbn\"], value[\"title\"], value[\"author_id\"], value[\"year\"],\n                     value[\"price\"][\"amount_cents\"], value.get(\"stock\", 0))).lastrowid\n            except sqlite3.IntegrityError as e:\n                if \"UNIQUE\" in str(e):\n                    return self.problem(409, \"duplicate-isbn\", \"ISBN already in the catalogue\",\n                                        f\"another book has ISBN {value['isbn']}\")\n                return self.problem(422, \"invalid-book\", \"The book breaks the contract\",\n                                    \"every problem with the book is listed in errors\",\n                                    errors=[{\"pointer\": \"#/author_id\", \"detail\": \"no such author\"}])\n            created = book(conn.execute(\"SELECT * FROM books WHERE id = ?\", (ident,)).fetchone())\n            location = f\"/v1/books/{ident}\"\n            if key:\n                conn.execute(\"INSERT INTO idempotency_keys VALUES (?, ?, ?, ?, ?)\",\n                             (key, fingerprint, location, json.dumps(created, ensure_ascii=False),\n                              datetime.now(timezone.utc).isoformat(timespec=\"seconds\")))\n        return self.reply(201, created, [(\"Location\", location)])",
      "note": "**One transaction holds the key check, the new book and the stored answer.** `BEGIN IMMEDIATE` takes SQLite's write lock first, so two retries arriving together queue rather than both inserting, and a crash halfway leaves neither a book without its key nor a key without its book. A key seen before with the same body replays the stored answer; with a different body it is a 422."
    },
    {
      "code": "\n    def refuse(self):\n        self.problem(405, None, \"Method Not Allowed\", f\"the catalogue does not take {self.command}\",\n                     [(\"Allow\", \"GET, POST\")])\n\n    do_PUT = do_PATCH = do_DELETE = do_OPTIONS = refuse",
      "note": "The methods the catalogue does not take get a 405 with `Allow`, in the problem shape, instead of the HTML 501 that Python's library sent for `OPTIONS` in lesson 1."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Catalogue)\n    print(\"catalogue on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "The same port as `rest.py`, which is why only one of them can run at a time."
    }
  ]
}
```
