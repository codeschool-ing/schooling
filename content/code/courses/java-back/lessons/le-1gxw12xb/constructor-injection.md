---
title: Why the constructor
version: 1
---

Spring can hand a bean its dependencies in three ways: as arguments to its constructor, by writing a
field directly, or by calling a setter. The bookshop uses the first everywhere. This section is the
argument for it, and part of the argument is a detour through the second.

```schooling-example
{"language": "java", "file": "BookService.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.springframework.stereotype.Service;\n"}, {"code": "@Service\npublic class BookService {", "note": "`@Service` is the label component scanning looks for. Nothing else in the class mentions Spring."}, {"code": "\n    private final BookRepository books;", "note": "`final`: once the constructor has run, the field holds a repository and nothing can empty it or swap it. Its type is the interface, so the service cannot tell which store it was given."}, {"code": "\n    public BookService(BookRepository books) {\n        this.books = books;\n    }\n", "note": "The only constructor, so Spring uses it without being told. `@Autowired` on it would be allowed and would change nothing; it is needed only to pick one of several constructors."}, {"code": "    public List<Book> list() {\n        return books.findAll();\n    }\n\n    public Optional<Book> find(long id) {\n        return books.findById(id);\n    }\n\n    public Book add(String isbn, String title, String author, int priceCents) {\n        return books.save(new Book(0, isbn, title, author, priceCents));\n    }\n}", "note": "Everything else is ordinary code calling `books`, which the constructor has already guaranteed is there."}]}
```

Four properties follow from taking dependencies in the constructor, and the bookshop already relies
on each of them:

- the object is complete when `new` returns, and there is no moment in which `books` is `null`;
- the field can be `final`, so nothing replaces the repository halfway through the application's life;
- the dependencies are the constructor's parameter list, so a class that needs seven things says so
  in its signature, where a reviewer sees it;
- any code can build the object with no container at all. `Wiring.java` did, and lesson 19 builds
  the order service with `new`, two stand-in repositories and a fixed clock.

## A detour through field injection

**Field injection is not just a shorter way to write the same thing**, although it is shorter, it
fills a great deal of older code and tutorials, and it works. Replace `BookService.java` with this
version for a moment:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BookService {

    @Autowired
    private BookRepository books;

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

Spring creates the object with the constructor Java writes when a class declares none, and then sets
`books` by reflection, private as it is. The application starts as before. `Wiring.java` no longer
compiles:

```
!!! MISSING BLOCK field-a
```

The class has no constructor that takes a repository any more. The obvious repair, `new
BookService()`, compiles and fails somewhere else:

```
!!! MISSING BLOCK field-b
```

That `NullPointerException` is the cost. The object exists without its dependency, and nothing
outside Spring can give it one except more reflection, so a test of `BookService` would need either
the whole container or a tool that writes private fields. With a constructor, the compiler refuses to
build the object incomplete; with a field, the program finds out when it runs. The field also cannot
be `final`, since it is written after construction.

Undo the detour: put `BookService.java` back as the first section shows it, and run
`mvn -B -q package` again.

## Setters, and the interface

**Setter injection**, a `setBooks` method that Spring calls after construction, is for a dependency
that is genuinely optional: the class works without it and does more with it. The bookshop has none.

`BookService` depends on the interface `BookRepository`, not on `InMemoryBookRepository`, and
Spring does not require that. A constructor can ask for a class, and Spring injects the bean of that
class. The interface pays here for a reason particular to this course: lesson 9 deletes
`InMemoryBookRepository`, adds a repository that reads PostgreSQL, and `BookService` does not change
by a line. An interface invented for a class that will only ever have one implementation buys a
second file and nothing else; this one has its second implementation four lessons away.
