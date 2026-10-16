---
title: The objects, built by hand
version: 1
---

The bookshop gets its first real classes in this lesson: a book, a place to keep books, a service
over that place, and a report that runs at start-up. They depend on each other, so something has to
create them in the right order and pass each one the objects it asks for. Spring will do that. This
section does it by hand first, so that nothing Spring does later is a mystery.

A common picture of Spring is that the annotations on these classes are what make them work: that
`@Service` turns a class into a service. **An annotation does nothing by itself.** It is a label that
some other code may read, and a program that never reads it runs exactly as if it were not there. The
program at the end of this section is that program.

## The six files

Create these in `~/bookshop`, beside what lesson 4 left there. Five are in the package
`com.example.bookshop.catalogue`, and the sixth in `com.example.bookshop.config`.

`src/main/java/com/example/bookshop/catalogue/Book.java`:

```java
package com.example.bookshop.catalogue;

public record Book(long id, String isbn, String title, String author, int priceCents) {

    public Book withId(long newId) {
        return new Book(newId, isbn, title, author, priceCents);
    }
}
```

A **record** carries the five values of a book, with the price in cents so that no arithmetic on it
ever rounds. `withId` returns a copy with a new id, which is how the repository below numbers a book
it stores.

`src/main/java/com/example/bookshop/catalogue/BookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

public interface BookRepository {

    List<Book> findAll();

    Optional<Book> findById(long id);

    Optional<Book> findByIsbn(String isbn);

    Book save(Book book);
}
```

What any store of books has to answer. It is an interface, so the code that uses it depends on the
questions and not on where the answers are kept; lesson 9 puts PostgreSQL behind the same four
methods.

`src/main/java/com/example/bookshop/catalogue/InMemoryBookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryBookRepository implements BookRepository {

    private final Map<Long, Book> books = new ConcurrentSkipListMap<>();
    private final AtomicLong nextId = new AtomicLong(1);

    public InMemoryBookRepository() {
        save(new Book(0, "9786500000016", "Dom Casmurro", "Machado de Assis", 3990));
        save(new Book(0, "9786500000023", "The Time Machine", "H. G. Wells", 2950));
        save(new Book(0, "9786500000030", "Frankenstein", "Mary Shelley", 3500));
    }

    @Override
    public List<Book> findAll() {
        return List.copyOf(books.values());
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.ofNullable(books.get(id));
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return books.values().stream().filter(b -> b.isbn().equals(isbn)).findFirst();
    }

    @Override
    public Book save(Book book) {
        Book stored = book.id() == 0 ? book.withId(nextId.getAndIncrement()) : book;
        books.put(stored.id(), stored);
        return stored;
    }
}
```

The store this lesson uses: a map in memory, filled with three books when the object is created and
forgotten when the application stops. The map is a `ConcurrentSkipListMap` and the counter an
`AtomicLong`, both safe to use from several threads at once, and the section on scopes says why that
matters.

`src/main/java/com/example/bookshop/catalogue/BookService.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

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

    public Optional<Book> find(long id) {
        return books.findById(id);
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
```

The class the rest of the application will call. **It does not create its repository.** It asks for
one, as a constructor parameter, and keeps whatever it is given.

`src/main/java/com/example/bookshop/catalogue/CatalogueReport.java`:

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
                LocalDateTime.now(clock).toLocalDate(), books.list().size());
    }
}
```

A `CommandLineRunner` is Spring Boot's hook for "run this once the application has started". The
report needs the service, to count the books, and a clock, to know the date.

`src/main/java/com/example/bookshop/config/ClockConfig.java`:

```java
package com.example.bookshop.config;

import java.time.Clock;
import java.time.ZoneId;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ClockConfig {

    @Bean
    public Clock clock() {
        return Clock.system(ZoneId.of("America/Sao_Paulo"));
    }
}
```

The odd one out. It is not part of the bookshop but a recipe for an object the bookshop needs, and
the section on `@Bean` explains it.

## Wiring them yourself

None of these classes calls `new` on anything it depends on. Somebody still has to, and in the order
the constructors force: the repository before the service that takes it, the service and the clock
before the report. Save this as `~/Wiring.java`, in your home directory and outside the project:

```java
// Wiring.java: the bookshop's objects, built and connected by hand.
import com.example.bookshop.catalogue.BookService;
import com.example.bookshop.catalogue.CatalogueReport;
import com.example.bookshop.catalogue.InMemoryBookRepository;
import com.example.bookshop.config.ClockConfig;

void main() {
    var repository = new InMemoryBookRepository();
    var service = new BookService(repository);
    var clock = new ClockConfig().clock();
    var report = new CatalogueReport(service, clock);
    report.run();
}
```

It is a single-file program, which Java 25 runs straight from its source, and its `void main()` needs
no class around it. It needs the bookshop's compiled classes on the class path, and the libraries
those use. `mvn -B -q package` compiles the project: `-B` runs Maven without colours or progress
output, and `-q` keeps it silent unless something fails. Then the dependency plugin's
`build-classpath` goal writes the path of every dependency's jar into a file, which the `java` command
reads back with `$(cat ...)`:

```
!!! MISSING BLOCK by-hand
```

The report ran and counted three books. Spring's jars were on the class path and Spring never
started: nothing read the annotations, and they changed nothing. The log line looks different from a
Spring Boot application's because Boot never set up the logging; this is Logback's plain default.

Each class received its collaborators from outside, through its constructor, and that is all
**dependency injection** means. Which object is created, in what order and handed to whom was decided
in one place, `main`, and not inside each class.

**Inversion of control** is the wider idea those lines are an instance of. A class does not fetch
what it needs, and does not decide when it runs: something outside builds it and calls it.
`CatalogueReport.run` is the plainest case in the bookshop, because nothing in the bookshop's own
code ever calls it. In `Wiring.java` the outside party is `main`. In the application it is Spring,
and the next section watches it make the same calls in the same order.
