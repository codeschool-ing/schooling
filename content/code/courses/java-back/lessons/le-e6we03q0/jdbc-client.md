---
title: JdbcClient, and a catalogue that survives a restart
version: 1
---

The last piece is the repository. Delete the in-memory one, so that only one `BookRepository`
remains for Spring to inject, and create
`src/main/java/com/example/bookshop/catalogue/JdbcBookRepository.java`:

```schooling-example
{"language": "java", "file": "JdbcBookRepository.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.springframework.jdbc.core.simple.JdbcClient;\nimport org.springframework.stereotype.Repository;\n", "note": "Nothing in the imports is `java.sql`. `JdbcClient` is Spring's, and it does the opening, preparing and closing that `Jdbc.java` wrote out by hand."}, {"code": "@Repository\npublic class JdbcBookRepository implements BookRepository {\n\n    private static final String COLUMNS = \"SELECT id, isbn, title, author, price_cents FROM book\";\n\n    private final JdbcClient jdbc;\n\n    public JdbcBookRepository(JdbcClient jdbc) {\n        this.jdbc = jdbc;\n    }\n", "note": "Still `@Repository`, still the `BookRepository` interface from lesson 5, so `BookService` does not change at all. `JdbcClient` arrives by constructor injection: Boot builds one around the pool."}, {"code": "    @Override\n    public List<Book> findAll() {\n        return jdbc.sql(COLUMNS + \" ORDER BY id\").query(Book.class).list();\n    }\n", "note": "`query(Book.class)` maps each row onto the record's constructor, by column name, and `list()` collects them. `price_cents` reaches `priceCents` because an underscore followed by a letter matches the capital."}, {"code": "    @Override\n    public Optional<Book> findById(long id) {\n        return jdbc.sql(COLUMNS + \" WHERE id = ?\").param(id).query(Book.class).optional();\n    }\n\n    @Override\n    public Optional<Book> findByIsbn(String isbn) {\n        return jdbc.sql(COLUMNS + \" WHERE isbn = ?\").param(isbn).query(Book.class).optional();\n    }\n", "note": "`param` fills the `?` in order, as `setLong` did. `optional()` answers an empty `Optional` for no rows and throws if there were two, which a unique ISBN makes impossible."}, {"code": "    @Override\n    public Book save(Book book) {\n        long id = jdbc.sql(\"\"\"\n                INSERT INTO book (isbn, title, author, price_cents)\n                VALUES (:isbn, :title, :author, :priceCents)\n                RETURNING id\"\"\")\n                .paramSource(book)\n                .query(Long.class)\n                .single();\n        return book.withId(id);\n    }\n}", "note": "Named parameters, `:isbn` and the rest, are filled from the record's accessors by `paramSource`. `RETURNING id` makes the `INSERT` answer with the number the database chose, and `single()` reads that one value."}]}
```

Read it beside `Jdbc.java`. Every method is one chain: the SQL, its parameters, what each row
becomes, and how many rows to expect. What is missing is everything that was ceremony there.
**`JdbcClient`** borrows a connection from the pool, prepares the statement, sets the parameters,
walks the `ResultSet`, maps each row, and closes it all in the right order, including when
something throws. The parameters are still parameters, `?` or `:name`, never pasted text.

Two things it adds that `Jdbc.java` did not have. A failure comes out as one of Spring's unchecked
`DataAccessException`s instead of a checked `SQLException`, so `BookService` does not have to
declare anything. And **`RETURNING id`**, a PostgreSQL addition to `INSERT`, makes the statement
answer with the `id` the sequence just chose. The service passed `0`, the database picked the real
number, and `withId` gives back a `Book` that carries it.

Build, after deleting the old class:

```
ana@vm:~/bookshop$ rm src/main/java/com/example/bookshop/catalogue/InMemoryBookRepository.java
ana@vm:~/bookshop$ mvn -q package
```

## Starting it

Start the application in a second terminal, with `java -jar target/bookshop-0.1.0.jar` in
`~/bookshop`:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:15:46.183-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 15076 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:15:46.186-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:15:47.013-03:00  INFO 15076 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-22T19:15:47.022-03:00  INFO 15076 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:15:47.023-03:00  INFO 15076 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:15:47.044-03:00  INFO 15076 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 807 ms
2026-10-22T19:15:47.124-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2026-10-22T19:15:47.368-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@427a12b6
2026-10-22T19:15:47.370-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2026-10-22T19:15:47.661-03:00  INFO 15076 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T19:15:47.669-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 1.755 seconds (process running for 2.059)
2026-10-22T19:15:47.696-03:00  INFO 15076 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 3 books
```

Three lines between Tomcat and `Started` are new, and they are the pool: `HikariPool-1 - Starting...`,
`Added connection` with the driver's `PgConnection`, and `Start completed`. The first connection
ran `schema.sql` and `data.sql`, and the last line is lesson 5's `CatalogueReport` counting **3
books** that now come from a `SELECT`. Ask the server who is connected while it runs:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c "SELECT application_name, state, count(*) FROM pg_stat_activity WHERE usename = 'bookshop' GROUP BY 1, 2"
    application_name    | state  | count 
------------------------+--------+-------
 PostgreSQL JDBC Driver | idle   |    10
 psql                   | active |     1
(2 rows)
```

**Ten connections, all `idle`**, opened by the driver for the pool, and the one `active` is `psql`
asking. Ten is HikariCP's default size. A request borrows one for a few milliseconds and gives it
back; lesson 14 measures what happens when they are all borrowed at once, and how to size the pool.

## The API, unchanged, on a database

```
ana@vm:~/bookshop$ curl -s localhost:8080/books | python3 -m json.tool
[
    {
        "id": 1,
        "isbn": "9786500000016",
        "title": "Dom Casmurro",
        "author": "Machado de Assis",
        "priceCents": 3990
    },
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 3,
        "isbn": "9786500000030",
        "title": "Frankenstein",
        "author": "Mary Shelley",
        "priceCents": 3500
    }
]
ana@vm:~/bookshop$ curl -si -w '\n' localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000054", "title": "Wise Blood", "author": "Flannery O'\''Connor", "priceCents": 4100}'
HTTP/1.1 201 
Location: /books/4
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:15:48 GMT

{"id":4,"isbn":"9786500000054","title":"Wise Blood","author":"Flannery O'Connor","priceCents":4100}
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'SELECT id, title, author FROM book'
 id |      title       |      author       
----+------------------+-------------------
  1 | Dom Casmurro     | Machado de Assis
  2 | The Time Machine | H. G. Wells
  3 | Frankenstein     | Mary Shelley
  4 | Wise Blood       | Flannery O'Connor
(4 rows)
```

The list is `data.sql`'s three books, read by `findAll`. The `POST` is lesson 6's, answered as
before with `201` and a `Location`, and the `id` in it, **4**, is the one `RETURNING` brought back
from the sequence. `-w '\n'` only prints a line break after the body, which ends without one. And
`psql` shows the row is in the table, where any other program can read it.

Now the test this lesson was for. Stop the application with `Ctrl+C` and start it again. Among the
start-up lines in the second terminal:

```
2026-10-22T19:15:51.622-03:00  INFO 15244 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 4 books
```

**4 books.** Lesson 7's bookshop would have said 3, because the book you added lived in a `Map`
and the map ended with the process. This one is in PostgreSQL, and `data.sql` ran again without
adding a copy of anything.
