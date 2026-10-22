---
title: Given, when, then
version: 1
---

A REST Assured test is written in three clauses, and the names are the library's own methods.
**`given()`** describes the request: headers, a body, credentials. **`when()`** sends it, with a
method and a path. **`then()`** states what the answer must be, and each statement after it is an
expectation that fails the test if the answer disagrees. The shape is borrowed from behaviour-driven
development, which lesson 21 meets properly; here it is only a way of reading a test from top to
bottom.

Create `src/test/java/com/example/bookshop/BooksApiIT.java` with two tests. The section after this
one adds two more.

EXAMPLE-FIRST

## Running one integration test

`mvn verify` runs every test, unit and integration. To run one integration test class, name it in
the `it.test` property, which failsafe reads. The output of a whole build is long, so `grep` keeps
the lines worth reading here:

```
RUN-FIRST
```

Read it from the top. `Tomcat started on port` names a port nobody chose: the number differs on
every run, and the test only knows it through `@LocalServerPort`. `Started BooksApiIT` is the
application starting inside the test's JVM, in the time a context and a PostgreSQL container take.
Then the two tests ran in the same class, against the same server.

`-Dit.test` narrows failsafe and nothing else. The unit tests of lessons 18 and 19 still ran
before these, under surefire, and they cost well under a second.

## A test that fails, read

A test is only worth what it says when it fails. As a detour, put a wrong expectation into the
second test: the belief that an error answer is `application/json`, like every other answer of the
bookshop.

```
RUN-DETOUR
```

**`1 expectation failed.`** is REST Assured's own report, and the line under it says exactly which
expectation and what came back instead. The server answered `application/problem+json`, as lesson 7
made it, and a client that checks the media type before parsing would have treated that answer
differently from a book. That difference is what the test exists to protect. `BooksApiIT.java:50`
is the line of the expectation, not of the request, so a failing test points at the claim that
broke.

Put the expectation back:

```
RUN-BACK
```
