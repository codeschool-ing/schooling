---
title: Resolvers, and how a query is walked
version: 1
---

**The schema says what may be asked; a resolver is the function that produces one field's value.**
Running a query means walking it from the root down, and at each field calling that field's
resolver once for every object the field belongs to. Whatever a resolver returns becomes the
object the fields below it are resolved on.

A common picture of a GraphQL server has it translating the whole query into one SQL statement.
It does nothing of the kind. Each field is resolved on its own, and the server does whatever its
resolvers do. The book page from the section on `graph.py` ran three statements, one per resolver
that touches the database, in the order the walk reached them:

```
  sql: SELECT * FROM books WHERE id = '2'
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
127.0.0.1 - - [10/Oct/2026 01:38:12] "POST /graphql HTTP/1.1" 200 -
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A tree of resolver calls for the query book(id: 2) with title, author name and the author&#x27;s book titles. Query.book runs SQL 1 and returns book 2. Its title comes from the default resolver; Book.author runs SQL 2 and returns author 1. The author&#x27;s name comes from the default resolver; Author.books runs SQL 3 and returns books 1 and 2, whose titles come from the default resolver.\"><defs><marker id=\"l03-tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"14\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book(id: 2)</text><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Query.book · SQL 1</text><rect x=\"110\" y=\"100\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"175.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"175.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">default</text><rect x=\"400\" y=\"100\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><text x=\"480.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Book.author · SQL 2</text><rect x=\"250\" y=\"186\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"315.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"315.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">default</text><rect x=\"480\" y=\"186\" width=\"170\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Author.books · SQL 3</text><rect x=\"420\" y=\"272\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"480.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">of book 1</text><rect x=\"580\" y=\"272\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"640.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">of book 2</text><line x1=\"360\" y1=\"54\" x2=\"175\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"360\" y1=\"54\" x2=\"480\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"480\" y1=\"140\" x2=\"315\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"480\" y1=\"140\" x2=\"565\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"565\" y1=\"226\" x2=\"480\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"565\" y1=\"226\" x2=\"640\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><rect x=\"20\" y=\"262\" width=\"22\" height=\"14\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a resolver of ours, which runs SQL</text><rect x=\"20\" y=\"290\" width=\"22\" height=\"14\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"50\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the default resolver: a key of the dict above</text><text x=\"175\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;Memórias Póstumas…&quot;</text></svg>", "caption": "How graph.py walks one query. Every box is one call; the three solid ones are functions in graph.py and each runs one SQL query, while the dashed ones read a key from the dict their parent returned."}
```

## What a resolver receives

Every resolver gets the same four things, though libraries hand them over in different orders.
The JavaScript reference implementation passes `(parent, args, context, info)`; graphql-core passes
`parent` and `info` and then the arguments by name, which is why `graph.py`'s resolvers look like
`one_book(parent, info, id)`.

| | what it is | in `graph.py` |
|---|---|---|
| `parent` | the value the field above returned | for `Book.author`, the book's row as a dict |
| arguments | the field's arguments, already checked against their types | `id`, `authorId`, `bookId`, `stock` |
| context | one object shared by every resolver of one request | the database connection and the loader |
| `info` | where the walk is: the field's name, its path, the schema | `info.context` is how the context arrives |

The context is the place for anything that belongs to the request rather than to a field: a
connection, the user who sent the request, a cache that must not outlive it. Lesson 11 is about
deciding what each user may see, and in a GraphQL server the context is where a resolver finds that
user.

## The default resolver

The schema has fifteen fields and `graph.py` has seven functions. The other eight, `title`, `year`,
`name` and the rest, are answered by the **default resolver**, which looks in the parent for a key
or an attribute with the field's name. That is why the functions in `graph.py` return plain dicts:
a dict made from a row already holds `title` and `year`, and nothing more needs writing.

`priceCents` has a function only because the column is called `price_cents`. Without it the
default resolver would find no key called `priceCents` and return nothing, and the request would
fail, because the schema promises the field is never null. A resolver is where the names of the API
part company with the names of the database.

## The walk

In `graph.py` the walk is depth first, as the log above shows. When a field returns a list, its fields are resolved on each item; when it
returns an object, on that one object; when it returns `null`, nothing below it runs. So the number
of resolver calls is not fixed by the query: the same query costs more on a shop with more books.
That is the property the next section measures, and the one the section on protecting the server
has to put a limit on.
