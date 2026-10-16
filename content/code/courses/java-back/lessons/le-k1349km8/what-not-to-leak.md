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

@@CAP unexpected@@

No handler in `ApiErrorHandler` claims an `IllegalStateException`, so this is the 500 from this lesson's
first section, and the body is Spring Boot's: a timestamp, the status, its phrase and the path. The
message is not in it. The second terminal has all of it:

@@CAP unexpected-log@@

That split is Spring Boot's default rather than luck. Its error page has properties that decide what
goes into the body, and the bookshop leaves them at their defaults. Turning one on shows what the
default keeps out. Started with `--server.error.include-message=always`, the same request answers:

@@CAP include-message-1@@

And with `--server.error.include-stacktrace=always`, the body carries the whole stack trace, cut here to
its first lines by `head`:

@@CAP include-message-2@@

@@TRACE-SENTENCE@@ Neither property belongs in a deployed configuration, and the log already has
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

@@CAP catch-all@@

@@CATCHALL-PARAGRAPHS@@

Delete the method and put `findById` back as it was before going on.

## Why the bookshop keeps no catch-all

A catch-all can be written safely: it logs the exception with its stack trace and answers with a fixed
sentence that names nothing. Many applications have one. The bookshop does not, because "whatever
nothing more specific claims" grows as the application does. Spring Security, which arrives in lesson
15, refuses access by throwing an exception of its own and turns it into a 401 or a 403 further out,
after the controller has finished; a handler for `Exception` in the advice can catch it first and
answer 500. Spring Boot's error page already does the safe half of the job, logging everything and
saying nothing. The price is that the bookshop's 500 is the one answer not in the problem shape, which
is a price paid for an error that should not happen.

## What a detail may say

Every `detail` in the bookshop is a sentence somebody wrote for the client, built from what the client
sent. "No book has id 99" gives back the id that was asked for and nothing more. The constraint messages
were written for whoever filled in the form. And Spring's own handlers keep to the same rule: a body that
is not JSON gets "Failed to read request" @@JACKSON-CLAUSE@@

**So `e.getMessage()` goes into a response only when you wrote the exception.** A library's message is
written for the developer who will read the log, and it carries what developers need: SQL, paths, host
names, values from other rows. `apis` lesson 13 puts this beside the other ways an API tells a stranger
too much.
