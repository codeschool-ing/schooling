---
title: What an error must not say
version: 1
---

The tempting belief is that more detail in an error helps everybody: the client sees exactly what broke
and can report it. But the client of an API is a stranger, and the details of a failure inside the
server are things it can do nothing about: a database that refused a connection, a SQL statement, a
class name, a library's version. To a client acting in good faith they are noise. To somebody probing
the API they are a map of the inside, saying which database runs on which host under which user. **The
response says what the client can act on, and the log keeps everything else.**

## A failure nobody expected

The bookshop has no database until lesson 9, so this detour plants a stand-in for a failed one. In
`InMemoryBookRepository.java`, replace `findById` with this:

```java
    @Override
    public Optional<Book> findById(long id) {
        throw new IllegalStateException("connection to db-01.bookshop.example:5432 refused for user bookshop");
    }
```

Build, restart, and ask for book 1:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 -w '\n'
HTTP/1.1 500 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:22 GMT
Connection: close

{"timestamp":"2026-10-22T22:41:22.507Z","status":500,"error":"Internal Server Error","path":"/books/1"}
```

No handler in `ApiErrorHandler` claims an `IllegalStateException`, so this is the 500 from this lesson's
first section, and the body is Spring Boot's: a timestamp, the status, its phrase and the path. The
message is not in it. The second terminal has all of it:

```
2026-10-22T19:41:22.496-03:00 ERROR 6477 --- [bookshop] [nio-8080-exec-1] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop] with root cause

java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop
```

That split is Spring Boot's default rather than luck. Its error page has properties that decide what
goes into the body, each of them off by default, and the bookshop leaves them alone. Turning one on
shows what the default keeps out, and it shows a trap on the way. Answers written for Spring Boot 3 give
the property as `server.error.include-message`. Started with
`--server.error.include-message=always`, the bookshop answers exactly as before:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 -w '\n'
{"timestamp":"2026-10-22T22:41:27.227Z","status":500,"error":"Internal Server Error","path":"/books/1"}
```

**Spring Boot 4 renamed the group to `spring.web.error`**, and the old name is accepted and ignored.
Spring Boot has a module for finding exactly this, `spring-boot-properties-migrator`, which reports
renamed properties when the application starts. Started with `--spring.web.error.include-message=always`,
the same request answers:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 -w '\n'
{"timestamp":"2026-10-22T22:41:31.962Z","status":500,"error":"Internal Server Error","message":"connection to db-01.bookshop.example:5432 refused for user bookshop","path":"/books/1"}
```

And with `--spring.web.error.include-stacktrace=always`, the body gains a `trace` member: the whole
stack trace in one string, which the short Python program below prints a line at a time, stopping
after six:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 | python3 -c 'import json, sys; print(*json.load(sys.stdin)["trace"].splitlines()[:6], sep="\n")'
java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop
	at com.example.bookshop.catalogue.InMemoryBookRepository.findById(InMemoryBookRepository.java:30)
	at com.example.bookshop.catalogue.BookService.get(BookService.java:21)
	at com.example.bookshop.catalogue.BookController.get(BookController.java:33)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
```

The rest of it goes on through every Spring and Tomcat class the request passed. Package names, class
names, file names and line numbers are a description of the inside, written out for whoever asks. Neither property belongs in a deployed configuration, and the log already has
everything they add.

## The catch-all that leaks

The usual way to bring the 500 into the problem shape as well is a handler for `Exception`, the parent
of nearly everything. Written in a hurry, it looks like this. Add it to `ApiErrorHandler` above the
override, as a second detour, then build and restart:

```java
    @ExceptionHandler(Exception.class)
    public ProblemDetail unexpected(Exception e) {
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "unexpected", "Unexpected error", e.getMessage());
    }
```

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 -w '\n'
HTTP/1.1 500 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:51 GMT
Connection: close

{"detail":"connection to db-01.bookshop.example:5432 refused for user bookshop","instance":"/books/1","status":500,"title":"Unexpected error","type":"https://bookshop.example/problems/unexpected"}
ana@vm:~/bookshop$ curl -si localhost:8080/nope -w '\n'
HTTP/1.1 404 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:51 GMT

{"detail":"No static resource nope.","instance":"/nope","status":404,"title":"Not Found"}
```

Two failures in one method. The detail is the exception's own message, so the host, the port and the
database user went to the client. And the second terminal printed no error at all: the exception counted
as handled, so nothing logged it, and the one person who could fix the database was the one person not
told.

The second request shows what the catch-all did not do. `/nope` still got its 404, because Spring picks
the handler whose exception type is closest to the one thrown. `NoResourceFoundException` has a handler
of its own, and `Exception` only gets what nothing more specific claims.

Delete the method and put `findById` back as it was before going on.

## Why the bookshop keeps no catch-all

A catch-all can be written safely: it logs the exception with its stack trace and answers with a fixed
sentence that names nothing. Many applications have one. The bookshop does not, because "whatever
nothing more specific claims" grows as the application does. Spring Security, which arrives in lesson
15, refuses access by throwing an exception of its own and turns it into a 401 or a 403 further out,
after the controller has finished. A handler for `Exception` in the advice can catch it first and
answer 500. Spring Boot's error page already does the safe half of the job, logging everything and
saying nothing. The price is that the bookshop's 500 is the one answer not in the problem shape, which
is a price paid for an error that should not happen.

## What a detail may say

Every `detail` in the bookshop is a sentence somebody wrote for the client, built from what the client
sent. "No book has id 99" gives back the id that was asked for and nothing more. The constraint messages
were written for whoever filled in the form. And Spring's own handlers keep to the same rule: a body that
is not JSON gets "Failed to read request", while the `dev` log in
"Spring's own errors" showed Jackson's own words, `JSON parse error: Unexpected end-of-input
within/between Object entries`. Those words are harmless. The next library's may not be.

**So `e.getMessage()` goes into a response only when you wrote the exception.** A library's message is
written for the developer who will read the log, and it carries what developers need: SQL, paths, host
names, values from other rows. `apis` lesson 13 puts this beside the other ways an API tells a stranger
too much.
