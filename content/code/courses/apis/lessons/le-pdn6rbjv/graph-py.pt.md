---
title: graph.py
version: 1
---

O `graph.py` é a livraria de novo, agora como uma API GraphQL. Ele lê o mesmo `shelf.db` pelo mesmo
`db.py`, então os livros que você alterou na lição 1 são os livros que ele serve. Como o `rest.py`,
ele é construído sobre o `http.server` do próprio Python; o que ele acrescenta é o `graphql`, o
pacote que a lição 1 instalou como `python3-graphql-core`, que analisa uma consulta, confere contra o
esquema e a executa.

Ele também faz duas coisas que um servidor de verdade não faria em toda requisição. Imprime cada
comando SQL que roda no terminal do servidor, e diz ao cliente quantos foram, para que o custo de uma
consulta seja algo que você lê em vez de adivinhar.

**Os dois servidores escutam na porta 8000, então só um roda por vez.** Pare o `rest.py` com `Ctrl+C` no
segundo terminal. Depois, no primeiro, `nano graph.py`, cole o arquivo abaixo e salve:

```schooling-example
{
  "language": "python",
  "file": "shelf/graph.py",
  "parts": [
    {
      "code": "# shelf/graph.py\n\"\"\"The bookshop as a GraphQL API: one address, POST /graphql.\n\nRun it with `python3 graph.py`, or `python3 graph.py --batch` to fetch\nauthors in batches. It answers on http://127.0.0.1:8000.\n\"\"\"\nimport asyncio\nimport inspect\nimport json\nimport sqlite3\nimport sys\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nfrom graphql import GraphQLError, build_schema, execute, parse, validate\nfrom graphql.language import FieldNode, FragmentSpreadNode, OperationDefinitionNode\n\nimport db",
      "note": "A biblioteca padrão de novo, mais o `graphql`, o pacote que a lição 1 instalou como `python3-graphql-core`. `build_schema` transforma o texto do esquema em um objeto; `parse`, `validate` e `execute` são os três passos por que passa toda requisição; as três classes de nó são o que o limite de profundidade procura. O `db.py` é o mesmo que o `rest.py` usa, então as duas APIs leem um só banco."
    },
    {
      "code": "\nBATCH = \"--batch\" in sys.argv\nMAX_DEPTH = 5",
      "note": "Duas configurações. `--batch` na linha de comando muda o jeito como um livro encontra seu autor, e a seção sobre o problema N+1 mede isso. `MAX_DEPTH` é quantos campos de profundidade uma consulta pode ter, e a seção sobre proteger o servidor tenta passar dele."
    },
    {
      "code": "\nschema = build_schema(\"\"\"\ntype Query {\n  books(authorId: ID): [Book!]!\n  book(id: ID!): Book\n  author(id: ID!): Author\n}\n\ntype Mutation {\n  setStock(bookId: ID!, stock: Int!): Book\n}\n\ntype Book {\n  id: ID!\n  isbn: String!\n  title: String!\n  year: Int!\n  priceCents: Int!\n  stock: Int!\n  author: Author!\n}\n\ntype Author {\n  id: ID!\n  name: String!\n  country: String!\n  books: [Book!]!\n}\n\"\"\")",
      "note": "O esquema que a seção anterior explica, entregue ao `build_schema` como texto. Um erro nele derruba o programa na partida, antes de chegar qualquer requisição."
    },
    {
      "code": "\n\ndef resolves(type_name, field):\n    \"\"\"Attach the function below it to one field of the schema.\"\"\"\n    def attach(fn):\n        schema.get_type(type_name).fields[field].resolve = fn\n        return fn\n    return attach\n\n\ndef rows(info, sql, *args):\n    return [dict(r) for r in info.context[\"db\"].execute(sql, args)]\n\n\ndef row(info, sql, *args):\n    found = rows(info, sql, *args)\n    return found[0] if found else None",
      "note": "`resolves` prende uma função a um campo do esquema, que é como um esquema montado a partir de texto ganha código. `rows` e `row` rodam SQL na conexão da requisição, guardada em `info.context`, e transformam cada linha em um dict, porque o resolver padrão procura o campo em um dict pelo nome."
    },
    {
      "code": "\n\n@resolves(\"Query\", \"books\")\ndef all_books(parent, info, authorId=None):\n    if authorId is None:\n        return rows(info, \"SELECT * FROM books ORDER BY id\")\n    return rows(info, \"SELECT * FROM books WHERE author_id = ? ORDER BY id\", authorId)\n\n\n@resolves(\"Query\", \"book\")\ndef one_book(parent, info, id):\n    return row(info, \"SELECT * FROM books WHERE id = ?\", id)\n\n\n@resolves(\"Query\", \"author\")\ndef one_author(parent, info, id):\n    return row(info, \"SELECT * FROM authors WHERE id = ?\", id)",
      "note": "As três entradas de `Query`. Cada função recebe o objeto acima dela, `parent`, que na raiz não é nada, depois `info`, depois os argumentos do campo pelo nome. `authorId` tem `None` como padrão porque o esquema deixa o cliente omiti-lo."
    },
    {
      "code": "\n\n@resolves(\"Book\", \"priceCents\")\ndef price_cents(book, info):\n    return book[\"price_cents\"]\n\n\n@resolves(\"Book\", \"author\")\ndef book_author(book, info):\n    if BATCH:\n        return info.context[\"authors\"].load(book[\"author_id\"])\n    return row(info, \"SELECT * FROM authors WHERE id = ?\", book[\"author_id\"])\n\n\n@resolves(\"Author\", \"books\")\ndef author_books(author, info):\n    return rows(info, \"SELECT * FROM books WHERE author_id = ? ORDER BY id\", author[\"id\"])",
      "note": "Os campos de `Book` e `Author` que precisam de código. `priceCents` só renomeia a coluna `price_cents`; `author` e `books` rodam cada um uma consulta para o objeto a que pertencem. `title`, `year`, `name` e os outros não têm função nenhuma: o resolver padrão os encontra no dict."
    },
    {
      "code": "\n\n@resolves(\"Mutation\", \"setStock\")\ndef set_stock(parent, info, bookId, stock):\n    try:\n        with info.context[\"db\"]:\n            info.context[\"db\"].execute(\"UPDATE books SET stock = ? WHERE id = ?\", (stock, bookId))\n    except sqlite3.IntegrityError as e:\n        raise GraphQLError(f\"stock {stock} refused: {e}\")\n    return row(info, \"SELECT * FROM books WHERE id = ?\", bookId)",
      "note": "A única mutation. O próprio `CHECK (stock >= 0)` do banco recusa um estoque negativo, e o resolver transforma isso em um `GraphQLError`, que vai parar no `errors` da resposta com o caminho do campo que falhou."
    },
    {
      "code": "\n\nclass Loader:\n    \"\"\"Hands out a promise for each author id, then fetches them all in one query.\"\"\"\n\n    def __init__(self, conn):\n        self.conn, self.promised, self.waiting = conn, {}, []\n\n    def load(self, ident):\n        if ident not in self.promised:\n            loop = asyncio.get_running_loop()\n            if not self.waiting:\n                loop.call_soon(self.fetch)\n            self.promised[ident] = loop.create_future()\n            self.waiting.append(ident)\n        return self.promised[ident]\n\n    def fetch(self):\n        ids, self.waiting = self.waiting, []\n        marks = \", \".join(\"?\" * len(ids))\n        found = {r[\"id\"]: dict(r) for r in\n                 self.conn.execute(f\"SELECT * FROM authors WHERE id IN ({marks})\", ids)}\n        for ident in ids:\n            self.promised[ident].set_result(found.get(ident))",
      "note": "O loader que agrupa, usado só com `--batch`. `load` devolve uma promessa, um future do asyncio, em vez de um autor, e pede ao event loop que chame `fetch` assim que estiver livre. Até lá todo livro da lista já pediu seu autor, então `fetch` recebe os ids juntos e responde a todos com um único `WHERE id IN (…)`."
    },
    {
      "code": "\n\ndef depth(selections, fragments):\n    \"\"\"How many fields deep a selection goes, following fragments into their own.\"\"\"\n    deepest = 0\n    for node in selections:\n        if isinstance(node, FieldNode):\n            below = node.selection_set.selections if node.selection_set else []\n            deepest = max(deepest, 1 + depth(below, fragments))\n        elif isinstance(node, FragmentSpreadNode):\n            deepest = max(deepest, depth(fragments[node.name.value], fragments))\n        else:\n            deepest = max(deepest, depth(node.selection_set.selections, fragments))\n    return deepest\n\n\ndef deepest(document):\n    fragments = {d.name.value: d.selection_set.selections for d in document.definitions\n                 if not isinstance(d, OperationDefinitionNode)}\n    return max(depth(d.selection_set.selections, fragments) for d in document.definitions\n               if isinstance(d, OperationDefinitionNode))",
      "note": "A conta do limite de profundidade: o número de campos no caminho mais longo do topo da consulta até uma folha, seguindo um fragment para dentro dos campos dele. Ela lê a consulta já analisada e roda antes de qualquer resolver."
    },
    {
      "code": "\n\nasync def run(document, body, context):\n    result = execute(schema, document, variable_values=body.get(\"variables\"),\n                     operation_name=body.get(\"operationName\"), context_value=context)\n    return await result if inspect.isawaitable(result) else result",
      "note": "`execute` devolve o resultado na hora quando todo resolver respondeu na hora, e algo a esperar quando algum deles devolveu uma promessa, que é o que o loader faz. `run` dá conta dos dois casos."
    },
    {
      "code": "\n\nclass Graph(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def refuse(self, status, message, headers=()):\n        self.reply(status, {\"errors\": [{\"message\": message}]}, headers)\n\n    def do_GET(self):\n        self.refuse(405, \"send the query with POST to /graphql\", [(\"Allow\", \"POST\")])",
      "note": "Toda resposta é JSON, com uma lista `errors` quando algo deu errado, o formato que um cliente GraphQL já sabe ler. Um `GET` é recusado com 405: este servidor só recebe consultas por `POST`."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        if self.path != \"/graphql\":\n            return self.refuse(404, \"the API is at /graphql\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.refuse(415, \"send the query as application/json\")\n        try:\n            body = json.loads(raw)\n            document = parse(body[\"query\"])\n        except GraphQLError as e:\n            return self.reply(400, {\"errors\": [e.formatted]})\n        except (ValueError, TypeError, KeyError):\n            return self.refuse(400, 'send a JSON object with the query in \"query\"')",
      "note": "Antes de ler a consulta: um endereço só, `/graphql`, e um corpo JSON. Uma consulta que não passa na análise responde 400, com a linha e a coluna do erro."
    },
    {
      "code": "        errors = validate(schema, document)\n        if errors:\n            return self.reply(400, {\"errors\": [e.formatted for e in errors]})\n        levels = deepest(document)\n        if levels > MAX_DEPTH:\n            return self.refuse(400, f\"the query is {levels} levels deep and the limit is {MAX_DEPTH}\")",
      "note": "Depois, as duas verificações que não precisam do banco. `validate` confronta a consulta com o esquema e recusa um campo que não existe; o limite de profundidade recusa uma consulta funda demais. As duas respondem 400, porque nada rodou."
    },
    {
      "code": "\n        sql = []\n        conn = db.connect()\n        conn.set_trace_callback(sql.append)\n        result = asyncio.run(run(document, body, {\"db\": conn, \"authors\": Loader(conn)}))\n        conn.close()\n        sql = [s for s in sql if s.split()[0] in (\"SELECT\", \"UPDATE\")]\n        for statement in sql:\n            print(\"  sql:\", statement, file=sys.stderr, flush=True)\n        self.reply(200, {**result.formatted, \"extensions\": {\"sqlQueries\": len(sql)}})",
      "note": "A execução. `set_trace_callback` entrega cada comando que a conexão roda para `sql.append`, então a contagem é exata. Cada comando aparece no terminal do servidor, e a contagem volta ao cliente em `extensions`, a chave que a especificação do GraphQL reserva para os acréscimos do próprio servidor. O status é **200** tenha ou não `errors` no corpo."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Graph)\n    print(f\"graph on http://127.0.0.1:8000/graphql, batch {'on' if BATCH else 'off'}\", flush=True)\n    server.serve_forever()",
      "note": "O mesmo endereço do `rest.py`, então só um dos dois roda por vez. A primeira linha que ele imprime diz se o agrupamento está ligado."
    }
  ]
}
```

## Rodando

No segundo terminal:

```sh
cd ~/shelf && python3 graph.py
```

Ele imprime uma linha e espera:

```
graph on http://127.0.0.1:8000/graphql, batch off
```

A página de livro da seção anterior agora é uma requisição só. A consulta nomeia o livro, os campos
que quer dele, o autor e os livros do autor; a resposta tem exatamente o formato da pergunta,
aninhada do mesmo jeito:

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

`extensions` não faz parte dos dados. É o `graph.py` relatando o próprio trabalho, três consultas
SQL, e as próximas seções se apoiam nisso.

A lista de títulos que custou 797 bytes no `rest.py` custa isto, `extensions` incluído:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title } }"}' | wc -c
268
```
