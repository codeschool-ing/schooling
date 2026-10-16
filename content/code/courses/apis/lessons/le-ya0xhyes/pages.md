---
title: Pages
version: 1
---

**A collection is sent a page at a time, the page has a maximum size, and the response says where
the next page is.** Six books fit in one answer; sixty thousand do not, and an API that sends the
whole table to every client that asks for the list stops answering the day the table grows. The
question is how a client asks for "the next page", and the obvious answer is the one that fails.

## Offset and limit

The obvious answer is a position: `?offset=40&limit=20`, skip forty rows and send twenty. It is easy
to write, and it lets a client jump straight to page 37. But a position only means the same row while
nothing changes, and a collection people write to changes between one request and the next.

## A cursor instead

A cursor asks the other way: for the rows **after the last row of the previous page**, by its values
rather than its position. "Books with an id below 5", not "rows three and four". `catalogue.py`
pages that way, and the difference shows as soon as the collection changes between two pages.

Here are the books newest first, two to a page, both ways at once: `sqlite3` shows what an offset
query returns, and `catalogue.py` is asked with `sort=-id`. The first page is the same either way:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 0'
6|Americanah
5|Ensaio sobre a Cegueira
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-id&limit=2' | jq -c '.items[].id, .next'
6
5
"/v1/books?sort=-id&limit=2&after=WyItaWQiLCA1LCA1XQ"
```

Now somebody adds a book:

```
ana@api:~/shelf$ curl -s -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990, "currency": "BRL"}}' | jq -c '{id, title}'
{"id":7,"title":"Quincas Borba"}
```

And both ask for their second page:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 2'
5|Ensaio sobre a Cegueira
4|Perto do Coração Selvagem
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-id&limit=2&after=WyItaWQiLCA1LCA1XQ' | jq -c '.items[].id, .next'
4
3
"/v1/books?sort=-id&limit=2&after=WyItaWQiLCAzLCAzXQ"
```

Book 7 arrived at the front of the list and pushed every row one place back, so the offset's second
page, rows three and four, is now 5 and 4. **Book 5 is shown twice.** Had a book been deleted
instead, everything would have moved forward and one book would never have been shown at all.
Neither case produces an error; a client copying the list into its own database quietly ends up with
a duplicate or a gap.

The cursor's second page asked for ids below 5 and got 4 and 3, untouched by the insert. Book 7 is
not on this walk at all: it arrived in front of where the walk started, and it is on the first page
of the next one.

An offset has a second cost. To answer `OFFSET 100000`, the database still walks through the hundred
thousand rows it then throws away, so pages get slower the further in a client reads. A cursor
becomes a `WHERE` condition, and with an index on the sort field the thousandth page costs what the
first one did.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three rows of books, newest first. The first page, before the insert, is books 6 and 5. After book 7 is added at the front, offset 2 counts two positions and returns books 5 and 4, so book 5 appears twice. The cursor asks for ids below 5 and returns books 4 and 3.\"><text x=\"272.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"324.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"376.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"428.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"480.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"532.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"584.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"236\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">position</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">page 1, before the insert</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">limit=2</text><rect x=\"250\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"302\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"324.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"354\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"406\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"428.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"458\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"510\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">page 2 by offset</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">offset=2</text><rect x=\"250\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"272.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">7</text><rect x=\"302\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"324.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"354\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"376.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"406\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"458\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"562\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">page 2 by cursor</text><text x=\"20\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">after=(id 5)</text><rect x=\"250\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"272.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">7</text><rect x=\"302\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"324.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"354\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"406\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"458\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"562\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"376.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">shown twice</text><text x=\"612\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">book 7 arrived:</text><text x=\"612\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every row moved</text><text x=\"612\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ids below 5:</text><text x=\"612\" y=\"251\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nothing moved</text></svg>", "caption": "An offset counts positions, and an insert moves every position after it. A cursor names the last row seen, which an insert does not move."}
```

## How the next page is announced

`catalogue.py` gives the address of the next page twice, in the body as `next` and in a `Link`
header with `rel="next"`, the form RFC 8288 defines and GitHub's API, among others, uses. The
default sort is by id:

```
ana@api:~/shelf$ curl -si 'localhost:8000/v1/books?limit=2'
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/json
Content-Length: 433
Link: </v1/books?limit=2&after=WyJpZCIsIDIsIDJd>; rel="next"

{"items": [{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price": {"amount_cents": 3990, "currency": "BRL"}, "stock": 12, "in_stock": true}, {"id": 2, "isbn": "9786500000023", "title": "Memórias Póstumas de Brás Cubas", "author_id": 1, "year": 1881, "price": {"amount_cents": 4490, "currency": "BRL"}, "stock": 7, "in_stock": true}], "next": "/v1/books?limit=2&after=WyJpZCIsIDIsIDJd"}
```

The cursor inside the link holds three things: the sort, the last row's value for it and the last
row's id, as JSON in URL-safe base64:

```
ana@api:~/shelf$ echo WyJpZCIsIDIsIDJd | base64 -d; echo
["id", 2, 2]
```

The contract calls it **opaque**: a client copies it from the `next` link and never builds or reads
one, so the server is free to change what goes inside. Opaque does not mean secret, as `base64 -d`
shows; nothing in a cursor may be something the client should not see.

A client follows `next` until it is `null`:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDIsIDJd' | jq -c '.items[].id, .next'
3
4
"/v1/books?limit=2&after=WyJpZCIsIDQsIDRd"
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDQsIDRd' | jq -c '.items[].id, .next'
5
6
"/v1/books?limit=2&after=WyJpZCIsIDYsIDZd"
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDYsIDZd' | jq -c '.items[].id, .next'
7
null
```

A page also has a ceiling. `limit` defaults to 20 and goes up to 100, and a client asking for more is
told so rather than given a server's worth of rows:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=500' | jq -r .detail
limit is a whole number from 1 to 100
```

Some APIs quietly lower a limit that is too high instead; a client then gets fewer rows than it asked
for and has to notice. Refusing is the choice that cannot be misread.

| | offset and limit | cursor |
|---|---|---|
| a row added or removed between pages | rows repeat or are skipped | nothing moves |
| jump straight to page 37 | yes | no; pages are walked in order |
| cost of a page deep in the list | grows with the offset | the same as the first page, given an index |
| what the client sends back | a number it works out | the link it was given |
