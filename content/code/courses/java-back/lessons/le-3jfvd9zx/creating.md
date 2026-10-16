---
title: Creating a book with POST, 201 and Location
version: 1
---

Replace `BookController.java` with this version. The two `GET` methods are unchanged, and the new one
is at the bottom:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

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
    public ResponseEntity<BookResponse> add(@RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

What the new method says, annotation by annotation:

- **`@PostMapping`** with no path of its own answers `POST /books`, the same path as the list with a
  different method. That is the HTTP convention: a `GET` on a collection reads it, a `POST` to it adds
  to it.
- **`@RequestBody`** is step 2 with a body: Jackson reads the JSON into a `BookRequest`, and only then
  is the method called.
- The service builds the `Book` and the repository picks its id, counting on from the three books it
  started with.
- **`ResponseEntity.created(uri)`** sets the status to **201 Created** and adds a **`Location`**
  header naming where the new book now lives. The body is the book as stored, so the client learns
  its id without asking again.

Build it with `mvn -q package`, stop the application in the second terminal with Ctrl+C, and start it
again with `java -jar target/bookshop-0.1.0.jar`.

## Sending a body with curl

Two more flags. `-d '...'` sends the text as the body, and makes the request a `POST` without saying
so. `-H 'Content-Type: application/json'` adds the header that tells the server the body is JSON.

```
(pending post-201)
```

A 201, `Location: /books/4` and the new book in the body. Asking for the `Location` gives the same
book back: the header is an address a client can use straight away.

## The id the client cannot choose

This body says `"id": 1`, the id of *Dom Casmurro*:

```
(pending post-id)
```

The new book is number 5, and book 1 is untouched. Jackson found no `id` component in `BookRequest`
and dropped the property, without an error or a line in the log. The request record decided what a
client is allowed to say.

## Forgetting the header

```
(pending post-415)
```

Without `-H`, curl labels a `-d` body `application/x-www-form-urlencoded`, the format an HTML form
sends. Nothing in this controller reads forms, so the answer is **415 Unsupported Media Type**, and
its `Accept` header lists what `POST /books` does read. When a POST you expected to work answers 415,
the `Content-Type` is the first thing to check.

## A body that makes no sense

```
(pending post-junk)
```

A five-digit ISBN, an empty title and a price below zero, accepted and stored as book 6. Jackson made
sure the JSON was well formed and that every value fitted its type. Whether the values make sense is
a different question, and nothing in the application asks it yet. The next section does.
