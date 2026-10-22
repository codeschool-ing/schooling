---
title: Paging and sorting
version: 1
---

`GET /books` no longer returns the whole catalogue: it returns **a page** of it. The controller's
method takes a `Pageable`, built by Spring Data's web support, which Boot switches on like the
repositories. It comes from three query parameters: **`page`**, counted from 0; **`size`**, how many per
page; and **`sort`**, a property and an optional direction, `sort=title,desc`, repeatable for a second
key.
`@PageableDefault(size = 20, sort = "id")` is what a request that names none of them gets. The service
passes the `Pageable` to `findAllBy`, and Hibernate turns it into SQL.

The second page of two, by title from Z to A:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=2&page=1&sort=title,desc" | python3 -m json.tool
{
    "content": [
        {
            "id": 2,
            "isbn": "9786500000023",
            "title": "The Time Machine",
            "author": "H. G. Wells",
            "priceCents": 2950
        },
        {
            "id": 5,
            "isbn": "9786500000054",
            "title": "Quincas Borba",
            "author": "Machado de Assis",
            "priceCents": 3690
        }
    ],
    "page": {
        "size": 2,
        "number": 1,
        "totalElements": 7,
        "totalPages": 4
    }
}
```

```
2026-10-22T19:19:56.369-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.title desc offset ? rows fetch first ? rows only
2026-10-22T19:19:56.391-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select count(*) from book b1_0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 242\" role=\"img\" aria-label=\"Seven books sorted by title, descending, cut into pages of two, the last holding one. Page 1 holds The Time Machine and Quincas Borba: the query skips two rows and fetches two. A second query counts the seven rows, which gives totalElements 7 and totalPages 4.\"><defs><marker id=\"l11-pg\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sorted by title, descending</text><rect x=\"75\" y=\"26\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"36.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Triste Fim de Policarpo Quaresma</text><rect x=\"75\" y=\"52\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"62.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">The War of the Worlds</text><rect x=\"75\" y=\"88\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">The Time Machine</text><rect x=\"75\" y=\"114\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"124.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Quincas Borba</text><rect x=\"75\" y=\"150\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"160.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Persuasion</text><rect x=\"75\" y=\"176\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Frankenstein</text><rect x=\"75\" y=\"212\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Dom Casmurro</text><text x=\"36\" y=\"49.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">page 0</text><text x=\"36\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">page 1</text><text x=\"36\" y=\"173.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">page 2</text><text x=\"36\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">page 3</text><rect x=\"345\" y=\"89.5\" width=\"230\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">offset 2 rows</text><text x=\"460\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fetch first 2 rows only</text><line x1=\"295\" y1=\"111.5\" x2=\"343\" y2=\"111.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-pg)\"></line><rect x=\"345\" y=\"170\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select count(*) from book</text><text x=\"460\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">7 rows: totalElements 7, totalPages 4</text><text x=\"460\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the second query</text></svg>", "caption": "size=2&page=1&sort=title,desc: one query skips two rows and fetches two, and a second query counts all seven, because the page cannot know the total from two rows."}
```

**Paging costs two statements.** The first fetches the rows of the page: `order by b1_0.title desc`
for the sort, and `offset ? rows fetch first ? rows only` for the page, with the 2 and the 2 bound as
parameters like any other value. The second counts, because `totalElements` and `totalPages` cannot
be known from two rows. In the JSON, `content` is the page and `page` is the four numbers a client needs
to draw the next and previous buttons.

**And sometimes it costs one.** The first `GET /books` in the section on the relationship asked for a page of 20,
the default, and the second terminal showed a single statement with `fetch first ? rows only` and no
count. The query brought back fewer rows than the page could hold, so this was the last page, and its
rows were the total: Spring Data did the arithmetic instead of asking.

## Sorting through the relationship

A sort property may be a path, like a derived query's. Sorting by the author's name:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=3&sort=author.name" | python3 -m json.tool | grep -E "title|author|total"
            "title": "The Time Machine",
            "author": "H. G. Wells",
            "title": "The War of the Worlds",
            "author": "H. G. Wells",
            "title": "Persuasion",
            "author": "Jane Austen",
        "totalElements": 7,
        "totalPages": 3
```

```
2026-10-22T19:19:57.051-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by a1_0.name fetch first ? rows only
2026-10-22T19:19:57.060-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select count(*) from book b1_0
```

`order by a1_0.name`, on the author the entity graph had already joined.

## What the parameters cannot do

A client chooses the size, and Spring Data caps it. Asking for five thousand books per page:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=5000" | python3 -m json.tool | tail -n 7
    "page": {
        "size": 2000,
        "number": 0,
        "totalElements": 7,
        "totalPages": 1
    }
}
```

The page came back with a `size` of 2000, Spring Data's default ceiling, so one request cannot ask the
database for a million rows. Boot's property `spring.data.web.pageable.max-page-size` moves it.

A client also chooses the sort, and the sort is not pasted into the SQL as text: Spring Data resolves
it against the entity's properties first. A property `Book` does not have:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?sort=price"; echo
{"timestamp":"2026-10-22T22:19:58.619Z","status":500,"error":"Internal Server Error","path":"/books"}
```

Nothing reached the database; the second terminal printed no statement for this request. But **the
answer is wrong in its status.** The mistake is the client's, and a 400 would say so. The 500 is
Spring Data's `PropertyReferenceException` reaching lesson 7's handler, which has no case for it, so the
body is Boot's default rather than a problem detail. The bookshop leaves it like this, and an API
of your own deserves the one extra `@ExceptionHandler` that maps it to a 400.

## Why `PagedModel` and not `Page`

`books.list(pageable)` returns a Spring Data `Page`, and the controller wraps it in a `PagedModel`
before it returns. **`Page` is an interface for Java code**, with methods such as `getPageable`,
`isFirst` and `hasNext`, and it was never designed as a JSON format. **`PagedModel` is the JSON
format**, `content` and the four numbers, and Spring Data treats it as a shape to keep stable. Returning
it says, in the method's type, exactly what a client receives.

## Deep pages

`offset` is simple and has one cost that grows: to answer `page=5000&size=20`, PostgreSQL finds,
sorts and discards the first 100,000 rows before returning twenty. For a catalogue of seven books that
is nothing; for an endless feed it is the slowest query in the application. The usual answer there is
**keyset pagination**, which asks for the rows after the last one seen (`where title > ?`) instead of
after a number of rows, and Spring Data offers it as scrolling with `Window` and `ScrollPosition`. This
course stays with pages.
