---
title: Resources and their addresses
version: 1
---

**In REST, the address names a thing and the method says what to do with it.** The thing is a
**resource**: a book, an author, the list of an author's books. Resources come in two shapes, a
**collection**, which holds many, and an **item**, which is one of them, and the address says which
shape it is by whether it ends in an id.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"The addresses shelf answers, as a tree. Under /v1 there are two collections, /books and /authors. /books/3 is one item of the first. /authors/2 is one item of the second, and /authors/2/books is a collection inside it. A query string, ?author_id=3, filters /books without becoming a new address.\"><defs><marker id=\"tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"80\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/v1</text><rect x=\"160\" y=\"45\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books</text><rect x=\"160\" y=\"165\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors</text><rect x=\"350\" y=\"20\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books/3</text><rect x=\"350\" y=\"75\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books?author_id=3</text><rect x=\"350\" y=\"165\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors/2</text><rect x=\"530\" y=\"165\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors/2/books</text><line x1=\"100\" y1=\"125\" x2=\"130\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"65\" x2=\"130\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"65\" x2=\"158\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"185\" x2=\"158\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"290\" y1=\"58\" x2=\"348\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><line x1=\"290\" y1=\"72\" x2=\"348\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#tree-ah)\"></line><line x1=\"290\" y1=\"185\" x2=\"348\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><line x1=\"490\" y1=\"185\" x2=\"528\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><text x=\"225\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">collection</text><text x=\"225\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">collection</text><text x=\"420\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the same collection, filtered</text><text x=\"420\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">item</text><text x=\"605\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a collection in an item</text><text x=\"498\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">item</text></svg>", "caption": "Every address is a noun. The methods are the verbs, and the next section is about them."}
```

The collection first. Every book, cut down by `jq` to three fields so that each fits on a line:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books | jq -c '.[] | {id, title, author_id}'
{"id":1,"title":"Dom Casmurro","author_id":1}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","author_id":1}
{"id":3,"title":"A Hora da Estrela","author_id":2}
{"id":4,"title":"Perto do Coração Selvagem","author_id":2}
{"id":5,"title":"Ensaio sobre a Cegueira","author_id":3}
{"id":6,"title":"Americanah","author_id":4}
```

One item, this time with `-i`, which makes curl print the status line and the headers before the
body:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/3
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 128

{"id": 3, "isbn": "9786500000030", "title": "A Hora da Estrela", "author_id": 2, "year": 1977, "price_cents": 3490, "stock": 0}
```

An item that does not exist answers **404** with a body that says so. A client should be able to tell
"no such book" from "no such address" without reading prose. Lesson 2 gives errors a shape a program
can read; for now the status code carries it:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 24

{"error": "no book 99"}
```

## A collection inside an item

An author is an item of `/v1/authors`, and the author's books are a collection that belongs to that
item. The address says so by nesting:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/2
{"id": 2, "name": "Clarice Lispector", "country": "BR"}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/2/books | jq -c '.[] | {id, title}'
{"id":3,"title":"A Hora da Estrela"}
{"id":4,"title":"Perto do Coração Selvagem"}
```

The same books can be had another way, by **filtering** the collection of all books with a query
string. Filtering does not create a new resource; it is the same collection, with fewer items shown:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?author_id=3' | jq -c '.[] | {id, title}'
{"id":5,"title":"Ensaio sobre a Cegueira"}
```

So which one? Both are common, and shelf answers both on purpose. Nest when the inner thing only makes
sense inside the outer one, the lines of one order, the replies to one comment, and filter when it is
one of several ways to cut a collection that stands on its own. Books stand on their own; you will
want them by author today and by year or price tomorrow, and a query string takes any number of
those without an address for each. **One level of nesting is the practical limit.**
`/authors/2/books/4/reviews` reads well and makes every client build four-part paths to reach a review
that already has an id of its own.

## What does not belong in an address

**A verb.** The most common wrong design names the action in the path, `/getBooks`, `/createBook`,
`/deleteBook?id=7`, and uses `GET` or `POST` for all of them. shelf has no such address:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/v1/getBooks
404
```

The method is the verb, and there are only a handful of them. That is the point: every HTTP client,
proxy and cache in the world already knows what `GET` and `DELETE` promise. Nobody knows what
`/deleteBook` does without reading your documentation.

**Something that can change.** shelf addresses a book by its `id`, a number the database gave it,
and not by its ISBN, even though the ISBN is unique too. An address is something other people store:
in a bookmark, in another database, in a log. An identifier that comes from the world, a title, an
ISBN that a publisher corrects, an e-mail address, can change, and every stored copy of the address
then points at nothing or at something else. An id the system invents and never reuses for another
thing cannot.

A few conventions are worth following for no deeper reason than that everybody does: collections are
**plural nouns** (`/books`, not `/book`), addresses are lower case with hyphens between words, and a
trailing slash means nothing. shelf's single regular expression accepts `/v1/books/` and `/v1/books`
alike, which is the forgiving choice.
