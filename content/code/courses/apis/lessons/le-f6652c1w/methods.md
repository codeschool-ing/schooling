---
title: The methods, and what each one promises
version: 1
---

HTTP has a short list of methods, and each comes with two promises that clients rely on without
asking. A method is **safe** if it changes nothing on the server, and **idempotent** if sending it
twice leaves the server exactly as sending it once did.

| method | what it does to a resource | safe | idempotent |
|---|---|---|---|
| `GET` | reads it | yes | yes |
| `POST` | creates one inside a collection, or does something that fits no other method | no | **no** |
| `PUT` | replaces it with the body, whole | no | yes |
| `PATCH` | changes the fields the body names, and leaves the rest | no | not promised |
| `DELETE` | removes it | no | yes |

**These promises are what lets the network help you.** A browser prefetches links because `GET` is
safe. A client whose connection dropped halfway through a `PUT` sends it again, because it is
idempotent and a second copy cannot hurt. Nobody may retry a `POST` blindly, because two copies may
create two orders; lesson 2 shows the header that makes a `POST` safe to retry. Break a promise, a
`GET /books/7/delete` for instance, and the network will act on the promise anyway: a crawler following
links would empty the catalogue.

## POST creates

A new book goes to the collection, and the server decides its id. The answer is **201 Created**, and
the `Location` header says where the new item lives:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 124
Location: /v1/books/7

{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990, "stock": 0}
```

The same request a second time is not a second copy of the book. It is refused with **409 Conflict**,
because the ISBN is unique in the database, and the body says which rule it broke. The
`-w '%{http_code}\n'` asks curl to print the status after the body:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990}'
{"error": "conflict: UNIQUE constraint failed: books.isbn"}
409
```

That refusal is the data protecting itself, and it is luck, not the method. A table with no unique
column would have stored the same book twice, with ids 7 and 8.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Sending the same PUT twice leaves the shelf in the same state as sending it once: book 7 costs 4190 after the first and after the second. Sending the same POST twice tries to create two books; here the second is refused with 409 because the ISBN is already taken, and without that rule it would have created book 8.\"><defs><marker id=\"idem-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">PUT /v1/books/7, twice</text><rect x=\"20\" y=\"40\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text><text x=\"115.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">book 7 costs 4190</text><rect x=\"250\" y=\"40\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text><text x=\"345.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">book 7 costs 4190</text><line x1=\"210\" y1=\"65\" x2=\"248\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#idem-ah)\"></line><text x=\"470\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">same state: idempotent</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">POST /v1/books, twice</text><rect x=\"20\" y=\"155\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">201</text><text x=\"115.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">book 7 created</text><rect x=\"250\" y=\"155\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">409</text><text x=\"345.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ISBN already taken</text><line x1=\"210\" y1=\"180\" x2=\"248\" y2=\"180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#idem-ah)\"></line><text x=\"470\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a second book, unless a rule</text><text x=\"470\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">in the data refuses it</text><text x=\"250\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">without the UNIQUE ISBN: 201, book 8</text></svg>", "caption": "Idempotent means the second identical request changes nothing the first did not."}
```

## PUT replaces, PATCH changes

`PUT` sends the whole book, and the book becomes exactly that. Sending the same `PUT` twice gives the
same answer twice, and the same state, which is what idempotent means:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}
200
```

Because it replaces, a `PUT` that leaves out fields is not a smaller change; it is a book with fields
missing, and shelf refuses it. `PATCH` is the method for "change only this":

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"stock": 5}'
{"error": "missing fields: author_id, isbn, price_cents, title, year"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"stock": 5}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 5}
200
```

`PATCH` is not promised idempotent because it does not have to be. `{"stock": 5}` is, sent ten times,
but a patch that says "add one to the stock" would not be, and the method allows both. shelf's
patches only ever set values, which makes them idempotent in practice; a client cannot know that
without being told, so it should not retry one blindly either.

## DELETE removes

The first `DELETE` answers **204 No Content**: it worked, and there is nothing to send back. The
second answers **404**, because there is nothing left to delete.

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books/7
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X DELETE localhost:8000/v1/books/7
{"error": "no book 7"}
404
```

Is a 404 on the second `DELETE` a broken promise? No. Idempotence is about the **state of the
server**, not about the answer: after one `DELETE` or after two, book 7 is gone. A client retrying a
`DELETE` should read a 404 as "already done".

A method sent to an address that does not take it answers **405 Method Not Allowed**, and the `Allow`
header lists the methods that address does take. Deleting the whole collection is not something shelf
offers:

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Type: application/json
Content-Length: 43
Allow: GET, POST

{"error": "DELETE needs a book's address"}
```
