---
title: The entity manager and JPQL
version: 1
---

The **`EntityManager`** is the one interface a program talks to: `find` loads an entity by its key,
`persist` adds a new one, `createQuery` runs a query in **JPQL**, the Jakarta Persistence Query
Language. JPQL looks like SQL and is not SQL. It names entities and their fields, never tables and
columns, and Hibernate translates it into the SQL of whichever database it is talking to.

The repositories keep the interfaces lesson 5 gave them, so nothing above them has to know the
mapper exists. `BookRepository` does not change at all. Delete `JdbcBookRepository.java` and create
`JpaBookRepository.java` beside it:

```schooling-example
{
  "language": "java",
  "file": "JpaBookRepository.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport jakarta.persistence.EntityManager;\n\nimport org.springframework.stereotype.Repository;\n",
      "note": "The same package as before, and one import that matters: `EntityManager`, the specification's interface to the mapper."
    },
    {
      "code": "@Repository\npublic class JpaBookRepository implements BookRepository {\n\n    private final EntityManager em;\n\n    public JpaBookRepository(EntityManager em) {\n        this.em = em;\n    }\n",
      "note": "`@Repository` as in lesson 9. The `EntityManager` arrives through the constructor like any other bean. What Spring injects is a stand-in that hands every call to the persistence context of the transaction running at that moment, so one repository serves every request at once."
    },
    {
      "code": "    @Override\n    public List<Book> findAll() {\n        return em.createQuery(\"select b from Book b order by b.id\", Book.class)\n                .getResultList();\n    }\n",
      "note": "JPQL, not SQL. `Book` is the entity and `b.id` its field; there is no table name and no column list. Hibernate turns this into a `SELECT` on `book` and every column the entity maps. Notice what is not asked for: the author."
    },
    {
      "code": "    @Override\n    public Optional<Book> findById(long id) {\n        return Optional.ofNullable(em.find(Book.class, id));\n    }\n",
      "note": "`find` loads one entity by its key, or returns `null` when there is none, and `Optional.ofNullable` turns that into the empty case the service already answers with lesson 7's `BookNotFoundException`."
    },
    {
      "code": "    @Override\n    public Optional<Book> findByIsbn(String isbn) {\n        return em.createQuery(\"select b from Book b where b.isbn = :isbn\", Book.class)\n                .setParameter(\"isbn\", isbn)\n                .getResultStream()\n                .findFirst();\n    }\n",
      "note": "A parameter is named with a colon and bound by name, never glued into the string: JPQL is protected against injection the same way lesson 9's `?` placeholders were."
    },
    {
      "code": "    @Override\n    public Book save(Book book) {\n        em.persist(book);\n        return book;\n    }\n}",
      "note": "`persist` makes a new object managed. There is no `INSERT` statement in this file, and with `IDENTITY` keys Hibernate runs one straight away, because only the database can say what the id is."
    }
  ]
}
```

The author has a repository of its own now, because adding a book means finding its author or
creating one. Create `AuthorRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

public interface AuthorRepository {

    Optional<Author> findByName(String name);

    Author save(Author author);
}
```

and `JpaAuthorRepository.java`, which is the same pattern again:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

import jakarta.persistence.EntityManager;

import org.springframework.stereotype.Repository;

@Repository
public class JpaAuthorRepository implements AuthorRepository {

    private final EntityManager em;

    public JpaAuthorRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<Author> findByName(String name) {
        return em.createQuery("select a from Author a where a.name = :name", Author.class)
                .setParameter("name", name)
                .getResultStream()
                .findFirst();
    }

    @Override
    public Author save(Author author) {
        em.persist(author);
        return author;
    }
}
```

## Where the transaction goes

Every call above runs inside a **persistence context**, the mapper's working memory for one unit of
work, and in a Spring application that unit is a transaction. **The service opens it, not the
repository**, because the service knows where a piece of work starts and ends. Replace
`BookService.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BookService {

    private final BookRepository books;
    private final AuthorRepository authors;

    public BookService(BookRepository books, AuthorRepository authors) {
        this.books = books;
        this.authors = authors;
    }

    @Transactional(readOnly = true)
    public List<BookResponse> list() {
        return books.findAll().stream().map(BookResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public BookResponse get(long id) {
        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));
    }

    @Transactional
    public BookResponse add(BookRequest request) {
        if (books.findByIsbn(request.isbn()).isPresent()) {
            throw new DuplicateIsbnException(request.isbn());
        }
        Author author = authors.findByName(request.author())
                .orElseGet(() -> authors.save(new Author(request.author())));
        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents()));
        return BookResponse.from(book);
    }
}
```

`@Transactional` comes from Spring, not from JPA. On a method it means: begin a transaction before
the method runs, commit it when the method returns, roll it back if the method throws. `readOnly =
true` tells Hibernate that nothing read here will be written back, so it skips the work it would
otherwise do to notice changes. Lesson 14 is about transactions properly; here they matter for one
reason, which the next two sections show from both sides.

**The service returns `BookResponse`, never an entity.** The mapping from an entity to the record the
API sends happens inside the transaction, while the author can still be loaded. `BookResponse.from`
changes to read the entity's getters:

```java
package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle(),
                book.getAuthor().getName(), book.getPriceCents());
    }
}
```

and the controller loses the mapping it used to do, since what it receives is already the response.
Replace `BookController.java`:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public List<BookResponse> list() {
        return books.list();
    }

    @GetMapping("/{id}")
    public BookResponse get(@PathVariable long id) {
        return books.get(id);
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        BookResponse book = books.add(request);
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(book);
    }
}
```

## Running it

Build, and start the application in a second terminal with `java -jar target/bookshop-0.1.0.jar`:

```
(capture build)
```

The catalogue report from lesson 5 runs at start-up and calls `list()`, so its line in the second
terminal is the first sign the mapper works:

```
(capture report)
```

And the API answers as it did in lesson 9, with three more books and a different shape underneath:

```
(capture books)
```

## If you skipped the drop

If the database still holds lesson 9's table, the application does not start. This is what the
second terminal prints, cut down with `grep` to the line that matters:

```
(capture stale)
```

`data.sql` asked for a column the old table does not have, and Spring stops the application rather
than run against a schema it could not prepare. Go back to the end of the previous section and run
the two commands.

## Seeing the SQL

The application now runs SQL that appears nowhere in its source, and the rest of this lesson needs to
see it. Hibernate logs every statement it sends under the logger `org.hibernate.SQL`, at `debug`.
Create `src/main/resources/application-sql.properties`:

```properties
logging.level.org.hibernate.SQL=debug
```

That file only counts when the `sql` profile is active (lesson 4), so the noise stays out of a normal
run. Stop the application, start it again with the profile, and ask for one book:

```
(capture one-book)
```

The second terminal shows what that request cost:

```
(capture one-book-log)
```

**Two statements for one book.** `find` loaded the row of `book` and nothing more; the author was a
proxy. Then `BookResponse.from` called `getAuthor().getName()`, the proxy needed a name it did not
have, and it asked for the row of `author`. That is lazy loading working exactly as designed, and it
is also, in miniature, the problem two sections from now.
