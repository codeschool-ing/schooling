---
title: A controller, and curl as its client
version: 1
---

The bookshop has been a web server since lesson 4, and it has never answered a question. Lesson 5
filled it with beans, a service and a repository holding three books, but nothing connects a request
arriving on port 8080 to any of them. Build lesson 5's project, start it, and ask it for the books:

```
(pending lesson5-404)
```

A 404, with a small JSON body that Spring Boot writes for any path nobody handles. This lesson writes
the code that handles `/books`.

## The minimum of HTTP this lesson needs

A request is a method, a path, some headers and sometimes a body. `GET` asks for
something and `POST` sends something to be created. The answer is a **status code**, headers and a
body. These are the codes this lesson meets:

| code | meaning | where you meet it |
|---|---|---|
| 200 | here it is | a book that exists |
| 201 | created | a new book, in the section on POST |
| 400 | the request is wrong | bad JSON, or a value that breaks a rule |
| 404 | nothing here | a book that does not exist, a path nobody handles |
| 405 | the path exists, but not for this method | `DELETE` on a book |
| 415 | a body in a format this endpoint does not read | a POST without its `Content-Type` |

If you came through the `backend` track, `web-fundamentals` lesson 6 covered methods, headers and
status codes, and `apis` lesson 1 takes status codes and the design of an API much further.

## A class that is called, not a loop that reads

The common picture of a web framework is code that reads the request: take the bytes off the socket,
parse the first line, look at the path, branch to the right function. **Spring MVC turns that
around.** You write a class whose methods are labelled with the requests they answer, and the
framework does the reading and calls them. Nothing in the controller below touches a socket, a header
or a byte of JSON.

First the record the API answers with. Create
`src/main/java/com/example/bookshop/catalogue/BookResponse.java`:

```java
package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.id(), book.isbn(), book.title(), book.author(), book.priceCents());
    }
}
```

It is what the API says about a book, built from a `Book` by `from`. Today it has the same five
components as `Book`, and the section on DTOs argues why it is a second record anyway.

Then the **controller**, beside it in `BookController.java`. This version answers the two `GET`
requests; the section on POST adds a third method.

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\n\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "Everything imported here comes from `spring-web`, which the web starter has brought in since lesson 4."
    },
    {
      "code": "@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "`@RestController` makes the class a bean, found by the component scan of lesson 5, and says that what its methods return is the body of the response. `@RequestMapping` on the class puts `/books` in front of every path below it."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n",
      "note": "Constructor injection, as in lesson 5: the controller asks for the service and never builds one."
    },
    {
      "code": "    @GetMapping\n    public List<BookResponse> list() {\n        return books.list().stream().map(BookResponse::from).toList();\n    }\n",
      "note": "`@GetMapping` with no path of its own answers `GET /books`. The method returns a list of records and never mentions JSON; the next section shows who writes it."
    },
    {
      "code": "    @GetMapping(\"/{id}\")\n    public ResponseEntity<BookResponse> get(@PathVariable long id) {\n        return books.find(id)\n                .map(BookResponse::from)\n                .map(ResponseEntity::ok)\n                .orElse(ResponseEntity.notFound().build());\n    }",
      "note": "`{id}` is a template variable, and `@PathVariable` hands its value to the parameter of the same name, converted to `long`. `ResponseEntity` lets the method choose the status as well as the body: `ok` is 200 with the book, `notFound().build()` is 404 with no body at all."
    },
    {
      "code": "}"
    }
  ]
}
```

## Build it, run it, ask it

`-q` tells Maven to print only warnings and errors, so a build that prints nothing has worked:

```
(pending build)
```

Start the application in a **second terminal** and leave it running there. Every change to the code
from now on means stopping it with Ctrl+C, building again and starting it again.

```sh
java -jar target/bookshop-0.1.0.jar
```

Back in the first terminal, **curl** is the client. It sends one request and prints the answer:

```
(pending get-one)
```

Three flags, used throughout this lesson. `-i` prints the status line and the headers before the
body. `-s` keeps curl from printing anything of its own, such as a progress meter. `-w '\n'` writes a
newline after the answer, because JSON does not end with one and the next prompt would otherwise start
on the same line.

Read the first answer from the top. `HTTP/1.1 200` is the status; Tomcat sends the number with no
reason phrase after it, where other servers write `200 OK`. `Content-Type: application/json` says the
body is JSON, a choice Spring made without being told. The body is the `BookResponse` for book 1.

Book 99 is a 404 with `Content-Length: 0`: the controller found an empty `Optional` and returned
`notFound().build()`, which is a status and no body.

Without `-i`, curl prints only the body. The whole list is a JSON array, on one line:

```
(pending list)
```

## Answers you did not write

```
(pending not-mapped)
```

`DELETE /books/1` gets **405** and a header, `Allow: GET`. Spring knows that `/books/{id}` exists and
which methods it answers, and says so. `/authors` gets a 404, like book 99, but this one has a body:
nothing is mapped to that path, so the request ended in Spring Boot's own error handling, which writes
`timestamp`, `status`, `error` and `path`.

A path variable that cannot become a `long` is refused before the method runs:

```
(pending path-abc)
```

The second terminal says why, in a line the application logged at `WARN`:

```
(pending path-abc-log)
```

So there are already two kinds of error answer: the ones your controller decides, like the empty 404
for book 99, and the ones Spring decides, with Spring Boot's body. Lesson 7 puts both into one shape
that tells a client what went wrong. The next section shows where Spring's ones come from.
