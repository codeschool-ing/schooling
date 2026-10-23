---
title: All or nothing, with @Transactional
version: 1
---

A **transaction** is a group of statements the database treats as one: either all of them take effect
or none of them do. Lesson 9's JDBC code never asked for one, and it did not need to, because a JDBC
connection starts in **autocommit** mode, where every statement is a transaction on its own. That is
fine for one `INSERT`. An order is three kinds of write, and autocommit would let the first ones stay
when a later one fails.

The four properties a transaction promises are called **ACID**:

| letter | property | what it means for an order |
|---|---|---|
| A | atomicity | the order, its lines and the stock change happen together or not at all |
| C | consistency | every constraint holds at commit, so `CHECK (stock >= 0)` is never broken |
| I | isolation | what one order sees of another placed at the same moment (section 05) |
| D | durability | once the commit returns, a crash does not undo it |

In SQL a transaction is `BEGIN`, the statements, and then `COMMIT` or `ROLLBACK`. In Spring nobody
writes those three words: an annotation says where a transaction begins and ends, and Spring issues
them.

## The service that places an order

Create `src/main/java/com/example/bookshop/ordering/OrderService.java`:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.temporal.ChronoUnit;\n\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n", "note": "An ordinary service: two repositories and the `Clock` bean from lesson 5, all through the constructor. Nothing in it opens a connection or says `commit`."}, {"code": "    @Transactional\n    public OrderResponse place(OrderRequest request) {\n        Order order = new Order(request.customer(), clock.instant().truncatedTo(ChronoUnit.SECONDS));", "note": "`@Transactional` puts everything `place` does, on every repository, in one database transaction. It begins before the first line runs and ends when the method returns: with a commit, or with a rollback if a `RuntimeException` comes out."}, {"code": "        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }", "note": "For each line, `findByIdForUpdate` reads the book and locks its row until the transaction ends (section 06), and `take` lowers the stock on the object. No `update` is written here: Hibernate's dirty checking from lesson 10 sends it later, at the latest at commit."}, {"code": "        return OrderResponse.from(orders.save(order));\n    }\n", "note": "Saving the order inserts it and, through the cascade, its lines. If a `take` threw, this line is never reached."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id) {\n        return orders.findWithLinesById(id).map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}", "note": "A read gets a read-only transaction. Section 04 says what `readOnly` changes."}]}
```

Build it, and start the application in a second terminal. The `grep` keeps only the lines about
the migration; without it you see the whole startup, as in earlier lessons:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'Flyway|DbMigrate|Started Bookshop'
2026-10-22T19:38:25.375-03:00  INFO 491 --- [bookshop] [           main] org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://localhost:5432/bookshop (PostgreSQL 16.15)
2026-10-22T19:38:25.520-03:00  INFO 491 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:38:25.533-03:00  INFO 491 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - stock and orders"
2026-10-22T19:38:25.576-03:00  INFO 491 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Successfully applied 1 migration to schema "public", now at version v3 (execution time 00:00.032s)
2026-10-22T19:38:28.170-03:00  INFO 491 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 6.316 seconds (process running for 6.902)
```

Flyway found the database at version 2, where lesson 13 left it, and applied `V3`. Leave the
application running and go back to the first terminal.

## An order that cannot be filled

Ask for one Dom Casmurro and two copies of Frankenstein, of which the shop has one. `-w '\n'` only adds
the line break the JSON does not end with:

```
ana@vm:~/bookshop$ curl -s -i -w '\n' -H "Content-Type: application/json" -d '{"customer":"ana","lines":[{"bookId":1,"quantity":1},{"bookId":3,"quantity":2}]}' localhost:8080/orders
HTTP/1.1 409 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:38:28 GMT

{"detail":"Only 1 of 'Frankenstein' left, 2 wanted","instance":"/orders","status":409,"title":"Out of stock","type":"https://bookshop.example/problems/out-of-stock"}
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":5}
```

The `409` is the `ApiErrorHandler` answering for `OutOfStockException`. The command that matters is
the last one: Dom Casmurro still has 5 copies. The first line of the order was handled before the
second one failed. `take(1)` ran on Dom Casmurro, and Hibernate even sent its `update` to the database,
as the log in the next section shows. The change is gone all the same, because the exception left
`place` and Spring rolled the whole transaction back. No `customer_order` row was written either.

An order the shop can fill goes through, and both stocks move:

```
ana@vm:~/bookshop$ curl -s -i -w '\n' -H "Content-Type: application/json" -d '{"customer":"ana","lines":[{"bookId":1,"quantity":1},{"bookId":2,"quantity":2}]}' localhost:8080/orders
HTTP/1.1 201 
Location: /orders/1
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:38:28 GMT

{"id":1,"customer":"ana","placedAt":"2026-10-22T22:38:28Z","lines":[{"bookId":1,"title":"Dom Casmurro","quantity":1,"priceCents":3990},{"bookId":2,"title":"The Time Machine","quantity":2,"priceCents":2950}],"totalCents":9890}
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":4}
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/2
{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950,"stock":3}
```

## What rolls back, and what does not

By default Spring rolls back when a `RuntimeException` or an `Error` leaves the method, and **commits
when a checked exception leaves it**. The rule comes from EJB, where a checked exception meant a business outcome the caller was expected
to handle rather than a failure. It surprises people who declare `throws SomeCheckedException` on a
service method and find the half-done work committed.
`OutOfStockException` extends `RuntimeException`, so it is on the right side of the rule. A method that
must roll back on a checked exception says so with
`@Transactional(rollbackFor = SomeCheckedException.class)`.

The other way to lose the rollback is to catch the exception inside the method. A `try` that catches
`OutOfStockException` in `place` and returns normally tells Spring that all went well, and it commits
whatever was done before the throw.
