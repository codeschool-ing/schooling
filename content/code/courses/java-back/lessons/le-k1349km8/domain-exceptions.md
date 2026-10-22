---
title: Exceptions in the shop's own words
version: 1
---

## Where this lesson starts

This lesson starts from the bookshop as lesson 6 left it, built and running in a second terminal with
`java -jar target/bookshop-0.1.0.jar`. Ask it for three things it ought to refuse. `-i` makes curl print
the status line and the headers before the body, and `-w '\n'` adds a line break after the body, which a
JSON answer does not end with:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 404 
Content-Length: 0
Date: Thu, 22 Oct 2026 22:40:43 GMT


ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' -w '\n'
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:40:43 GMT
Connection: close

{"timestamp":"2026-10-22T22:40:43.514Z","status":400,"error":"Bad Request","path":"/books"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author": "Machado de Assis", "priceCents": 3990}' -w '\n'
HTTP/1.1 201 
Location: /books/4
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:40:43 GMT

{"id":4,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990}
```

Each answer is wrong in its own way. The first is a 404 with `Content-Length: 0`, which is correct and
says nothing: a client cannot tell "there is no book 99" from "there is no such address". The second is
Spring Boot's own error page, served as JSON. Four fields broke their constraints and the body names
none of them. The third is a bug. ISBN `9786500000016` is Dom Casmurro, book 1, and the shop has just
stored it a second time as book 4, because nothing in lesson 6 looked.

## Where an error is decided

The tempting picture is that errors belong to the controller: each method looks at what happened and
builds the response, the way lesson 6's `get` turned an empty `Optional` into
`ResponseEntity.notFound()`. That works for one method and stops working at the second rule, because
**the rule and the response live in different layers**. "An ISBN appears once in the catalogue" holds
however a book arrives, through this controller, an import job or a test, so it belongs in
`BookService`. And `BookService` knows nothing about HTTP. A 409 is how the web says it, not how the
shop says it.

So the service says what went wrong in the shop's own words, by throwing an exception named after it,
and one place in the web layer turns each exception into HTTP. Create two classes in
`src/main/java/com/example/bookshop/catalogue/`. `BookNotFoundException.java`:

```java
package com.example.bookshop.catalogue;

public class BookNotFoundException extends RuntimeException {

    public BookNotFoundException(long id) {
        super("No book has id " + id);
    }
}
```

And `DuplicateIsbnException.java`:

```java
package com.example.bookshop.catalogue;

public class DuplicateIsbnException extends RuntimeException {

    public DuplicateIsbnException(String isbn) {
        super("A book with ISBN " + isbn + " is already in the catalogue");
    }
}
```

Both extend `RuntimeException`, so no method has to declare them. That is the point: the controller
between the service and the client does nothing with them, and a checked exception would force it to
catch or declare one it cannot handle. It matters again in lesson 14, where Spring rolls a transaction
back on a `RuntimeException` and, by default, not on a checked one. Each message is a sentence a client
may read, built only from what the client sent; the last section of this lesson says why that matters.

Replace `BookService.java` with this. `find`, which returned an `Optional`, becomes `get`, which returns
the book or throws, and `add` refuses an ISBN the catalogue already has:

```java
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.stereotype.Service;

@Service
public class BookService {

    private final BookRepository books;

    public BookService(BookRepository books) {
        this.books = books;
    }

    public List<Book> list() {
        return books.findAll();
    }

    public Book get(long id) {
        return books.findById(id).orElseThrow(() -> new BookNotFoundException(id));
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        if (books.findByIsbn(isbn).isPresent()) {
            throw new DuplicateIsbnException(isbn);
        }
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
```

The check and the save are two steps, so two requests arriving together with the same new ISBN could
both pass the check. A map in memory cannot close that gap. A database can, and lesson 9's table does,
with a `UNIQUE` constraint on the column.

Then replace `BookController.java`. Only `get` changed: it returns a `BookResponse` and leaves the
missing book to the exception.

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
        return books.list().stream().map(BookResponse::from).toList();
    }

    @GetMapping("/{id}")
    public BookResponse get(@PathVariable long id) {
        return BookResponse.from(books.get(id));
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

## An exception nobody translates

Build with `mvn -q package`. `-q` prints errors and nothing else, so silence is success. Stop the
application in the second terminal with Ctrl+C, start it again, and ask for book 99:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 500 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:40:52 GMT
Connection: close

{"timestamp":"2026-10-22T22:40:52.405Z","status":500,"error":"Internal Server Error","path":"/books/99"}
```

A **500**, Internal Server Error, for a book that is simply not there. The exception left the
controller, crossed Spring MVC with nothing claiming it and reached the servlet container, and Spring
Boot's error page answered with the only status it has for that case: the server failed. The second
terminal logged it, and the stack trace runs on below these lines:

```
2026-10-22T19:40:52.394-03:00 ERROR 5197 --- [bookshop] [nio-8080-exec-1] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: com.example.bookshop.catalogue.BookNotFoundException: No book has id 99] with root cause

com.example.bookshop.catalogue.BookNotFoundException: No book has id 99
```

That is the right answer to an exception nobody planned for, and the wrong one for this exception,
which was planned. The next section gives it its 404.
