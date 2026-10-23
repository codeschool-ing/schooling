---
title: Queries from method names
version: 1
---

A method on a repository interface with no annotation and a name Spring Data understands is a
**derived query**: at startup Spring Data reads the name, works out what it asks for, and builds the
query from it. `findByIsbn(String isbn)` reads as "find the books whose `isbn` equals the argument",
and that is the query it gets.

The name has two halves either side of the first `By`. Before it is the **subject**, what to do:
`find`, `read`, `get`, `query`, `search` and `stream` all retrieve, and `count`, `exists` and `delete`
do what they say. After it is the **predicate**: property names of the entity, joined by `And` or
`Or`, each followed by a keyword saying how to compare it, and at the end an optional `OrderBy` with a
property and `Asc` or `Desc`. The names are the entity's fields, `priceCents` and never the column
`price_cents`, because a derived query is JPQL before it is SQL.

| in the name | an example | what it compares |
|---|---|---|
| no keyword | `findByIsbn(String isbn)` | equal to the argument |
| `Containing` | `findByTitleContaining(String text)` | the text anywhere in the title |
| `StartingWith` | `findByTitleStartingWith(String text)` | the text at the start |
| `IgnoreCase` | `findByTitleIgnoreCase(String title)` | equal, whatever the case |
| `LessThan`, `GreaterThanEqual` | `findByPriceCentsLessThan(int cents)` | a comparison with the argument |
| `Between` | `findByPriceCentsBetween(int low, int high)` | from the first to the second |
| `In` | `findByIsbnIn(Collection<String> isbns)` | any value in the collection |
| a path | `findByAuthorName(String name)` | a property of a related entity, through a join |

The shop's search uses three of them at once. `GET /books/search?q=the` calls
`findByTitleContainingIgnoreCaseOrderByTitle`:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/search?q=the" | python3 -m json.tool
[
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 6,
        "isbn": "9786500000061",
        "title": "The War of the Worlds",
        "author": "H. G. Wells",
        "priceCents": 3200
    }
]
```

and the second terminal shows what that name became:

```
2026-10-22T19:18:08.858-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where upper(b1_0.title) like upper(?) escape '\' order by b1_0.title
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"The method name findByTitleContainingIgnoreCaseOrderByTitle split into four parts, each beside the piece of SQL it became: findBy became select from book; TitleContaining became a like on the title with the text wrapped in percent signs; IgnoreCase became upper on both sides; OrderByTitle became order by title.\"><defs><marker id=\"l11-nm\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the method name</text><text x=\"500\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the SQL Hibernate sent</text><rect x=\"30\" y=\"34\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findBy</text><rect x=\"310\" y=\"34\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">select b1_0.id, … from book b1_0</text><text x=\"500\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a query for Book entities</text><line x1=\"250\" y1=\"56\" x2=\"308\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"88\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TitleContaining</text><rect x=\"310\" y=\"88\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">where … b1_0.title like ? escape '\\'</text><text x=\"500\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the text arrives as %the%, escaped</text><line x1=\"250\" y1=\"110\" x2=\"308\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"142\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">IgnoreCase</text><rect x=\"310\" y=\"142\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">upper(b1_0.title) like upper(?)</text><text x=\"500\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">both sides upper-cased</text><line x1=\"250\" y1=\"164\" x2=\"308\" y2=\"164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"196\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderByTitle</text><rect x=\"310\" y=\"196\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order by b1_0.title</text><text x=\"500\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the sort is part of the query</text><line x1=\"250\" y1=\"218\" x2=\"308\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line></svg>", "caption": "A derived query is read off the method name, one part at a time. Each part became one piece of the SQL in the log."}
```

The **`join author`** is not part of the name. It comes from the `@EntityGraph` on the method, which
the next section is about.

## The text is matched as text

**`escape '\'` is there to protect the search.** `Containing` wraps the argument in `%` on both sides,
and before it does, it escapes every `%` and `_` the client typed, because in `like` those two
characters are wildcards. A search for a percent sign, written `%25` in a URL, shows the difference:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/search?q=%25"; echo
[]
```

The second terminal shows the same statement as before, and no title contains a literal `%`, so
nothing came back. Unescaped,
the argument would have been `%%%`, a pattern that matches every title in the shop. That is not SQL
injection, since the text arrives as a bound parameter, the `?`, as lesson 9's `PreparedStatement` did;
it is the smaller mistake of letting a search box's user write the pattern instead of the text.

## Adding a book is three derived calls

`BookService.add` uses the other two derived queries before it writes anything. A new book by a new
author:

```
ana@vm:~/bookshop$ curl -s -i -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Triste Fim de Policarpo Quaresma", "author": "Lima Barreto", "priceCents": 3450}' localhost:8080/books; echo
HTTP/1.1 201 
Location: /books/7
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:18:10 GMT

{"id":7,"isbn":"9786500000078","title":"Triste Fim de Policarpo Quaresma","author":"Lima Barreto","priceCents":3450}
```

```
2026-10-22T19:18:10.161-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.isbn=?
2026-10-22T19:18:10.169-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.name=?
2026-10-22T19:18:10.192-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : insert into author (name) values (?)
2026-10-22T19:18:10.203-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : insert into book (author_id,isbn,price_cents,title) values (?,?,?,?)
```

`where b1_0.isbn=?` is `findByIsbn`, checking the ISBN is not taken. `where a1_0.name=?` is
`findByName`, looking for the author. The two inserts are `save`, called once on a new `Author` and
once on a new `Book`; both had a `null` id, so both were persisted.

## A name that matches nothing

**A derived query is checked when the application starts, not when it is first called.** As a detour,
add one with a misspelt property to `BookRepository`, under `findByIsbn`:

```java
    List<Book> findByTitel(String titel);
```

The compiler has no objection: to it this is a method like any other. Stop the application, build, and
start it again, this time in the first terminal, with the log filtered down to the line that matters:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1
Caused by: org.springframework.data.core.PropertyReferenceException: No property 'titel' found for type 'Book'; Did you mean 'title'
```

The application refused to start, named the property, and guessed the right one. That is the best
property of derived queries: a typo is found by starting the application once, which every test that
starts it also does (lesson 19), rather than by the first student who searches. Delete the line again
before you go on.

The other property is visible in `findByTitleContainingIgnoreCaseOrderByTitle` itself. **A name is a
good query language for one or two conditions and a poor one for five.** Past that point, the
query reads better as a query, which is what `@Query` is for.
