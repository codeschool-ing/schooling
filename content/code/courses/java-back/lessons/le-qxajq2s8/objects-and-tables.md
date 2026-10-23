---
title: Objects, tables and the mapper between them
version: 1
---

Lesson 9's repository did two jobs at once. It wrote the SQL, and it copied each column of each row
into a `Book` record. An **object-relational mapper**, an ORM, takes over the second job entirely
and most of the first: you describe how a class corresponds to a table, and the mapper writes the
`SELECT`, `INSERT` and `UPDATE` statements and turns rows into objects and objects back into rows.

The usual wrong picture is that the mapper replaces the database, and that the program now works
with a big collection of objects kept in memory. It does not. **Every object a mapper hands you
came out of a `SELECT`, and every change you make reaches the database as an `UPDATE`.** What
changes is who writes those statements and when they run, and most of this lesson is about the
when.

## Two shapes of one fact

Objects and tables disagree about three things, and a mapper exists to settle them.

- **References against keys.** A book object holds its author, so `book.getAuthor().getName()`
  is a method call. A row of `book` holds a number, `author_id`, and the name is a second lookup or
  a join.
- **Identity.** Two JDBC queries for book 3 give two records that are equal and distinct. Inside one
  unit of work, a mapper gives you the same object both times, because there is only one book 3.
- **Change.** A record never changes; to change a price in lesson 9 you would write an `UPDATE`.
  A mapped object has a field that changes, and the mapper notices and writes the `UPDATE` itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"On the left, a Book object whose author field refers to an Author object named Mary Shelley. On the right, a row of the book table holding author_id 3, which matches the id of a row in the author table.\"><defs><marker id=\"map-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in Java: objects</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in PostgreSQL: rows</text><rect x=\"30\" y=\"45\" width=\"180\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Book</text><text x=\"45\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">id = 3</text><text x=\"45\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">title = \"Frankenstein\"</text><text x=\"45\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author =</text><rect x=\"130\" y=\"165\" width=\"180\" height=\"62\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Author</text><text x=\"145\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">name = \"Mary Shelley\"</text><path d=\"M 108 118 C 150 118, 200 130, 210 162\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#map-ah)\"></path><text x=\"262\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a reference</text><rect x=\"390\" y=\"45\" width=\"290\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">book</text><text x=\"400\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">id</text><text x=\"400\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title</text><text x=\"440\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Frankenstein</text><text x=\"580\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">author_id</text><text x=\"580\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"390\" y=\"165\" width=\"290\" height=\"62\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">author</text><text x=\"400\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">id</text><text x=\"400\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"440\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">name</text><text x=\"440\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Mary Shelley</text><path d=\"M 600 108 C 600 140, 420 130, 412 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#map-ah)\"></path><text x=\"625\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a number to look up</text></svg>", "caption": "One fact, two shapes. The object holds its author; the row holds a number that has to be looked up. Hibernate translates between the two."}
```

## JPA and Hibernate

**Jakarta Persistence**, still called by its old name **JPA**, is a specification: a set of
annotations (`@Entity`, `@Id`, `@ManyToOne`), the `EntityManager` interface and a query language,
JPQL. It lives in the package `jakarta.persistence` and implements nothing. **Hibernate** is the
implementation Spring Boot uses; EclipseLink is another. The code in this lesson imports
`jakarta.persistence` only, and Hibernate does the work behind it. You will see its name in the log
and never in an import:

```
2026-10-22T19:22:22.216-03:00  INFO 29937 --- [bookshop] [           main] org.hibernate.orm.core                   : HHH000001: Hibernate ORM core version 7.4.5.Final
```

## What it costs

A mapper saves the copying, and it charges for it in three ways. They are the reason lesson 12 looks
at libraries that do less.

- **SQL you did not write.** A line of Java that looks like reading a field can be a query. The
  section on the N+1 problem counts them.
- **Rules about time.** An object stays connected to the database only while a unit of work is open.
  Read a lazy field after that and Hibernate throws instead of querying; the last section shows the
  exception.
- **A model of its own to learn.** Entities, a persistence context, flushing, proxies: none of it is
  SQL, and all of it decides which SQL runs. This lesson teaches the part of it the bookshop uses.
