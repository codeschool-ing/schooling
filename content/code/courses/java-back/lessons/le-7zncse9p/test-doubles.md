---
title: Test doubles, and a mock for each repository
version: 1
---

Lesson 18 tested `Order` and `Book`, which are plain objects: build one, call a method, check the
answer. `OrderService` is not like that. Placing an order locks a row in PostgreSQL, takes stock from
an entity Hibernate loaded and saves a new order through Spring Data. **The common picture is that
testing it therefore needs the database.** It needs the database only to test the database. The
service's own decisions — which book to take stock from, when to refuse, what the order adds up to
— can be checked with stand-ins for the repositories, in a test that runs in about a second.

## A double stands in for a collaborator

A **test double** is any object a test puts where the real collaborator would be, the way a stunt
double stands in for an actor. The vocabulary has five words, from Gerard Meszaros's *xUnit Test
Patterns*, and `testing-cicd` lesson 2 gives each its own example. In brief:

| double | what it does |
| --- | --- |
| dummy | fills a parameter and is never used |
| stub | returns answers the test chose in advance |
| fake | a working, simpler implementation, such as a repository over a `HashMap` |
| spy | a real object that also records how it was called |
| mock | is told what to expect, or asked afterwards what happened to it |

Lesson 5 already wrote a fake without using the word: `InMemoryBookRepository` kept three books in a
map, and lesson 9 replaced it with the JDBC one. Writing a fake of today's `BookRepository` would be
another matter, because since lesson 11 it extends `JpaRepository`, and a fake would have to
implement dozens of inherited methods so that a test could use two.

**Mockito** removes that cost. Given an interface or a class, it makes an object that implements
every method and answers each with an empty value — `null`, `0`, `false`, an empty list, an empty
`Optional` — until the test says otherwise. What Mockito calls a mock can play a stub (`when`) and a
mock in Meszaros's sense (`verify`) in the same test, which is why most Java code says "mock" for
both.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"Two panels. In the running application, OrderService calls BookRepository and OrderRepository, both Spring Data proxies that send SQL to PostgreSQL, and a Clock that reads the system clock. In OrderServiceTest, the same OrderService calls two Mockito mocks, one answering as it was stubbed and one recording every call, and a fixed clock; there is no database and no network.\"><defs><marker id=\"f19a-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19a-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"360\" height=\"310\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">in the running application</text><rect x=\"25\" y=\"48\" width=\"160\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">OrderService</text><line x1=\"45\" y1=\"86\" x2=\"45\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"45\" y1=\"126\" x2=\"58\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><line x1=\"185\" y1=\"126\" x2=\"208\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"108\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock.system(...)</text><text x=\"284.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the real time</text><line x1=\"45\" y1=\"181\" x2=\"58\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"163\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRepository</text><line x1=\"185\" y1=\"181\" x2=\"208\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"163\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Spring Data proxy</text><text x=\"284.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sends SQL</text><line x1=\"45\" y1=\"236\" x2=\"58\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"218\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">OrderRepository</text><line x1=\"185\" y1=\"236\" x2=\"208\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"218\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Spring Data proxy</text><text x=\"284.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sends SQL</text><line x1=\"284\" y1=\"254\" x2=\"284\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><path d=\"M 358 181 L 366 181 L 366 288\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><line x1=\"366\" y1=\"288\" x2=\"360\" y2=\"288\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"270\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"284.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">another process</text><rect x=\"390\" y=\"10\" width=\"360\" height=\"310\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">in OrderServiceTest</text><rect x=\"405\" y=\"48\" width=\"160\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">OrderService</text><line x1=\"425\" y1=\"86\" x2=\"425\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"425\" y1=\"126\" x2=\"438\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><line x1=\"565\" y1=\"126\" x2=\"588\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"108\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock.fixed(...)</text><text x=\"664.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">always 15:00 UTC</text><line x1=\"425\" y1=\"181\" x2=\"438\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"163\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRepository</text><line x1=\"565\" y1=\"181\" x2=\"588\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"163\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mock</text><text x=\"664.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answers as stubbed</text><line x1=\"425\" y1=\"236\" x2=\"438\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"218\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">OrderRepository</text><line x1=\"565\" y1=\"236\" x2=\"588\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"218\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mock</text><text x=\"664.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">records every call</text><text x=\"664\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no database, no network</text></svg>", "caption": "The service is the same class in both panels. What changes is what it reaches when it calls out."}
```

## The test

Create `src/test/java/com/example/bookshop/ordering/OrderServiceTest.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderServiceTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport static org.assertj.core.api.Assertions.assertThat;\nimport static org.assertj.core.api.Assertions.assertThatThrownBy;\nimport static org.mockito.ArgumentMatchers.any;\nimport static org.mockito.Mockito.never;\nimport static org.mockito.Mockito.verify;\nimport static org.mockito.Mockito.when;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.time.ZoneOffset;\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.junit.jupiter.api.extension.ExtendWith;\nimport org.mockito.Mock;\nimport org.mockito.junit.jupiter.MockitoExtension;\nimport org.springframework.test.util.ReflectionTestUtils;\n\nimport com.example.bookshop.catalogue.Author;\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookRepository;\nimport com.example.bookshop.catalogue.OutOfStockException;\n",
      "note": "The static imports are the test's vocabulary. `when`, `verify`, `never` and `any` are Mockito's; `assertThat` and `assertThatThrownBy` are AssertJ's, as in lesson 18. `spring-boot-starter-test` already brings Mockito, so the pom does not change for this file."
    },
    {
      "code": "@ExtendWith(MockitoExtension.class)\nclass OrderServiceTest {\n\n    @Mock\n    BookRepository books;\n\n    @Mock\n    OrderRepository orders;\n",
      "note": "**`MockitoExtension`** creates a fresh mock for every `@Mock` field before each test. A mock of `BookRepository` implements the whole interface and answers every call with an empty value until the test says otherwise."
    },
    {
      "code": "    OrderService service;\n\n    Book frankenstein = new Book(\"9786500000030\", \"Frankenstein\", new Author(\"Mary Shelley\"), 3500, 1);\n",
      "note": "The service is the real class, the one under test. The book is a real entity too, built with its public constructor: one copy of *Frankenstein* at 3500 cents. Nothing here needs a double, because neither touches anything outside the JVM."
    },
    {
      "code": "    @BeforeEach\n    void setUp() {\n        Clock noon = Clock.fixed(Instant.parse(\"2026-10-16T15:00:00Z\"), ZoneOffset.UTC);\n        service = new OrderService(books, orders, noon);\n        ReflectionTestUtils.setField(frankenstein, \"id\", 3L);\n    }\n",
      "note": "The service gets its three collaborators through the constructor, as lesson 5 arranged. The clock is fixed at 15:00 UTC, noon in São Paulo, so the time an order is placed is a value the test can assert. `ReflectionTestUtils` gives the book the id the database would have generated."
    },
    {
      "code": "    @Test\n    void placingAnOrderTakesTheStockAndSavesTheOrder() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));",
      "note": "A **stub**: when the service asks for book 3 with a lock, the mock returns the entity above. Any other id still gets the default, an empty `Optional`."
    },
    {
      "code": "        when(orders.save(any(Order.class))).thenAnswer(call -> {\n            Order order = call.getArgument(0);\n            ReflectionTestUtils.setField(order, \"id\", 7L);\n            return order;\n        });\n",
      "note": "`thenAnswer` runs code at the moment of the call. The order is created inside `place`, so the test cannot name it in advance; the answer takes it from the call's arguments, gives it id 7 and hands it back, which is what `save` does for real."
    },
    {
      "code": "        OrderResponse placed = service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 1))));\n\n        assertThat(placed.id()).isEqualTo(7);\n        assertThat(placed.totalCents()).isEqualTo(3500);\n        assertThat(placed.placedAt()).isEqualTo(Instant.parse(\"2026-10-16T15:00:00Z\"));\n        assertThat(frankenstein.getStock()).isZero();\n    }\n",
      "note": "The call under test, then what it should have produced: the id that `save` gave, the total, the fixed instant, and the stock the order took from the book."
    },
    {
      "code": "    @Test\n    void anOrderForMoreThanTheStockIsNeverSaved() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));\n",
      "note": "The second test stubs the same lookup and asks for two copies of a book that has one."
    },
    {
      "code": "        assertThatThrownBy(() -> service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))\n                .isInstanceOf(OutOfStockException.class);\n",
      "note": "`Book.take` throws, and the exception leaves `place` before the order reaches `save`."
    },
    {
      "code": "        verify(orders, never()).save(any());\n    }\n}",
      "note": "**`verify`** asks the mock what happened to it. `never()` turns the question into a claim: `save` was not called, with any argument. That is the one thing a stub cannot check, because a stub only answers."
    }
  ]
}
```

Run the tests. Maven prints a screen of `[INFO]` lines before the tests start, and `sed` keeps the
part from the tests' banner to the end. `2>&1` sends what the test JVM writes to its error stream
through `sed` as well, so that every line arrives in the order it was printed:

```
ana@vm:~/bookshop$ mvn test 2>&1 | sed -n '/T E S T S/,$p'
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.080 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.ordering.OrderServiceTest
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build as described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/ana/.m2/repository/net/bytebuddy/byte-buddy-agent/1.18.11/byte-buddy-agent-1.18.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
20:17:46.906 [main] INFO com.example.bookshop.ordering.OrderService -- Order 7 placed by ana: 1 line(s), 3500 cents
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.754 s -- in com.example.bookshop.ordering.OrderServiceTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.017 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.020 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.093 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.941 s
[INFO] Finished at: 2026-10-22T20:17:47-03:00
[INFO] ------------------------------------------------------------------------
```

Seventeen tests pass, the two new ones among them. Two things in this output are not test results.
The line from `OrderService` is the log line lesson 16 added, written here by Logback's default
console pattern because no Spring context is running. The other is the block of warnings in the
middle, which the next section reads line by line.

## What a mock answers when nobody told it

**A mock that was not told what to return does not fail. It returns the empty value.** Take the
stubbing out of the second test to see what that means for `findByIdForUpdate`, whose return type is
`Optional<Book>`. The first command deletes the line after the method's name and prints the method;
the second runs only this class, `-Dtest=OrderServiceTest`, and keeps the failure. **`-B`** is
Maven's batch mode, and it matters whenever Maven's output goes through `grep` or `sed`: without it
Maven colours its lines even into a pipe, and the colour codes sit between the characters a pattern
looks for.

```
ana@vm:~/bookshop$ sed -i '/void anOrderForMoreThanTheStockIsNeverSaved/{n;d}' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java && sed -n '/void anOrderForMoreThanTheStockIsNeverSaved/,/^    }/p' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java
    void anOrderForMoreThanTheStockIsNeverSaved() {

        assertThatThrownBy(() -> service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))
                .isInstanceOf(OutOfStockException.class);

        verify(orders, never()).save(any());
    }
ana@vm:~/bookshop$ mvn -B test -Dtest=OrderServiceTest 2>&1 | sed -n '/<<< FAILURE!$/,/BookNotFoundException/p'
[ERROR] com.example.bookshop.ordering.OrderServiceTest.anOrderForMoreThanTheStockIsNeverSaved -- Time elapsed: 0.012 s <<< FAILURE!
java.lang.AssertionError: 

Expecting actual throwable to be an instance of:
  com.example.bookshop.catalogue.OutOfStockException
but was:
  com.example.bookshop.catalogue.BookNotFoundException: No book has id 3
```

The test still expected `OutOfStockException` and got `BookNotFoundException`. With no stubbing the
mock returned an empty `Optional`, and the service's `orElseThrow` did exactly what it does for a book
that does not exist. A test that forgets a stubbing exercises a different path from the one its name
describes, and here an assertion caught it because the assertion named the exception.

Put the line back. Then change the id in the first test's stubbing from `3L` to `4L`, so the mock
is prepared for a call that never comes:

```
ana@vm:~/bookshop$ sed -i '0,/findByIdForUpdate(3L)/s//findByIdForUpdate(4L)/' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java && grep -n 'findByIdForUpdate' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java
50:        when(books.findByIdForUpdate(4L)).thenReturn(Optional.of(frankenstein));
67:        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));
ana@vm:~/bookshop$ mvn -B test -Dtest=OrderServiceTest 2>&1 | grep -m 1 -A 6 'Strict stubbing'
Strict stubbing argument mismatch. Please check:
 - this invocation of 'findByIdForUpdate' method:
    books.findByIdForUpdate(3L);
    -> at com.example.bookshop.ordering.OrderService.place(OrderService.java:34)
 - has following stubbing(s) with different arguments:
    1. books.findByIdForUpdate(4L); stubbed with: [Returns: Optional[com.example.bookshop.catalogue.Book@680a66dd]]
      -> at com.example.bookshop.ordering.OrderServiceTest.placingAnOrderTakesTheStockAndSavesTheOrder(OrderServiceTest.java:50)
```

This time Mockito itself refused, before any assertion ran. **`MockitoExtension` runs with strict
stubs**: a stubbing whose arguments do not match the call the code made is a `PotentialStubbingProblem`,
and the message names both lines, instead of letting the call fall through to an empty answer. A stubbing that is never used at
all fails the test too, with `UnnecessaryStubbingException`. Both rules push a test towards stubbing
exactly what the code under test calls. Put `3L` back before going on.
