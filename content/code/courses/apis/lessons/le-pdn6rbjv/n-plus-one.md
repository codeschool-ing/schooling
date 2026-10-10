---
title: The N+1 problem
version: 1
---

**A resolver runs once per object, so a field under a list runs once per item, and if it reaches
the database it runs one query per item.** A list of N books, each asking for its author, costs
one query for the list and N more for the authors. That is the **N+1 problem**, and every GraphQL
server written the obvious way has it.

It is easy to believe GraphQL solved this. The page that cost `rest.py` seven requests in the
first section is one request to `graph.py`, so the problem looks gone. It moved. Ask for every
title with its author's name:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title author { name } } }"}' | jq -c .extensions
{"sqlQueries":7}
```

Seven SQL queries, and the server's terminal shows which ones:

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM authors WHERE id = 2
  sql: SELECT * FROM authors WHERE id = 2
  sql: SELECT * FROM authors WHERE id = 3
  sql: SELECT * FROM authors WHERE id = 4
127.0.0.1 - - [10/Oct/2026 01:38:14] "POST /graphql HTTP/1.1" 200 -
```

They are the seven requests of the REST page, made by the server instead of by the client. On one
machine with SQLite that costs very little. On a database across a network, each of those queries
is a round trip of its own, and a list of a hundred books becomes a hundred and one of them.

## Batching

The way out is to stop asking for authors one at a time. The resolver for `Book.author` does not
fetch anything; it hands back a promise for author 1, or author 2, and moves on. Once every book in
the list has asked, and the server has nothing left to do but wait for promises, one query fetches
all the authors that were asked for, and each promise is kept from its result. `Loader` in
`graph.py` is that, in twenty lines: `load` collects the ids and `fetch` asks for them with
`WHERE id IN (…)`. The pattern is usually called a **data loader**, after DataLoader, the
JavaScript library Facebook published for it, and most GraphQL servers have one.

Stop the server with `Ctrl+C` and start it with batching on:

```sh
python3 graph.py --batch
```

The same query:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title author { name } } }"}' | jq -c .extensions
{"sqlQueries":2}
```

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id IN (1, 2, 3, 4)
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

Two queries instead of seven, and author 1 was asked for once. The loader does not only batch,
it remembers: an id that was already promised during this request is not fetched again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two rows of SQL queries for the query books with title and author name. Without --batch: one query for the books, then six for authors 1, 1, 2, 2, 3 and 4, seven in all. With --batch: one for the books and one for authors WHERE id IN (1, 2, 3, 4), two in all.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">without --batch</text><rect x=\"20\" y=\"44\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"122\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"159.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 1</text><rect x=\"204\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"241.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 1</text><rect x=\"286\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"323.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 2</text><rect x=\"368\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 2</text><rect x=\"450\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"487.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 3</text><rect x=\"532\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 4</text><text x=\"640\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">7 queries</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">with --batch</text><rect x=\"20\" y=\"126\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"122\" y=\"126\" width=\"238\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"241.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">authors IN (1, 2, 3, 4)</text><text x=\"640\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">2 queries</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 for the list, then 1 per book: that is the N+1</text></svg>", "caption": "The SQL behind one query for every title and its author's name, as graph.py printed it. Without the loader every book asks for its own author, and authors 1 and 2 are each fetched twice; with it the six lookups become one."}
```

## What one loader does not fix

A loader fixes the field it was written for. Go further down: each book's author, that author's
books, and their authors again:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { name } } } } }"}' | jq -c .extensions
{"sqlQueries":8}
```

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id IN (1, 2, 3, 4)
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 2 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 2 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 3 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 4 ORDER BY id
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

The authors arrived in one query, and the ten on the last level cost nothing at all, because every
one of them had already been promised. `Author.books` has no loader, and it went back to one query
per author: six of them, with the books of authors 1 and 2 asked for twice. Every field that reaches the database
from inside a list needs its own loader, and finding the ones that are missing is what a count like
`sqlQueries` is for. The same query without `--batch` cost 23.

A loader lives for one request, and that is deliberate. Shared between requests it would be a
cache, with every question a cache brings: how long an author stays fresh, and whether one user's
answer may be shown to another.
