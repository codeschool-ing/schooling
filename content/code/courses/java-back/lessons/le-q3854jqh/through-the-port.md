---
title: Testing through the port
version: 1
---

Lesson 19 left the bookshop with three kinds of test. `OrderServiceTest` runs the service with
Mockito standing in for the repositories, `BookRepositoryIT` runs the repository against PostgreSQL
in a container, and `BookshopApplicationIT` starts the whole application context against the same
kind of container. **None of them sends an HTTP request.** So nothing has yet checked that
`GET /books/1` answers 200 with JSON, that a book nobody has comes back as the problem detail of
lesson 7, or that `POST /books` without a token is refused with the 401 of lesson 15. All of that
lives between the socket and the service, in code that no test has run.

A common first idea is to test the controller by calling it: build a `BookController`, call
`get(1)`, look at what it returns. That checks a method. It skips the mapping from the path to the
method, the conversion of `"1"` into a `long`, the security filters, Jackson, and the error handler,
which together are what a client actually meets. **An API test is a client.** It sends a request
to a running server and judges the answer by what crossed the wire: the status, the headers and the
body.

## Two ways to start the application in a test

`@SpringBootTest` starts the application context, and its `webEnvironment` attribute says whether a
server comes with it:

| `webEnvironment` | what starts | how a request reaches the controller |
|---|---|---|
| `MOCK`, the default | the context, with a mock servlet environment and no server | in the same thread, through Spring's `MockMvc`, with no socket |
| `RANDOM_PORT` | the context and the embedded Tomcat, on a free port | over a real HTTP connection |
| `DEFINED_PORT` | the same, on `server.port`, 8080 here | over a real HTTP connection, if nothing else holds 8080 |
| `NONE` | the context, without any web layer | it does not |

`BookshopApplicationIT` uses the default, which is why it could ask `BookService` for a count and
never open a connection. The test this lesson writes asks for **`RANDOM_PORT`**. A free port chosen
at start-up means the test never collides with a bookshop you left running in another terminal, or
with a second build on the same machine, which is exactly what `DEFINED_PORT` would do.

```schooling-figure
FIGURE-PORT-EN
```

`MockMvc` is faster and is a fair choice for testing a controller's mapping. This lesson uses a real
port because its question is what a client sees, and the client of an API arrives through a socket.

## REST Assured

**REST Assured** is a Java library for testing HTTP APIs: an HTTP client and a set of assertions,
written as one sentence per request. Spring Boot's parent does not manage its version, so the pom
names it, the way lesson 17 named springdoc's. Replace `pom.xml` with this one. Two lines are new:
the `rest-assured.version` property and the dependency near the end of `<dependencies>`, in the
`test` scope.

```xml
POM
```

Its dependencies are worth one look, because two of them surprise people:

```
TREE
```

REST Assured sends its requests with Apache **HttpClient** 4.5, not with the JDK's own client, and
it reads JSON and XML bodies with **Groovy**: the path you write to reach a field, such as `title`
or `lines.size()`, is Groovy's GPath. Neither ever appears in your test code. Look at the Groovy
version, too. REST Assured 6.1.0 asks for Groovy 5.0.3, and the tree shows 5.0.8, because Spring
Boot's parent manages Groovy and, as lesson 4 showed, a managed version wins over the one a library
asked for.

The test class goes where failsafe looks for integration tests, with a name ending in `IT`, as
lesson 19 arranged: `src/test/java/com/example/bookshop/BooksApiIT.java`. The next section writes
it.
