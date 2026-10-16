---
title: Mutations, and errors that arrive with a 200
version: 1
---

**A mutation is a field of the `Mutation` root, and it is written like a query with the word
`mutation` in front.** It takes arguments, changes something, and returns an object whose fields
the client selects as usual, so the client reads back the new state in the same request. There is
one rule that differs from a query: the specification requires the top-level fields of a mutation
to run **one after another, in the order they are written**, so a request that writes twice knows
which write happened first.

The request below sets two stocks at once: book 1 to 10, which is fine, and book 2 to -1, which the
database's `CHECK (stock >= 0)` refuses. `-i` shows the status line:

```
ana@api:~/shelf$ curl -si localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "mutation { a: setStock(bookId: 1, stock: 10) { title stock } b: setStock(bookId: 2, stock: -1) { title stock } }"}'
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:38:15 GMT
Content-Type: application/json
Content-Length: 239

{"data": {"a": {"title": "Dom Casmurro", "stock": 10}, "b": null}, "errors": [{"message": "stock -1 refused: CHECK constraint failed: stock >= 0", "locations": [{"line": 1, "column": 62}], "path": ["b"]}], "extensions": {"sqlQueries": 3}}
```

## Partial data, and where the error is

**The answer is 200 OK, with both `data` and `errors` in it.** `a` succeeded and holds the new
stock. `b` is `null`, and the error beside it names the field with `path`, `["b"]`, and the place in
the query with `locations`. It is a partial success, and the database agrees:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ a: book(id: 1) { stock } b: book(id: 2) { stock } }"}' | jq -c .data
{"a":{"stock":10},"b":{"stock":7}}
```

Book 1 now has 10 and book 2 still has 7. Each field committed on its own; nothing made the two
writes one transaction, and nothing in GraphQL does. A client that needs all or nothing asks for one
mutation that does all of it, designed that way in the schema.

The `null` stopped at `b` because `setStock` returns `Book`, which may be null. Had the schema said
`Book!`, the server could not put `null` there without breaking its own promise, so the `null`
would climb to the nearest field that allows one: here that is the whole of `data`, and the answer
would carry the error and no data at all. That is the other side of the advice in the section on
the schema: a non-null field that fails takes its parent down with it.

## What a 200 means now

In `rest.py` the status code carried the outcome, and lesson 1 argued that a client branches on it.
In GraphQL **a 200 only says the query ran.** The terminal of the server shows the same thing a
monitoring system would see, three statements and an ordinary success:

```
  sql: UPDATE books SET stock = 10 WHERE id = '1'
  sql: SELECT * FROM books WHERE id = '1'
  sql: UPDATE books SET stock = -1 WHERE id = '2'
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

Two consequences, one on each side.

- Monitoring that counts 5xx and 4xx answers sees nothing wrong with this request, or with a
  hundred like it. A GraphQL server has to count the errors in its bodies itself, by field, and send
  that number to wherever the alarms live.
- A client must read `errors` on every answer. A wrapper that only throws when the status is not
  2xx will hand the screen a `null` and no explanation.

`graph.py` does answer 400 in one case: when nothing ran, because the query did not parse, failed
validation, or was too deep. The client then has to change the request, which is what a 4xx means.
Servers differ on this, and some answer 200 even then; once execution has started, 200 is what you
will see almost everywhere.

Some schemas take a further step and make an expected failure part of the data: `setStock` would
return an object with either the book or a `problem` field the client must look at. The error is
then typed, documented in the schema, and impossible to overlook, and `errors` is left for the
failures nobody planned for.
