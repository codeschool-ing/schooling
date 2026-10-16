---
title: Bean Validation, rules on the request
version: 1
---

Before changing anything, send the application as it stands a book with no price:

```
(pending no-price-int)
```

The second terminal says what happened:

```
(pending no-price-int-log)
```

A 400, and a refusal from **Jackson**: a missing price cannot go into an `int`, and Jackson 3 refuses
rather than inventing a 0. That is the right answer from the wrong place. Jackson refused at step 2,
before the record existed, and its message names a Java type, not a field a client sent. Every other
rule about a book's values has to run after the record exists, and has to say which field it is
about.

## The standard and the starter

**Bean Validation** is the Jakarta standard for that. Its rules are annotations on an object's
fields, called **constraints**, and a validator checks an object against them and reports every
violation it finds, not only the first. The API lives in `jakarta.validation`, and **Hibernate
Validator** is the implementation Spring Boot uses; it shares a name and an origin with the Hibernate
of lesson 10 and is a separate library.

Replace `pom.xml` with this one. The only change is the second dependency, and it carries no version
because the parent manages it, as lesson 4 explained:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

Then replace `BookRequest.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents) {
}
```

| constraint | refuses |
|---|---|
| `@NotNull` | `null`, which includes a property missing from the JSON |
| `@NotBlank` | `null`, an empty string, or a string of spaces |
| `@Size(max = 200)` | a string longer than 200 characters |
| `@PositiveOrZero` | a number below zero |

**The price is an `Integer` now.** A missing price arrives as `null`, which an `Integer` can hold, so
Jackson has nothing to refuse and `@NotNull` reports the problem as a field error, alongside any
other. The ISBN has only `@NotNull` for the moment.

Build, restart, and send the nonsense of the previous section again:

```
(pending constraints-alone)
```

**Accepted, as before.** The constraints are on the record and nothing reads them. Spring validates a
`@RequestBody` argument only when the parameter asks for it, and this one does not ask.

## @Valid asks

Replace `BookController.java` with the final version. One word changed, `@Valid` in front of
`@RequestBody`, and the import it needs:

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
    public ResponseEntity<BookResponse> get(@PathVariable long id) {
        return books.find(id)
                .map(BookResponse::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

**`@Valid`** tells step 2 to run the validator on the record Jackson built, and to call the method
only if it reports nothing. Build, restart, and try the nonsense once more:

```
(pending junk-400)
```

A 400 at last, with the body Spring Boot writes for any error: a time, the status, its name and the
path. It says the request failed and not why. The second terminal knows why:

```
(pending junk-400-log)
```

`MethodArgumentNotValidException` is what Spring throws when `@Valid` finds violations, and the line
lists every **field error**. `title` was rejected with the value `[]` and "must not be blank";
`priceCents` with `[-5]` and "must be greater than or equal to 0". Each message is the default text
of its constraint. The ISBN `12345` passed, because `@NotNull` is all it asks.

By default Spring Boot leaves those field errors out of the body, so a client sees a bare 400 and has
to guess which field it got wrong. Lesson 7 builds an error body that names each field and says what
is wrong with it.

A missing price is now a field error like the others:

```
(pending no-price-null)
```

```
(pending no-price-null-log)
```

## Two gates, and the method behind both

Jackson has not gone away. Send a body that is not JSON at all, cut off after the ISBN:

```
(pending malformed)
```

```
(pending malformed-log)
```

So a body passes two gates before `add` runs, and each fails in its own way:

| what is wrong | who refuses | what the log names |
|---|---|---|
| the body is not JSON, or a value cannot fit its type | Jackson, while building the record | `HttpMessageNotReadableException` |
| the record exists, and a value breaks a constraint | Bean Validation, because of `@Valid` | `MethodArgumentNotValidException`, one field error per broken rule |

In both cases the method is never called, which is what makes the controller's own code short: by the
time `add` runs, the request is well formed and every rule has held.

## What the standard constraints cannot say

```
(pending wrong-check-201)
```

`9786500000048` is thirteen digits, so `@NotNull` is satisfied and nothing else is asked. It is not an
ISBN: the last digit of an ISBN is computed from the other twelve, and here it is wrong. No constraint
in the standard knows that rule. Hibernate Validator has an `@ISBN` of its own outside the standard,
but a rule of your own domain is what the mechanism is for, and the next section writes one.
