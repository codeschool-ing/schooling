---
title: Errors a program can read
version: 1
---

**An error body is read by a program first and by a person second.** The status code says which
class of thing went wrong; the body has to say exactly what, in a form a client can branch on
without parsing a sentence. RFC 9457, *Problem Details for HTTP APIs*, is the standard shape for
that body, and every error `catalogue.py` writes takes that shape.

The usual error body is a message for a human. Lesson 1's `rest.py`, sent a book with an empty
title, a year as text, a price as a float and no ISBN or author:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": "", "year": "1891", "price_cents": 39.90}'
{"error": "wrong type for: price_cents, year"}
422
```

There is nothing in that a program can use except by matching English text, and the text is free to
change in the next release. It is also incomplete: it names two wrong types and says nothing about
the two missing fields or the empty title, which the client discovers one request at a time.

## The problem details object

The same body, sent to `catalogue.py`:

```
ana@api:~/shelf$ curl -s -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": "", "year": "1891", "price_cents": 39.90}' | jq .
{
  "type": "https://shelf.example/problems/invalid-book",
  "title": "The book breaks the contract",
  "status": 422,
  "detail": "every problem with the book is listed in errors",
  "instance": "/v1/books",
  "errors": [
    {
      "pointer": "#",
      "detail": "Additional properties are not allowed ('price_cents' was unexpected)"
    },
    {
      "pointer": "#",
      "detail": "'isbn' is a required property"
    },
    {
      "pointer": "#",
      "detail": "'author_id' is a required property"
    },
    {
      "pointer": "#",
      "detail": "'price' is a required property"
    },
    {
      "pointer": "#/title",
      "detail": "'' is too short"
    },
    {
      "pointer": "#/year",
      "detail": "'1891' is not of type 'integer'"
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The problem details body catalogue.py sent for an invalid book, one member per line, each with a note. type, status and the pointers in errors are for the client program; title and detail are for a person; instance says which occurrence it was.\"><defs><marker id=\"l02-pd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"400\" height=\"266\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"22.0\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{</text><text x=\"33.5\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;type&quot;: &quot;https://shelf.example/problems/invalid-book&quot;,</text><line x1=\"470\" y1=\"54\" x2=\"418\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what kind of problem: the client branches on this</text><text x=\"33.5\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;title&quot;: &quot;The book breaks the contract&quot;,</text><line x1=\"470\" y1=\"76\" x2=\"418\" y2=\"76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the kind, in words, the same every time</text><text x=\"33.5\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;status&quot;: 422,</text><line x1=\"470\" y1=\"98\" x2=\"418\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the status code again, for logs</text><text x=\"33.5\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;detail&quot;: &quot;every problem with the book is ...&quot;,</text><line x1=\"470\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">this occurrence, for a person</text><text x=\"33.5\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;instance&quot;: &quot;/v1/books&quot;,</text><line x1=\"470\" y1=\"142\" x2=\"418\" y2=\"142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which occurrence</text><text x=\"33.5\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;errors&quot;: [</text><line x1=\"470\" y1=\"164\" x2=\"418\" y2=\"164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an extension member</text><text x=\"45.0\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;pointer&quot;: &quot;#/year&quot;,</text><line x1=\"470\" y1=\"186\" x2=\"418\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which field, as a JSON Pointer</text><text x=\"50.75\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;detail&quot;: &quot;&#x27;1891&#x27; is not of type &#x27;integer&#x27;&quot;}</text><line x1=\"470\" y1=\"208\" x2=\"418\" y2=\"208\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-pd-ah)\"></line><text x=\"478\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what is wrong with it</text><text x=\"33.5\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">]</text><text x=\"22.0\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><rect x=\"430\" y=\"262\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"448\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read by the program</text><rect x=\"580\" y=\"262\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"598\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read by a person</text></svg>", "caption": "A problem details body has a part for the program and a part for the person, and a client that branches on the text has picked the wrong part."}
```

| member | what it is for |
|---|---|
| `type` | a URI naming the kind of problem. **This is what a client branches on.** It never changes for a given kind, and it may lead to a page that documents it |
| `title` | a short summary of that kind, the same for every occurrence; for people, not for code |
| `status` | the HTTP status code again, for when the body is logged or passed on without its headers |
| `detail` | this occurrence, explained to a person |
| `instance` | which occurrence: here, the path that was asked for. An id that also appears in the server's log serves the same purpose |
| anything else | extension members. `errors`, one entry per failure with a JSON Pointer to the field, is the one RFC 9457 itself uses as an example |

The media type is `application/problem+json`, so a client knows the shape before it reads a byte.
A problem with no more to say than its status code uses the type `about:blank`, and its title is
then the status code's own name:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/problem+json
Content-Length: 122

{"type": "about:blank", "title": "Not Found", "status": 404, "detail": "there is no book 99", "instance": "/v1/books/99"}
```

## One shape for every error

**A client should need one error parser**, so every failure takes this shape, including the ones that have
nothing to do with the book's fields. A book whose ISBN is taken, and a body that is not JSON
at all:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price": {"amount_cents": 3990, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/duplicate-isbn", "title": "ISBN already in the catalogue", "status": 409, "detail": "another book has ISBN 9786500000016", "instance": "/v1/books"}
409
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": '
{"type": "https://shelf.example/problems/malformed-json", "title": "The body is not JSON", "status": 400, "detail": "Expecting value: line 1 column 11 (char 10)", "instance": "/v1/books"}
400
```

The 409 says which ISBN is taken and nothing about how the database found out. Lesson 1's 409 passed
SQLite's own message to the client, naming the table and the column; that is an internal detail, and
the next change to the database changes the message. The 400 does pass the parser's message on,
because the line and column of a syntax error are exactly what the client needs.

The last of lesson 1's complaints was the HTML page Python's library sent for a method nobody had
written. `catalogue.py` answers those methods itself, with a 405, an `Allow` header and a problem:

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books/1
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/problem+json
Content-Length: 145
Allow: GET, POST

{"type": "about:blank", "title": "Method Not Allowed", "status": 405, "detail": "the catalogue does not take DELETE", "instance": "/v1/books/1"}
```
