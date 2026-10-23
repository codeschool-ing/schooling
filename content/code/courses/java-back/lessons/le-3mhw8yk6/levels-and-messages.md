---
title: Levels, logger names and messages
version: 1
---

Every line is written at one of five **levels**, from the most talkative to the most serious: `TRACE`,
`DEBUG`, `INFO`, `WARN` and `ERROR`. Each logger has a **threshold**, and a line below its logger's
threshold is thrown away before anything else happens to it. Logback on its own let `DEBUG` through,
which is why the `Hello` run printed all four lines. Spring Boot sets the threshold of the **root
logger**, the one every other logger inherits from, to `INFO`.

Thresholds are set per logger name, and names are hierarchical at the dots: a threshold on
`com.example.bookshop` applies to `com.example.bookshop.ordering.OrderService` and to every other
logger under it, unless something more specific overrides it. In Boot a threshold is a property,
`logging.level.<name>=<level>`, which lesson 4's `dev` profile already used to turn
`org.springframework.web` up to `debug`.

## Two of this lesson's changes

This lesson changes four files of the bookshop. Replace `src/main/resources/application.properties`
with this; the last line is new, and the next section explains it:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}
bookshop.jwt.lifetime=15m

logging.pattern.correlation=[%X{requestId:-}] 
```

And replace `src/main/java/com/example/bookshop/ordering/OrderService.java`, which until now placed
an order without saying so:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.temporal.ChronoUnit;\n\nimport org.slf4j.Logger;\nimport org.slf4j.LoggerFactory;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n", "note": "`Logger` and `LoggerFactory` come from `org.slf4j`. The class depends on the facade and on no backend."}, {"code": "@Service\npublic class OrderService {\n\n    private static final Logger log = LoggerFactory.getLogger(OrderService.class);\n", "note": "One logger per class, `static final`, named after the class, so its lines read `c.e.bookshop.ordering.OrderService`."}, {"code": "    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n"}, {"code": "    @Transactional\n    public OrderResponse place(String customer, OrderRequest request) {\n        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }\n        Order saved = orders.save(order);", "note": "As in lesson 14, apart from the last line: the saved order is kept in a variable, because the log line needs its id."}, {"code": "        log.info(\"Order {} placed by {}: {} line(s), {} cents\",\n                saved.getId(), customer, saved.getLines().size(), saved.totalCents());\n        return OrderResponse.from(saved);\n    }\n", "note": "The line is written after `save`, so the id exists, and inside the transaction, just before it commits. Four values, four `{}`."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id, String customer) {\n        return orders.findWithLinesById(id)\n                .filter(order -> order.getCustomer().equals(customer))\n                .map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"}]}
```

```
ana@vm:~/bookshop$ mvn -q package
```

## The bookshop's log, read

From here on the application runs in a **second terminal**, with what it prints sent to a file so
that the first terminal can search it. This is close to how a server runs: the application writes to
standard output and something else collects it. Remember that `BOOKSHOP_JWT_SECRET` has to be
exported in this terminal too, as lesson 15 did:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar > app.log
```

The second terminal shows nothing now; it all goes to `app.log`. In the first terminal:

```
ana@vm:~/bookshop$ grep -E 'Starting Bookshop|Started|Catalogue' app.log
2026-10-22T19:30:41.658-03:00  INFO 18927 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 18927 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:30:46.856-03:00  INFO 18927 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.588 seconds (process running for 6.085)
2026-10-22T19:30:46.921-03:00  INFO 18927 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

This is Boot's pattern for Logback, and each field has a place:

| field | what it is |
|---|---|
| the first one | the time, to the millisecond, with its offset from UTC |
| `INFO` | the level |
| the number after it | the process id |
| `[bookshop]` | `spring.application.name` |
| `[           main]` | the thread, padded or cut to 15 characters |
| `[]` | the correlation slot that `logging.pattern.correlation` added, empty here |
| `c.example.bookshop.BookshopApplication` | the logger's name, its packages shortened to fit 40 characters |
| after the colon | the message |

Stop the application with Ctrl+C in the second terminal, and start it again with the root threshold
raised to `WARN`:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --logging.level.root=warn > app.log
```

```
ana@vm:~/bookshop$ cat app.log

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

```

The banner is not a log line, so no threshold touches it. Every line under it was `INFO`, and the
start-up wrote no warning, so nothing is left. Now one exception for the bookshop's own package:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --logging.level.root=warn --logging.level.com.example.bookshop=info > app.log
```

```
ana@vm:~/bookshop$ grep INFO app.log
2026-10-22T19:32:26.469-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 21234 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:32:26.472-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:32:30.707-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.556 seconds (process running for 4.929)
2026-10-22T19:32:30.782-03:00  INFO 21234 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

The catalogue line is back, which was expected. The other three are a lesson about names. **Spring
Boot wrote those lines, not the bookshop**, and they passed because Boot logs its start-up under the
name of the application's own class. A logger's name is whatever the caller asked for; the
convention is the caller's class, and most libraries follow it, but the name filters the lines and the
code that wrote them can be anywhere.

## What each level is for

The levels are only useful if they mean the same thing to everybody reading the log:

- `ERROR`: something failed and somebody has to act. On a server this is the level an alert watches.
- `WARN`: something unexpected that the application handled, and that would matter if it kept
  happening.
- `INFO`: the events of the business and of the application's life: started, an order placed.
- `DEBUG` and `TRACE`: detail for a developer chasing a problem, off unless somebody turns it on.

A customer who asks for two copies of a book with one left gets a 409 from the bookshop, and that is
the application working. Logging it as an `ERROR` would wake whoever is on call for an ordinary
Tuesday; `OrderService` does not log it at all, because the response already says it.

## Placeholders, and why not `+`

`OrderService` writes its line with `{}` placeholders and the values after the message:

```java
log.info("Order {} placed by {}: {} line(s), {} cents",
        saved.getId(), customer, saved.getLines().size(), saved.totalCents());
```

The tempting version joins the string itself: `log.info("Order " + saved.getId() + " placed by " +
customer ...)`. It prints the same line, and it does the work of building that string **before
`info` is even called**, whether or not the line will be written. At `INFO` that hardly matters. On
a `debug` call inside a loop over every order line, with the threshold at `INFO`, it builds and throws
away a string per iteration, calling `toString` on whatever was joined. With placeholders the
backend checks the threshold first and formats only the lines it keeps.

The arguments themselves are still evaluated, though: `log.debug("Stock {}", books.count())` runs the
query even when debug is off. For an argument that costs something, SLF4J 2 has a fluent form that
takes a supplier and calls it only when the line is kept:

```java
log.atDebug().setMessage("Stock {}").addArgument(() -> books.count()).log();
```

**An exception goes last, with no placeholder for it.** `Hello` logged
`log.error("Quantity '{}' is not a number", "two", e)`: one `{}` and two arguments, and SLF4J treats a
`Throwable` left over at the end as the line's exception and prints its stack trace. The two
common mistakes both lose that trace. `log.error("Failed: " + e)` prints only the exception's
`toString`, and `log.error("Failed: {}", e.getMessage())` prints only its message. The stack trace is
the part that says where.
