---
title: The catalogue on Spring Data
version: 1
---

Eight files of the catalogue change. Two of them leave, because lesson 10's hand-written classes have
nothing left to do once Spring Data implements both interfaces:

```
ana@vm:~/bookshop$ rm src/main/java/com/example/bookshop/catalogue/JpaBookRepository.java src/main/java/com/example/bookshop/catalogue/JpaAuthorRepository.java
```

`AuthorRepository.java` becomes the interface in the previous section; replace it now if you have not.
Then replace `BookRepository.java` with this. Everything in it is one of this lesson's sections.
`findByIsbn` and the long `findByTitle…` are derived queries, the subject of the next one, and
`@EntityGraph` is the section after. `@Query` and the `TitleAndPrice` it returns come next, and `Page`
with `Pageable` is the last.

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findByIsbn(String isbn);

    @EntityGraph(attributePaths = "author")
    Page<Book> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = "author")
    List<Book> findByTitleContainingIgnoreCaseOrderByTitle(String text);

    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);
}
```

Create `TitleAndPrice.java` beside it. It is an interface with two getters and no implementation
anywhere in the project, which the section on `@Query` explains:

```java
package com.example.bookshop.catalogue;

public interface TitleAndPrice {

    String getTitle();

    int getPriceCents();
}
```

`BookService` keeps its shape, a transaction around every method and DTOs on the way out, and gains
three methods for the three new queries. Replace it with this:

```schooling-example
{"language": "java", "file": "BookService.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\n\nimport org.springframework.data.domain.Page;\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\n@Service\npublic class BookService {\n\n    private final BookRepository books;\n    private final AuthorRepository authors;\n\n    public BookService(BookRepository books, AuthorRepository authors) {\n        this.books = books;\n        this.authors = authors;\n    }\n", "note": "The two repositories arrive through the constructor, as they always have. Their types are the same interfaces `BookService` has depended on since lesson 5, so nothing here knows that what implements them changed."}, {"code": "    @Transactional(readOnly = true)\n    public long count() {\n        return books.count();\n    }\n", "note": "`count` is inherited from `CrudRepository` and becomes one `select count(*)`. The catalogue report used to call `list().size()`, which loaded every book in order to count them."}, {"code": "    @Transactional(readOnly = true)\n    public Page<BookResponse> list(Pageable pageable) {\n        return books.findAllBy(pageable).map(BookResponse::from);\n    }\n", "note": "A page of entities, mapped to DTOs while the transaction is still open. `Page.map` converts the content and keeps the page's numbers: which page, how big, how many in total."}, {"code": "    @Transactional(readOnly = true)\n    public List<BookResponse> search(String text) {\n        return books.findByTitleContainingIgnoreCaseOrderByTitle(text).stream().map(BookResponse::from).toList();\n    }\n", "note": "The derived query from the next section. The order comes back from the database already sorted, so nothing here sorts."}, {"code": "    @Transactional(readOnly = true)\n    public List<TitleAndPrice> titlesBy(String author) {\n        return books.findTitlesByAuthor(author);\n    }\n", "note": "The projection goes out as it came in. It holds only a title and a price, which is already all the client should see, so there is no DTO to map to."}, {"code": "    @Transactional(readOnly = true)\n    public BookResponse get(long id) {\n        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));\n    }\n", "note": "`findById` is inherited. The book's author is a lazy reference, and `BookResponse.from` loads it when it reads the name, inside this transaction."}, {"code": "    @Transactional\n    public BookResponse add(BookRequest request) {\n        if (books.findByIsbn(request.isbn()).isPresent()) {\n            throw new DuplicateIsbnException(request.isbn());\n        }\n        Author author = authors.findByName(request.author())\n                .orElseGet(() -> authors.save(new Author(request.author())));\n        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents()));\n        return BookResponse.from(book);\n    }\n}", "note": "Unchanged from lesson 10, and it is now three Spring Data calls: `findByIsbn` and `findByName` are derived queries, and `save` is inherited."}]}
```

The controller gains two endpoints, and its list becomes a page. `GET /books` now takes a `Pageable`,
which Spring Data builds from the request's `page`, `size` and `sort` parameters, and answers a
`PagedModel`, the JSON shape of one page. `GET /books/search?q=…` searches titles and
`GET /books/by-author?name=…` lists one author's titles with their prices. Replace
`BookController.java`:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public PagedModel<BookResponse> list(@PageableDefault(size = 20, sort = "id") Pageable pageable) {
        return new PagedModel<>(books.list(pageable));
    }

    @GetMapping("/search")
    public List<BookResponse> search(@RequestParam String q) {
        return books.search(q);
    }

    @GetMapping("/by-author")
    public List<TitleAndPrice> byAuthor(@RequestParam String name) {
        return books.titlesBy(name);
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

And `CatalogueReport` counts the books instead of listing them:

```java
package com.example.bookshop.catalogue;

import java.time.Clock;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class CatalogueReport implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(CatalogueReport.class);

    private final BookService books;
    private final Clock clock;

    public CatalogueReport(BookService books, Clock clock) {
        this.books = books;
        this.clock = clock;
    }

    @Override
    public void run(String... args) {
        log.info("Catalogue opened on {} with {} books",
                LocalDateTime.now(clock).toLocalDate(), books.count());
    }
}
```

## Running it with the SQL in view

Build it. `-q` keeps Maven quiet unless something fails, so a build with nothing to report prints
nothing:

```
ana@vm:~/bookshop$ mvn -q package
```

Then start the application in a **second terminal**, with lesson 10's `sql` profile, which logs every
statement Hibernate sends. The `grep` keeps three kinds of line out of the startup: Spring Data's report
of the repositories it found, the SQL, and the catalogue report.

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'interfaces|hibernate.SQL|Catalogue'
2026-10-22T19:18:03.006-03:00  INFO 21638 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 50 ms. Found 2 JPA repository interfaces.
2026-10-22T19:18:07.935-03:00 DEBUG 21638 --- [bookshop] [           main] org.hibernate.SQL                        : select count(*) from book b1_0
2026-10-22T19:18:07.962-03:00  INFO 21638 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

**`Found 2 JPA repository interfaces`** is the scan from the first section, and it happened before the
database was even reached: the two proxies exist from the start. **`select count(*) from book b1_0`** is
the inherited `count()`, sent by `CatalogueReport` through `BookService.count`, and `b1_0` is the alias
Hibernate gives the `book` table in every statement it writes.

Leave that terminal running. Every section from here sends requests from the first terminal and reads
what arrived in the second. When a section changes a file, stop the application with Ctrl+C, run
`mvn -q package`, and start it again with the same command.
