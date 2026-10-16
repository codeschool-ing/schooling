---
title: Open in view, and the exception it hides
version: 1
---

A lazy author can load itself only while the persistence context that produced it is open. Read it
after that and Hibernate does not quietly run the query anyway: it throws a
**`LazyInitializationException`**. Every Hibernate developer meets it, and the usual first reaction
is to make it go away rather than to read it.

## Making it happen

Another detour. In `BookService`, delete the `@Transactional(readOnly = true)` line above `get`, and
leave everything else as it is. Without a transaction of its own, `find` runs in a persistence
context that lives only as long as that one call, and `BookResponse.from` then reads the author of a
book that is already detached. Build, start, and ask for a book:

```
(capture lazy-curl)
```

A 500, in Spring's default shape for an exception nobody handled: lesson 7's handler covers the
bookshop's own exceptions and Spring's web errors, and this is neither. The second terminal says what
it was; these are the lines before the stack trace starts:

```
(capture lazy-log)
```

Read it as a sentence: the proxy for `Author` number 1 could not load itself because there was **no
session**, Hibernate's name for the persistence context. The book was fine. Its author was a promise
that could only be kept inside a transaction, and the transaction had never been opened.

## The setting that hides it

Now start the same build with one more argument, `--spring.jpa.open-in-view=true`, and ask again:

```
(capture osiv-curl)
```

Same code, and it works. The second terminal shows both statements, the author's included:

```
(capture osiv-log)
```

**Open session in view**, OSIV, is a Spring setting that opens a persistence context when a web
request arrives and closes it only after the response has been written. Every lazy field touched
anywhere during the request, in the service, the controller or the JSON serialisation, finds a
context open and loads itself. Spring Boot turns it on by default, and a project that never sets the
property gets this warning on every start:

```
(capture osiv-warning)
```

It is switched off in this bookshop for three reasons.

- **It hides where the queries happen.** The service stops being the place that decides what is
  loaded; any code that touches a getter can run a query, including code that only meant to
  serialise an object.
- **It can hold a database connection for the rest of the request**, including the time spent
  writing the response to a slow client. Lesson 14 counts connections, and they run out.
- **It works only for web requests.** A scheduled job or a start-up task gets no such context, so
  code that works when a controller calls it throws when anything else does.

With it off, the exception arrives early and in the right place, the first time the code is run, and
the fix is the one this bookshop already has: **the service decides what to load, inside its
transaction, and returns plain records.** Put the `@Transactional(readOnly = true)` line back above
`get`, so that `BookService.java` is again the file from the section on the entity manager.
