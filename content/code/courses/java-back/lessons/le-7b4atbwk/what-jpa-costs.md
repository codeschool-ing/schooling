---
title: What JPA charges for what it gives
version: 1
---

Lessons 10 and 11 gave the bookshop an ORM, and it earned its place. `Book` is an object, a changed
field is written back without an `UPDATE` anybody typed, and
`findByTitleContainingIgnoreCaseOrderByTitle` is a query nobody wrote. The same two lessons showed
the bill: the listing sent one `select` per book until `join fetch` and `@EntityGraph` fixed it, and
reading a book's author after the transaction had closed threw a `LazyInitializationException`.

A common picture is that the choice is JPA or raw JDBC, the comfort of objects or a page of
`rs.getString` calls. **The space between the two is full of libraries**, and each of them keeps a
different part of what JPA gives and drops a different part of what it costs. To compare them, it
helps to name the parts:

| JPA gives you | and charges you |
|---|---|
| SQL generated from entities and JPQL | SQL you did not write, read in a log after it has run |
| a persistence context that tracks every entity it loaded | a session with a lifetime, and an exception when you outlive it |
| lazy associations, behind proxies | one more query per association, unless you plan the fetch |
| one mapping for PostgreSQL, MySQL or Oracle | the database's own features reached through native queries |

None of the right-hand column is a defect. A team that wants the left-hand column pays it gladly,
and most Spring applications are that team. The libraries in this lesson exist for the teams that
looked at one row of the table and decided the trade was wrong for them.

## Every one of them ends in JDBC

Lesson 9 called JDBC the foundation everything else sits on, and the title is meant literally.
Whatever library is on top, the driver ends up holding a `PreparedStatement` with its parameters
bound, and **PostgreSQL never learns which library built it**. How a library talks to the database
is the same for all of them. The useful questions are who writes the SQL text, and what the library
remembers between one statement and the next.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 350\" role=\"img\" aria-label=\"Three columns of persistence libraries over one bar labelled JDBC. Left, where you write the SQL as text: JdbcClient, JDBI and MyBatis. Middle, where you write it as Java: jOOQ. Right, where the library writes it: Spring Data JPA on Hibernate, and EBean. An arrow from every column reaches the same JDBC bar, and one arrow goes from there to PostgreSQL.\"><defs><marker id=\"l12-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"125\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL as text you write</text><text x=\"350\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL as Java you write</text><text x=\"575\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">SQL the library writes</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"245\" y=\"36\" width=\"210\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"460\" y=\"36\" width=\"230\" height=\"174\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"30\" y=\"44\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">JdbcClient</text><text x=\"125\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Spring, lesson 9</text><rect x=\"30\" y=\"100\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JDBI</text><rect x=\"30\" y=\"156\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MyBatis</text><text x=\"125\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">statements in mappers</text><rect x=\"255\" y=\"100\" width=\"190\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">jOOQ</text><text x=\"350\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">classes generated from the schema</text><rect x=\"470\" y=\"44\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Spring Data JPA</text><rect x=\"470\" y=\"100\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Hibernate</text><rect x=\"580\" y=\"100\" width=\"100\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EBean</text><line x1=\"520\" y1=\"88\" x2=\"520\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><rect x=\"30\" y=\"244\" width=\"650\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">JDBC</text><text x=\"355\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Connection, PreparedStatement, ResultSet</text><line x1=\"125\" y1=\"210\" x2=\"125\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><line x1=\"350\" y1=\"210\" x2=\"350\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><line x1=\"575\" y1=\"210\" x2=\"575\" y2=\"242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line><text x=\"237\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every arrow ends in the same calls</text><rect x=\"290\" y=\"314\" width=\"130\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"329\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL</text><line x1=\"355\" y1=\"294\" x2=\"355\" y2=\"312\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12-ah)\"></line></svg>", "caption": "Every library in this lesson ends in the same JDBC calls, and the database never learns which one built the statement. What differs is who writes the SQL above them."}
```

The figure's three columns are the three answers this lesson meets:

- The SQL is text you write. Spring's `JdbcClient`, from lesson 9, JDBI and MyBatis bind your
  parameters and turn rows into objects, and they remember nothing between calls. The SQL is a
  string, and the compiler cannot read it.
- The SQL is Java you write. jOOQ generates a class for every table and gives you a builder that
  reads like SQL, so the compiler checks the query against the schema.
- The SQL is the library's. Hibernate, behind JPA, and EBean map entities to tables and write the
  statements themselves.

In a Spring application one more option sits close to home. **Spring Data JDBC** keeps the
repository interfaces of lesson 11, `CrudRepository`, derived query methods and `@Query` (with SQL
in it rather than JPQL), and drops the persistence context and lazy loading. Loading an object loads
everything that belongs to it at once rather than lazily, and saving writes it, with nothing tracked
in between. It is Spring's own answer to "repositories without Hibernate"; the next three sections
are the answers from outside Spring.
