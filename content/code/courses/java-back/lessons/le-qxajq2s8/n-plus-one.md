---
title: The N+1 problem, counted and fixed
version: 1
---

The **N+1 problem** is one query to fetch a list of N things, followed by one more query for each of
them to fetch something they point at. Nobody writes it on purpose. It comes from code that reads
perfectly well, a loop over books asking each one for its author's name, sitting on top of a lazy
relationship. Each question is fast, so a test with three rows never notices; a page with two
hundred books by two hundred authors makes two hundred and one round trips to the database.

## Counting it

The bookshop has it right now. `findAll` is still the version from the section on the entity manager,
`select b from Book b order by b.id`, and `BookService.list` maps every book with
`BookResponse.from`, which reads `getAuthor().getName()`. With the application started with the `sql`
profile, ask for the list:

```
(capture nplus1)
```

and look at the second terminal:

```
(capture nplus1-log)
```

One `select` on `book`, with `author_id` among its columns and no name, and then one `select` on
`author` for each author whose name was asked for. **Four, not six.** Dom Casmurro's author is loaded
when the first book is mapped; when Quincas Borba asks for Machado de Assis two books later, the
persistence context already holds him and answers without a query. The same happens for H. G.
Wells. So N is the number of distinct authors on the page, which is no comfort: a page of two
hundred books from two hundred authors is two hundred and one statements, each a round trip to the
database and back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"Left: the plain query sends one select on book and then four selects on author, one for each of Dom Casmurro, The Time Machine, Frankenstein and Persuasion; the other two books find their authors already loaded. Right: with join fetch, one select joins book and author and returns six rows with the names.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">select b from Book b order by b.id</text><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 books, 4 authors: 5 statements</text><rect x=\"20\" y=\"62\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from book</text><text x=\"256\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 rows, author ids only</text><text x=\"14\" y=\"75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"20\" y=\"96\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for Dom Casmurro</text><text x=\"14\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><rect x=\"20\" y=\"130\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for The Time Machine</text><text x=\"14\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><rect x=\"20\" y=\"164\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for Frankenstein</text><text x=\"14\" y=\"177\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><rect x=\"20\" y=\"198\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for Persuasion</text><text x=\"14\" y=\"211\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Quincas Borba and The War of the Worlds: no statement,</text><text x=\"20\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">their authors are already in the persistence context.</text><line x1=\"452\" y1=\"12\" x2=\"452\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"470\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">… join fetch b.author …</text><text x=\"470\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 books, 4 authors: 1 statement</text><rect x=\"470\" y=\"62\" width=\"214\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from book join author …</text><text x=\"470\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 rows, each with its author's name</text></svg>", "caption": "The same six books, asked for twice. Without join fetch every new author is one more round trip; with it the whole list is one."}
```

## The fix people reach for first

Switching the relationship to `FetchType.EAGER` sounds like the cure, and it is worth seeing why it
is not. Change `LAZY` to `EAGER` in `Book`, rebuild, restart, and ask for the list again:

```
(capture eager-list-log)
```

The same five statements. `EAGER` decides that the author is loaded *with* the book, but a JPQL
query is translated as written, and this one names no author; so Hibernate runs it, finds six books
whose authors it promised to load, and loads them one by one, straight away instead of later. Where
`EAGER` does help is `find`, which Hibernate writes itself and can join. One book is now one
statement:

```
(capture eager-one-log)
```

Put `LAZY` back before going on. `EAGER` moves the problem rather than solving it, and it makes every
other query pay for authors whether it wants them or not.

## Asking for the author in the query

The cure is to say, in the query that loads the books, that their authors are wanted too.
**`join fetch`** does that: it joins the related entity and fills the relationship from the same
rows, so no proxy is left to load itself. In `JpaBookRepository`, replace the `findAll` method with
this one:

```java
    @Override
    public List<Book> findAll() {
        return em.createQuery("select b from Book b join fetch b.author order by b.id", Book.class)
                .getResultList();
    }
```

Rebuild and restart with the `sql` profile. The catalogue report at start-up is already down to one
statement:

```
(capture fetch-startup)
```

and so is the list:

```
(capture fetch-log)
```

One statement. The `join` is in the SQL, the author's `id` and `name` are among the columns, and
every `Book` arrives with a real `Author` rather than a proxy, so `BookResponse.from` finds the names
already there. Six books or six hundred, the list is one statement and one round trip.
`JpaBookRepository.java` is now in its final form for this lesson.

## What to take from it

- **Read the SQL log of every new screen once.** The N+1 problem is invisible in the code and
  obvious in the log, where it looks like a column of identical statements.
- **Decide what to load where the query is written**, not on the entity. The mapping says what a
  book IS; the query says what this screen needs.
- `join fetch` is one cure among several. Hibernate can also load the authors of many books in a
  single `IN` query when it finds them lazy (batch fetching), and lesson 11 states the same intent
  on a Spring Data repository with `@EntityGraph`. `sql-databases` lesson 11 looks at the problem
  from the database's side.
