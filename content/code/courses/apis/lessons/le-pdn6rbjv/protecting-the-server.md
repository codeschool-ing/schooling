---
title: Protecting the server
version: 1
---

**In REST the server decides how much work one request can cause. In GraphQL the client does.** An
endpoint of `rest.py` runs the same queries whoever calls it. A query to `graph.py` can ask for a
tree as wide and as deep as the schema allows, and in a bookshop where a book has an author and an
author has books, the tree has no bottom.

So counting requests, which is how lesson 12 limits a client, does not measure the load here. One
request of fifty characters, books, their authors, those authors' books and their authors again:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { name } } } } }"}' | jq -c .extensions
{"sqlQueries":23}
```

Twenty-three SQL queries for one request, on a shop with six books. Each level multiplies the one
above it, and batching only divides the total:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The query books, author, books, author, name, level by level. Level 1 returns 6 books, level 2 six authors, level 3 ten books, level 4 ten authors. SQL without --batch: 1, 6, 6 and 10, 23 in all. With --batch: 1, 1, 6 and 0, 8 in all.\"><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">SQL, off</text><text x=\"650\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">SQL, on</text><text x=\"220\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">objects returned</text><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"150\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"650\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"32\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><rect x=\"150\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"650\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"44\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"150\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"330\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"360\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"390\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"420\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"650\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"56\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><rect x=\"150\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"330\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"360\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"390\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"420\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"650\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">0</text><line x1=\"520\" y1=\"212\" x2=\"690\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"560\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">23</text><text x=\"650\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">8</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one request, 50 characters of query</text></svg>", "caption": "A query five levels deep, books, author, books, author, name, and inside the limit. Each level multiplies the one above it, and the SQL count follows; batching cuts it from 23 to 8 but does not stop the multiplying."}
```

## A depth limit

The simplest defence refuses a query that goes too deep, before running any of it. `graph.py`
counts the fields on the longest path of the query, following fragments, and refuses anything past
`MAX_DEPTH`, which is 5. One level more than the query above:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { books { title } } } } } }"}' -w '%{http_code}\n'
{"errors": [{"message": "the query is 6 levels deep and the limit is 5"}]}
400
```

Refused with 400, without a single SQL statement. Depth is a crude measure, though. A query can be
shallow and still wide, asking for every list the schema has side by side, and a list argument such
as `books(first: 1000)` makes one level as expensive as several.

It also catches more than you meant. The query that tools send to read a whole schema, the one the
previous section's editors and generators rely on, is deeper than the limit:

```
ana@api:~/shelf$ python3 -c 'import graph, graphql; print(graph.deepest(graphql.parse(graphql.get_introspection_query())))'
13
```

Thirteen levels, so `graph.py` as written would refuse the tools. Servers with a depth limit exempt
the introspection fields or measure them separately, which is one more line of code nobody writes
until the editor stops working.

## A cost limit

The better measure gives every field a **cost**, multiplies the cost of a list's fields by how many
items the list can return, and refuses a query whose total is over a budget. It needs every list to
have a limit the server knows, which is a good rule anyway: an argument such as `first` with a
maximum, rather than a list that returns whatever the table holds. Several GraphQL servers and
gateways have cost analysis built in, and the same number makes a better rate limit than a count
of requests.

## Persisted queries

The strongest defence removes the language from the request. With **persisted queries**, every
query a client will ever send is registered on the server when the client is built, and the client
sends only its id or its hash, with the variables. The server runs the queries it knows and refuses
any other text. It turns an open query language into a fixed list of operations, each one measured
before it ships, and it suits exactly the case where you write every client yourself.

## Why HTTP caching is harder

To anything that only sees HTTP, the last requests of this lesson look alike: a write that half
failed, a read, two questions about the schema and a refused query, all the same method to the same
address:

```
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
  sql: SELECT * FROM books WHERE id = '1'
  sql: SELECT * FROM books WHERE id = '2'
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 400 -
```

An HTTP cache, in a browser or in front of a server, stores answers under their method and address,
and in practice it does not store a `POST` at all. With one address and one method for everything, the request
line says nothing about what was asked. GraphQL over HTTP allows a read to be sent as a `GET`, with
the query in the address; `graph.py` refuses that:

```
ana@api:~/shelf$ curl -si 'localhost:8000/graphql?query=%7Bbooks%7Btitle%7D%7D'
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:38:16 GMT
Content-Type: application/json
Content-Length: 66
Allow: POST

{"errors": [{"message": "send the query with POST to /graphql"}]}
```

A server that takes `GET` gets cacheable addresses back, but a whole query in every address is long
and unstable. Persisted queries fix that as well: the address carries a short id and the variables,
the same for every client asking the same thing. GraphQL clients also keep a cache of their own,
storing each object by its type and `id`, which is one more reason every object type in the schema
should have one.
