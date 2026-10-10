---
title: The problem GraphQL answers
version: 1
---

**A REST endpoint decides the shape of its answer, and every client gets that shape.** That is
what made lesson 1's API easy to read, cache and document, and it has a price that grows with the
number of screens built on top of it. A screen needs a particular set of fields from a particular
set of resources, and the endpoints were cut along the resources, not along the screens. So the
screen gets more than it needs from one endpoint, and less than it needs from each.

Start `rest.py` again in the second terminal if it is not running, and look at both halves.

## More than the screen needs

A list of titles needs one field per book. `/v1/books/2` sends seven, and the collection sends all
seven for every book:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/2
{"id": 2, "isbn": "9786500000023", "title": "Memórias Póstumas de Brás Cubas", "author_id": 1, "year": 1881, "price_cents": 4490, "stock": 7}
ana@api:~/shelf$ curl -s localhost:8000/v1/books | wc -c
797
```

That is **over-fetching**: 797 bytes for a list whose titles are a fraction of it. On a desk with a
fast connection the waste is small, and it is the half people notice first. The other half costs
more.

## Less than the screen needs

A book's page shows the book, its author's name and the author's other books. No single address of
`rest.py` has all three, so the page asks three times:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/2 | jq -c '{title, author_id}'
{"title":"Memórias Póstumas de Brás Cubas","author_id":1}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/1 | jq -c '{name}'
{"name":"Machado de Assis"}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/1/books | jq -c '[.[].title]'
["Dom Casmurro","Memórias Póstumas de Brás Cubas"]
```

The second request cannot be written until the first has answered, because the author's id is in
the first answer. Three requests in a row cost three round trips, and on a phone network a round
trip is the expensive part. That is **under-fetching**: every answer is too small, so the client
makes up the difference with more requests.

A list is worse. A page showing every book with its author's name asks once for the books and then
once per book:

```
ana@api:~/shelf$ for a in $(curl -s localhost:8000/v1/books | jq ".[].author_id"); do curl -s localhost:8000/v1/authors/$a | jq -r .name; done
Machado de Assis
Machado de Assis
Clarice Lispector
Clarice Lispector
José Saramago
Chimamanda Ngozi Adichie
```

The server saw seven requests for one page, and asked the same question about Machado de Assis
twice:

```
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/2 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/2 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/3 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/4 HTTP/1.1" 200 -
```

## The two ways out

REST has answers of its own. The server can grow an endpoint per screen, a `/v1/book-pages/2` that
returns exactly what the page draws, or accept parameters that trim and widen an answer, such as
`?fields=title` and `?include=author`. Both work. Both mean the team that owns the server writes
something new for every screen, and the API slowly turns into a list of somebody's pages.

**GraphQL moves the decision to the client.** There is one address, and the request carries a
query that names every field the screen needs, across as many resources as it touches. Facebook
built it in 2012 for its mobile app, which had exactly this problem on slow networks, and published
it in 2015.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two sequence diagrams side by side. On the left, a client asks rest.py three times in a row: GET /v1/books/2 returns author_id 1, then GET /v1/authors/1 returns the name, then GET /v1/authors/1/books returns two titles. On the right, the client sends one POST /graphql and gets the book, the author and the books in one answer, while graph.py runs 3 SQL queries inside.\"><defs><marker id=\"l03-rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">REST: each request waits for the one before</text><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">GraphQL: one request</text><rect x=\"15\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><line x1=\"60\" y1=\"60\" x2=\"60\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"255\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rest.py</text><line x1=\"300\" y1=\"60\" x2=\"300\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"395\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><line x1=\"440\" y1=\"60\" x2=\"440\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"615\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">graph.py</text><line x1=\"660\" y1=\"60\" x2=\"660\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"370\" y1=\"30\" x2=\"370\" y2=\"292\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><line x1=\"62\" y1=\"90\" x2=\"297\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/books/2</text><line x1=\"298\" y1=\"120\" x2=\"63\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;author_id&quot;: 1</text><line x1=\"62\" y1=\"160\" x2=\"297\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/authors/1</text><line x1=\"298\" y1=\"190\" x2=\"63\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;name&quot;</text><line x1=\"62\" y1=\"230\" x2=\"297\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/authors/1/books</text><line x1=\"298\" y1=\"260\" x2=\"63\" y2=\"260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">two titles</text><line x1=\"442\" y1=\"90\" x2=\"657\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"549.5\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST /graphql</text><line x1=\"658\" y1=\"120\" x2=\"443\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"550.5\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">book, author and books</text><text x=\"660\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">3 SQL queries,</text><text x=\"660\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">inside the server</text><text x=\"550\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the query names every field</text><text x=\"550\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the page needs, and nothing else</text></svg>", "caption": "The same book page from both servers. rest.py needs three round trips, and the second cannot start until the first has said which author to ask for; graph.py needs one, and does the three lookups itself."}
```

The work did not disappear. `graph.py` still looks up the book, the author and the books, three
SQL queries; it does them inside the server, next to the database, instead of across the
network. Where that work can multiply is the subject of the section on the N+1 problem.
