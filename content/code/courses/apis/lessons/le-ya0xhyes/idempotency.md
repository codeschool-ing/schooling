---
title: Idempotency keys
version: 1
---

**A client whose POST went unanswered cannot tell whether it worked.** The request may have been lost
on the way in, or the book created and the response lost on the way out; from the client's side the
two look the same, a timeout. Retrying risks creating the book twice, and not retrying risks never
creating it. An `Idempotency-Key` header removes the dilemma: the client names the operation, and the
server recognises a retry of it and answers with what it answered the first time.

Lesson 1 showed why POST is the method with this problem: PUT and DELETE say what the end state
is, so sending them twice changes nothing, while POST says "create one more". The usual answer is to
rely on something in the data being unique. For books that half works, because the ISBN is unique. A
client that retries the creation of book 8 below, without a key, is told:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/duplicate-isbn", "title": "ISBN already in the catalogue", "status": 409, "detail": "another book has ISBN 9786500000085", "instance": "/v1/books"}
409
```

That stops the duplicate and leaves the client with the wrong question answered. A 409 says a book
with this ISBN exists; it does not say whether this client's first attempt created it or someone else
did, and an order, a payment or a message usually has no unique field to lean on at all.

## The key

The client makes up a key, unique to this one operation: a random UUID is the usual choice, and Linux
hands out a fresh one on every read of a file in `/proc`:

```
ana@api:~/shelf$ cat /proc/sys/kernel/random/uuid
b1a0b623-b2c3-4be8-a499-0dfce682ffe7
```

It sends the key with the first attempt and **the same key with every retry of that operation**, and
a new key for the next operation. This lesson types a fixed key, `3f1c9a2e-alienista`, so that the
three requests that use it can be repeated exactly. The first creates the book:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:43 GMT
Content-Type: application/json
Content-Length: 172
Location: /v1/books/8

{"id": 8, "isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}, "stock": 0, "in_stock": false}
```

The second is the retry, identical. Nothing new is created, and the answer is the stored one, with
the same `Location`, plus a header saying it is a replay:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:43 GMT
Content-Type: application/json
Content-Length: 172
Location: /v1/books/8
Idempotent-Replayed: true

{"id": 8, "isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}, "stock": 0, "in_stock": false}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A sequence between the client, catalogue.py and the database. The client sends POST with Idempotency-Key 3f1c9a2e-alienista. In one transaction the server inserts book 8 and stores the key with the response, and the 201 is lost on the way back. The client times out and sends the same request with the same key. The server finds the key with the same fingerprint, inserts nothing, and replays 201 with Location /v1/books/8 and Idempotent-Replayed true. A third request with the same key and a different price is refused with 422.\"><defs><marker id=\"l02-ik-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><line x1=\"90\" y1=\"40\" x2=\"90\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"320\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">catalogue.py</text><line x1=\"380\" y1=\"40\" x2=\"380\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"570\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.db</text><line x1=\"630\" y1=\"40\" x2=\"630\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"90\" y1=\"70\" x2=\"376\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST  Idempotency-Key: 3f1c9a2e-alienista</text><line x1=\"380\" y1=\"98\" x2=\"626\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"503.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">one transaction: book 8 + key + response</text><line x1=\"380\" y1=\"130\" x2=\"240\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"310.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">201  Location: /v1/books/8</text><line x1=\"214\" y1=\"124\" x2=\"226\" y2=\"136\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"214\" y1=\"136\" x2=\"226\" y2=\"124\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"96\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no answer: timeout</text><line x1=\"90\" y1=\"194\" x2=\"376\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the same POST, the same key</text><line x1=\"380\" y1=\"222\" x2=\"626\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"503.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">key known, same fingerprint</text><text x=\"636\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing inserted</text><line x1=\"380\" y1=\"254\" x2=\"94\" y2=\"254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"237.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">201  Location: /v1/books/8</text><text x=\"235.0\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Idempotent-Replayed: true</text><line x1=\"90\" y1=\"306\" x2=\"376\" y2=\"306\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the same key, another price</text><line x1=\"380\" y1=\"334\" x2=\"94\" y2=\"334\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"237.0\" y=\"326.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">422  key reused</text></svg>", "caption": "The key turns a retry into a question the server can answer: has this operation happened? If it has, the client gets the answer it missed."}
```

The server keeps each key with a fingerprint of the body it came with. The same key with a different
body is a client bug, the key reused for something else, and it is refused rather than guessed at:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 3290, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/key-reused", "title": "Idempotency-Key reused", "status": 422, "detail": "this key came with a different book; use a new key", "instance": "/v1/books"}
422
```

## The rules, written down

The header is being standardised by the IETF, in a draft called *The Idempotency-Key HTTP Header
Field*, which gives each case a status code. `catalogue.py` follows it:

| the request | the answer |
|---|---|
| a new key | handled normally; on success, the key, the fingerprint and the response are stored |
| a known key, the same body | the stored response, again: 201 and the same `Location`, with `Idempotent-Replayed: true` |
| a known key, a different body | **422**, and nothing is done |
| a known key whose first request is still running | **409**; try again shortly |
| no key | a plain POST, with no protection against a retry |

`catalogue.py` never sends that 409, because it handles a key inside one database transaction. **The
key check, the new book and the stored response are committed together or not at all.** The
transaction takes SQLite's write lock before it reads the key, so a second request with the same key
waits for the first to finish and then finds it. A server that stored the key in one place and the
book in another would need the 409, and would need to clean up after a crash between the two.

What is stored is visible, and it carries a timestamp in RFC 3339 with an offset, as the section on
names asks for:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT key, location, created_at FROM idempotency_keys'
3f1c9a2e-alienista|/v1/books/8|2026-10-10T04:29:43+00:00
```

Two things a production API adds. **Keys expire**: Stripe's API, which made this header popular,
removes a key only once it is at least 24 hours old, long enough for any sane retry; `catalogue.py`
keeps them forever.
And **a key belongs to a client**: two clients may well choose the same string, so the key is stored
alongside who sent it, which needs to know who is asking, the subject of lesson 7.
