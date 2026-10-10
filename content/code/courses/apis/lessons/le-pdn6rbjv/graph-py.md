---
title: graph.py
version: 1
---

`graph.py` is the bookshop again, as a GraphQL API this time. It reads the same `shelf.db` through
the same `db.py`, so the books you changed in lesson 1 are the books it serves. Like `rest.py` it
is built on Python's own `http.server`; what it adds is `graphql`, the package lesson 1 installed
as `python3-graphql-core`, which parses a query, checks it against the schema and runs it.

It also does two things a real server would not do for every request. It prints each SQL statement
it runs in the server's terminal, and it tells the client how many there were, so that the cost of
a query is something you can read rather than guess.

**Both servers listen on port 8000, so only one can run at a time.** Stop `rest.py` with `Ctrl+C` in
the second terminal. Then, in the first, `nano graph.py`, paste the file below and save it:

```schooling-example
{
  "language": "python",
  "file": "shelf/graph.py",
  "parts": [
    {
      "code": "# shelf/graph.py\n\"\"\"The bookshop as a GraphQL API: one address, POST /graphql.\n\nRun it with `python3 graph.py`, or `python3 graph.py --batch` to fetch\nauthors in batches. It answers on http://127.0.0.1:8000.\n\"\"\"\nimport asyncio\nimport inspect\nimport json\nimport sqlite3\nimport sys\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nfrom graphql import GraphQLError, build_schema, execute, parse, validate\nfrom graphql.language import FieldNode, FragmentSpreadNode, OperationDefinitionNode\n\nimport db",
      "note": "The standard library again, plus `graphql`, the package lesson 1 installed as `python3-graphql-core`. `build_schema` turns the schema's text into an object; `parse`, `validate` and `execute` are the three steps every request goes through; the three node classes are what the depth limit looks for. `db.py` is the file `rest.py` uses, so the two APIs read one database."
    },
    {
      "code": "\nBATCH = \"--batch\" in sys.argv\nMAX_DEPTH = 5",
      "note": "Two settings. `--batch` on the command line changes how a book finds its author, which the section on the N+1 problem measures. `MAX_DEPTH` is how many fields deep a query may go, and the section on protecting the server tries to get past it."
    },
    {
      "code": "\nschema = build_schema(\"\"\"\ntype Query {\n  books(authorId: ID): [Book!]!\n  book(id: ID!): Book\n  author(id: ID!): Author\n}\n\ntype Mutation {\n  setStock(bookId: ID!, stock: Int!): Book\n}\n\ntype Book {\n  id: ID!\n  isbn: String!\n  title: String!\n  year: Int!\n  priceCents: Int!\n  stock: Int!\n  author: Author!\n}\n\ntype Author {\n  id: ID!\n  name: String!\n  country: String!\n  books: [Book!]!\n}\n\"\"\")",
      "note": "The schema the previous section explains, handed to `build_schema` as a string. A mistake in it stops the program at start-up, before any request arrives."
    },
    {
      "code": "\n\ndef resolves(type_name, field):\n    \"\"\"Attach the function below it to one field of the schema.\"\"\"\n    def attach(fn):\n        schema.get_type(type_name).fields[field].resolve = fn\n        return fn\n    return attach\n\n\ndef rows(info, sql, *args):\n    return [dict(r) for r in info.context[\"db\"].execute(sql, args)]\n\n\ndef row(info, sql, *args):\n    found = rows(info, sql, *args)\n    return found[0] if found else None",
      "note": "`resolves` attaches a function to one field of the schema, which is how a schema built from text gets its code. `rows` and `row` run SQL on the request's connection, kept in `info.context`, and turn each row into a dict, because the default resolver looks a field up in a dict by its name."
    },
    {
      "code": "\n\n@resolves(\"Query\", \"books\")\ndef all_books(parent, info, authorId=None):\n    if authorId is None:\n        return rows(info, \"SELECT * FROM books ORDER BY id\")\n    return rows(info, \"SELECT * FROM books WHERE author_id = ? ORDER BY id\", authorId)\n\n\n@resolves(\"Query\", \"book\")\ndef one_book(parent, info, id):\n    return row(info, \"SELECT * FROM books WHERE id = ?\", id)\n\n\n@resolves(\"Query\", \"author\")\ndef one_author(parent, info, id):\n    return row(info, \"SELECT * FROM authors WHERE id = ?\", id)",
      "note": "The three ways into `Query`. Each function receives the object above it, `parent`, which at the root is nothing, then `info`, then the field's arguments by name. `authorId` defaults to `None` because the schema lets a client leave it out."
    },
    {
      "code": "\n\n@resolves(\"Book\", \"priceCents\")\ndef price_cents(book, info):\n    return book[\"price_cents\"]\n\n\n@resolves(\"Book\", \"author\")\ndef book_author(book, info):\n    if BATCH:\n        return info.context[\"authors\"].load(book[\"author_id\"])\n    return row(info, \"SELECT * FROM authors WHERE id = ?\", book[\"author_id\"])\n\n\n@resolves(\"Author\", \"books\")\ndef author_books(author, info):\n    return rows(info, \"SELECT * FROM books WHERE author_id = ? ORDER BY id\", author[\"id\"])",
      "note": "The fields of `Book` and `Author` that need code. `priceCents` only renames the column `price_cents`; `author` and `books` each run a query for the one object they belong to. `title`, `year`, `name` and the rest have no function at all: the default resolver finds them in the dict."
    },
    {
      "code": "\n\n@resolves(\"Mutation\", \"setStock\")\ndef set_stock(parent, info, bookId, stock):\n    try:\n        with info.context[\"db\"]:\n            info.context[\"db\"].execute(\"UPDATE books SET stock = ? WHERE id = ?\", (stock, bookId))\n    except sqlite3.IntegrityError as e:\n        raise GraphQLError(f\"stock {stock} refused: {e}\")\n    return row(info, \"SELECT * FROM books WHERE id = ?\", bookId)",
      "note": "The one mutation. The database's own `CHECK (stock >= 0)` refuses a negative stock, and the resolver turns that into a `GraphQLError`, which lands in the response's `errors` with the path of the field that failed."
    },
    {
      "code": "\n\nclass Loader:\n    \"\"\"Hands out a promise for each author id, then fetches them all in one query.\"\"\"\n\n    def __init__(self, conn):\n        self.conn, self.promised, self.waiting = conn, {}, []\n\n    def load(self, ident):\n        if ident not in self.promised:\n            loop = asyncio.get_running_loop()\n            if not self.waiting:\n                loop.call_soon(self.fetch)\n            self.promised[ident] = loop.create_future()\n            self.waiting.append(ident)\n        return self.promised[ident]\n\n    def fetch(self):\n        ids, self.waiting = self.waiting, []\n        marks = \", \".join(\"?\" * len(ids))\n        found = {r[\"id\"]: dict(r) for r in\n                 self.conn.execute(f\"SELECT * FROM authors WHERE id IN ({marks})\", ids)}\n        for ident in ids:\n            self.promised[ident].set_result(found.get(ident))",
      "note": "The batching loader, used only with `--batch`. `load` hands back a promise, an asyncio future, instead of an author, and asks the event loop to call `fetch` as soon as it is free. By then every book in the list has asked for its author, so `fetch` gets the ids together and answers all of them with one `WHERE id IN (…)`."
    },
    {
      "code": "\n\ndef depth(selections, fragments):\n    \"\"\"How many fields deep a selection goes, following fragments into their own.\"\"\"\n    deepest = 0\n    for node in selections:\n        if isinstance(node, FieldNode):\n            below = node.selection_set.selections if node.selection_set else []\n            deepest = max(deepest, 1 + depth(below, fragments))\n        elif isinstance(node, FragmentSpreadNode):\n            deepest = max(deepest, depth(fragments[node.name.value], fragments))\n        else:\n            deepest = max(deepest, depth(node.selection_set.selections, fragments))\n    return deepest\n\n\ndef deepest(document):\n    fragments = {d.name.value: d.selection_set.selections for d in document.definitions\n                 if not isinstance(d, OperationDefinitionNode)}\n    return max(depth(d.selection_set.selections, fragments) for d in document.definitions\n               if isinstance(d, OperationDefinitionNode))",
      "note": "The depth limit's arithmetic: the number of fields on the longest path from the top of the query down to a leaf, following a fragment into its own fields. It reads the parsed query and runs before any resolver does."
    },
    {
      "code": "\n\nasync def run(document, body, context):\n    result = execute(schema, document, variable_values=body.get(\"variables\"),\n                     operation_name=body.get(\"operationName\"), context_value=context)\n    return await result if inspect.isawaitable(result) else result",
      "note": "`execute` returns the result at once when every resolver answered at once, and something to wait for when one of them handed back a promise, which is what the loader does. `run` copes with both."
    },
    {
      "code": "\n\nclass Graph(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def refuse(self, status, message, headers=()):\n        self.reply(status, {\"errors\": [{\"message\": message}]}, headers)\n\n    def do_GET(self):\n        self.refuse(405, \"send the query with POST to /graphql\", [(\"Allow\", \"POST\")])",
      "note": "Every answer is JSON, with an `errors` list when something went wrong, the shape a GraphQL client already reads. A `GET` is refused with 405: this server takes its queries by `POST` only."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        if self.path != \"/graphql\":\n            return self.refuse(404, \"the API is at /graphql\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.refuse(415, \"send the query as application/json\")\n        try:\n            body = json.loads(raw)\n            document = parse(body[\"query\"])\n        except GraphQLError as e:\n            return self.reply(400, {\"errors\": [e.formatted]})\n        except (ValueError, TypeError, KeyError):\n            return self.refuse(400, 'send a JSON object with the query in \"query\"')",
      "note": "Before the query is read at all: one address, `/graphql`, and a JSON body. A query that does not parse answers 400, with the line and column of the mistake."
    },
    {
      "code": "        errors = validate(schema, document)\n        if errors:\n            return self.reply(400, {\"errors\": [e.formatted for e in errors]})\n        levels = deepest(document)\n        if levels > MAX_DEPTH:\n            return self.refuse(400, f\"the query is {levels} levels deep and the limit is {MAX_DEPTH}\")",
      "note": "Then the two checks that need no database. `validate` holds the query against the schema and refuses a field that does not exist; the depth limit refuses a query that goes too deep. Both answer 400, because nothing ran."
    },
    {
      "code": "\n        sql = []\n        conn = db.connect()\n        conn.set_trace_callback(sql.append)\n        result = asyncio.run(run(document, body, {\"db\": conn, \"authors\": Loader(conn)}))\n        conn.close()\n        sql = [s for s in sql if s.split()[0] in (\"SELECT\", \"UPDATE\")]\n        for statement in sql:\n            print(\"  sql:\", statement, file=sys.stderr, flush=True)\n        self.reply(200, {**result.formatted, \"extensions\": {\"sqlQueries\": len(sql)}})",
      "note": "Execution. `set_trace_callback` hands every statement the connection runs to `sql.append`, so the count is exact. Each statement is printed in the server's terminal, and the count goes back to the client in `extensions`, the key the GraphQL specification leaves for a server's own additions. The status is **200** whether or not `errors` is in the body."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Graph)\n    print(f\"graph on http://127.0.0.1:8000/graphql, batch {'on' if BATCH else 'off'}\", flush=True)\n    server.serve_forever()",
      "note": "The same address as `rest.py`, so only one of the two can run at a time. The first line it prints says whether batching is on."
    }
  ]
}
```

## Running it

In the second terminal:

```sh
cd ~/shelf && python3 graph.py
```

It prints one line and waits:

```
graph on http://127.0.0.1:8000/graphql, batch off
```

The book page from the previous section is now one request. The query names the book, the fields
it wants from it, the author and the author's books; the answer has exactly the shape of the
question, nested the same way:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ book(id: 2) { title author { name books { title } } } }"}' | jq .
{
  "data": {
    "book": {
      "title": "Memórias Póstumas de Brás Cubas",
      "author": {
        "name": "Machado de Assis",
        "books": [
          {
            "title": "Dom Casmurro"
          },
          {
            "title": "Memórias Póstumas de Brás Cubas"
          }
        ]
      }
    }
  },
  "extensions": {
    "sqlQueries": 3
  }
}
```

`extensions` is not part of the data. It is `graph.py` reporting its own work, three SQL queries,
and the next sections lean on it.

The list of titles that cost 797 bytes from `rest.py` costs this, `extensions` included:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title } }"}' | wc -c
268
```
