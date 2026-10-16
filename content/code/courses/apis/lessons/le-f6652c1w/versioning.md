---
title: Versioning
version: 1
---

**Once a client depends on your API, you can add to it and you cannot take away.** A new field in a
response is invisible to a client that does not read it. A field removed, renamed or changed in type
breaks every client that did read it, on the day you deploy, without any of them having changed a
line. Changes of the second kind are **breaking changes**, and a version number is how an API makes
one without breaking anybody: the old shape stays where it was, and the new one gets a new address.

shelf has two versions of one resource. Version 2 changed the price from a number of cents into an
object with an amount and a currency, because the shop wants to sell in euros one day:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price_cents": 3990, "stock": 12}
ana@api:~/shelf$ curl -s localhost:8000/v2/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "stock": 12, "price": {"amount_cents": 3990, "currency": "BRL"}}
```

That is a breaking change, and a small one is enough. A client of version 1 reads `price_cents` and
gets nothing from version 2; a client that multiplies it by the quantity now multiplies a missing
value. The same row in the database feeds both: the versions are two **representations** of one
resource, which is what makes it cheap to keep the old one alive while clients move.

shelf keeps version 2 read-only, and says so with a 405 and an `Allow` header rather than with silence:

```
ana@api:~/shelf$ curl -si -X PATCH localhost:8000/v2/books/1 -H 'Content-Type: application/json' -d '{"stock": 11}'
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Type: application/json
Content-Length: 36
Allow: GET

{"error": "version 2 is read-only"}
```

## Where the version goes

There are three common places, and every one of them is in use somewhere large:

| where | looks like | for | against |
|---|---|---|---|
| **the path** | `/v2/books/1` | visible in every log, link and bug report; trivial to route | the "same" resource has two addresses |
| a header | `Api-Version: 2` | the address stays the resource's | invisible in a link; caches must be told the answer varies by it |
| the media type | `Accept: application/vnd.shelf.v2+json` | the most faithful to HTTP: one resource, two representations | the hardest to read, type and debug |

**The path is the usual choice and a sound default**, because the property that matters most when
something breaks at night is being able to see the version in the log line. shelf puts it in the
path.

## Retiring a version

A version is a promise with an end date, and the usual pattern announces the date in the response
itself. Two headers, `Deprecation` and `Sunset`, say that a version is on its way out and when it stops
answering. A client that logs them warns its owners without anybody having to read an e-mail. Then you watch your own logs, count who still calls the old version, and
switch it off only when that number is zero or the date has passed.

**Most changes should never need a version.** Adding a field, adding an endpoint, accepting an optional
parameter: none of these breaks a client that is written sensibly, and lesson 2 is about writing both
sides so that they do not. A version is for the change you could not avoid, and an API that is on
`v7` after two years made six changes that a little thought would have made additive.
