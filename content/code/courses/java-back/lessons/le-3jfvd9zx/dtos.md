---
title: DTOs, because the API's shape is not the domain's
version: 1
---

Put `BookResponse` beside `Book` and they look like one record written twice: the same five
components, the same types, and a method that copies one into the other. The obvious move is to
return `Book` from the controller and delete `BookResponse`, and today the JSON would not change by
one byte.

It would change later, because the two records change for different reasons. A **DTO**, a data
transfer object, is a type whose only job is to be the shape of the data crossing a boundary, here
the HTTP API. `Book` is the **domain**: what the shop knows about a book, and it changes whenever the
shop does. The API is a **contract** with programs you do not control, a phone app installed last
year or a partner's nightly script, and it should change only when you decide it does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Two dashed regions: on the left the API contract, which changes only when you decide, holding BookRequest (isbn, title, author, priceCents, no id) and BookResponse (id, isbn, title, author, priceCents); on the right the domain, which changes when the shop does, holding Book. JSON from the client becomes a BookRequest, BookService.add makes a Book, BookResponse.from turns the Book into a BookResponse, and that goes back to the client as JSON. The client never touches Book.\"><defs><marker id=\"l6t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140\" y=\"14\" width=\"200\" height=\"262\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><rect x=\"450\" y=\"14\" width=\"235\" height=\"262\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"240\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the API's contract</text><text x=\"240\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">changes only when you decide</text><text x=\"567\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the domain</text><text x=\"567\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">changes when the shop does</text><rect x=\"10\" y=\"115\" width=\"100\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"60\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the client</text><rect x=\"155\" y=\"62\" width=\"170\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRequest</text><text x=\"240\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">isbn title author</text><text x=\"240\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><text x=\"240\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no id: the server picks it</text><rect x=\"155\" y=\"182\" width=\"170\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookResponse</text><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id isbn title author</text><text x=\"240\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><rect x=\"475\" y=\"112\" width=\"185\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"567\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Book</text><text x=\"567\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id isbn title author</text><text x=\"567\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><path d=\"M 110 128 L 127 128 L 127 100 L 153 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"85\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON in</text><path d=\"M 325 100 L 395 100 L 395 132 L 473 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"395\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BookService.add</text><path d=\"M 475 162 L 395 162 L 395 215 L 327 215\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"395\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BookResponse.from</text><path d=\"M 155 215 L 127 215 L 127 152 L 112 152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"85\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON out</text></svg>", "caption": "The records on the left are what clients see. Book can change shape without any client noticing, because no client ever receives it."}
```

This course makes both kinds of change, so the argument can be checked against it:

- **Lesson 10 turns `Book` into a JPA entity**, a class with getters whose author is no longer a
  `String` but an `Author` object read from the database. `BookResponse.from` changes to
  `book.getAuthor().getName()`, and the JSON a client receives still says
  `"author": "Machado de Assis"`.
- **Lesson 14 gives `Book` a stock count.** It reaches the API because lesson 14 adds a component to
  `BookResponse`: a decision, written in a diff somebody reads. Had the controller returned `Book`,
  every field the domain grew would have been published the day it was added, including any that
  were never meant for a client.

## The request has no id

The request side matters more. Who picks a new book's id is the server, so the record a client sends
has **no `id` component**: a request that carries one has nowhere to put it. The section on POST
sends `"id": 1` to prove it.

Create `src/main/java/com/example/bookshop/catalogue/BookRequest.java`:

```java
package com.example.bookshop.catalogue;

public record BookRequest(String isbn, String title, String author, int priceCents) {
}
```

Four components and no rules yet. The price is an `int` for now; the section on validation changes
it, for a reason a captured failure makes clear. The rules about what a client may send, such as a
title that is not empty, also go on this record and not on `Book`, because they describe this API's
input rather than what a book is.

## What it costs

Two more records and a mapping method per type, which for an API of three fields is real overhead.
Larger projects often generate the mapping, and in Java the usual tool for that is MapStruct. The
names follow a convention worth keeping: `BookRequest` comes in, `BookResponse` goes out, and the
suffix says which way the data travels.
