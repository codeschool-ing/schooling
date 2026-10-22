---
title: The proxy, and the call that goes around it
version: 1
---

The common picture of `@Transactional` is that the annotation changes the method: something is
compiled into `place` that begins and commits. Nothing is. `OrderService` is compiled exactly as
written. What changes is the object the controller is given. When Spring finds `@Transactional` on a
bean, it creates a **proxy**, a subclass generated at startup that wraps every call: the proxy begins
the transaction, calls the real method, and commits or rolls back. Lesson 5's container injects the
proxy wherever an `OrderService` is asked for, so the controller holds the proxy and never the object
itself.

## Watching the proxy work

`JpaTransactionManager` is the class the proxy asks to begin and end transactions, and at `debug`
level it says what it does. Restart the application in the second terminal with that logger turned up
from the command line, and the `sql` profile of lesson 10 beside it, then place the failing order again:

```
ana@vm:~/bookshop$ curl -s -i -w '\n' -H "Content-Type: application/json" -d '{"customer":"ana","lines":[{"bookId":1,"quantity":1},{"bookId":3,"quantity":2}]}' localhost:8080/orders
HTTP/1.1 409 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:38:35 GMT

{"detail":"Only 1 of 'Frankenstein' left, 2 wanted","instance":"/orders","status":409,"title":"Out of stock","type":"https://bookshop.example/problems/out-of-stock"}
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql --logging.level.org.springframework.orm.jpa.JpaTransactionManager=debug | grep -E 'Creating new|Participating|rollback|Committing|org.hibernate.SQL'
2026-10-22T19:38:34.372-03:00 DEBUG 791 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Creating new transaction with name [com.example.bookshop.catalogue.BookService.count]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT,readOnly
2026-10-22T19:38:34.380-03:00 DEBUG 791 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Participating in existing transaction
2026-10-22T19:38:34.421-03:00 DEBUG 791 --- [bookshop] [           main] org.hibernate.SQL                        : select count(*) from book b1_0
2026-10-22T19:38:34.428-03:00 DEBUG 791 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Committing JPA transaction on EntityManager [SessionImpl(920479985<open>)]
2026-10-22T19:38:35.466-03:00 DEBUG 791 --- [bookshop] [nio-8080-exec-1] o.s.orm.jpa.JpaTransactionManager        : Creating new transaction with name [com.example.bookshop.ordering.OrderService.place]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT
2026-10-22T19:38:35.490-03:00 DEBUG 791 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
2026-10-22T19:38:35.522-03:00 DEBUG 791 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,stock=?,title=? where id=?
2026-10-22T19:38:35.526-03:00 DEBUG 791 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
2026-10-22T19:38:35.527-03:00 DEBUG 791 --- [bookshop] [nio-8080-exec-1] o.s.orm.jpa.JpaTransactionManager        : Initiating transaction rollback
```

The first four lines are from startup. `CatalogueReport` calls `BookService.count`, whose proxy
creates a read-only transaction, and Spring Data's own `count()`, which carries a `@Transactional` of
its own, **joins** it instead of starting a second one.

Then the order. The proxy around `place` created a transaction, `PROPAGATION_REQUIRED` at the
database's default isolation. Inside it, Hibernate read Dom Casmurro with a locking read, then sent
the `update` that `take(1)` had made necessary, because it flushes pending changes before running a
query that could see them, and then read Frankenstein. When `OutOfStockException` came out of `place`,
the proxy asked for a rollback, and the `update` went with everything else.

## Propagation: joining, or starting fresh

`PROPAGATION_REQUIRED` in that log is the default **propagation**: join the caller's transaction if
there is one, start a new one if not. It is why Spring Data's `count()` became part of `BookService.count`'s transaction in the log above
instead of committing on its own.

The other value worth knowing is `REQUIRES_NEW`: suspend the caller's transaction, run in a new one,
and commit it whatever the caller does afterwards. It is for work that must survive the caller's
rollback, such as a row recording that an order was attempted and refused. It has a cost that section 07's pool
makes visible: the suspended transaction keeps its connection, so a `REQUIRES_NEW` call
holds two connections at once. The other propagation values exist and are rarely what anybody wants.

## A detour: the call that never meets the proxy

The proxy only sees calls that come in from outside. A call from one method of `OrderService` to
another is an ordinary Java call on `this`, and it never passes through the proxy. This is called
**self-invocation**, and it is easy to write by accident. Suppose somebody splits `place` in two, so
that a test can pass in the time, and moves the annotation to the method that does the work:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.time.temporal.ChronoUnit;\n\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n"}, {"code": "    public OrderResponse place(OrderRequest request) {\n        return placeAt(request, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n    }\n", "note": "`place` keeps the name the controller calls, works out the time and hands over. It has no annotation any more."}, {"code": "    @Transactional\n    public OrderResponse placeAt(OrderRequest request, Instant placedAt) {\n        Order order = new Order(request.customer(), placedAt);\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }\n        return OrderResponse.from(orders.save(order));\n    }\n", "note": "The work moved here, annotation and all. The body is the lesson's `place`, with the time passed in. Called from outside, this method would get its transaction."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id) {\n        return orders.findWithLinesById(id).map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"}]}
```

This is a detour: the file is replaced, and the lesson's version comes back at the end. Rebuild,
restart with the transaction logger, and order one Dom Casmurro:

```
ana@vm:~/bookshop$ curl -s -i -w '\n' -H "Content-Type: application/json" -d '{"customer":"ana","lines":[{"bookId":1,"quantity":1}]}' localhost:8080/orders
HTTP/1.1 500 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:38:46 GMT
Connection: close

{"timestamp":"2026-10-22T22:38:46.113Z","status":500,"error":"Internal Server Error","path":"/orders"}
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":4}
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --logging.level.org.springframework.orm.jpa.JpaTransactionManager=debug | grep -E 'Creating new|Participating|rollback|Committing|TransactionRequired'
2026-10-22T19:38:45.050-03:00 DEBUG 1191 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Creating new transaction with name [com.example.bookshop.catalogue.BookService.count]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT,readOnly
2026-10-22T19:38:45.059-03:00 DEBUG 1191 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Participating in existing transaction
2026-10-22T19:38:45.120-03:00 DEBUG 1191 --- [bookshop] [           main] o.s.orm.jpa.JpaTransactionManager        : Committing JPA transaction on EntityManager [SessionImpl(1169310916<open>)]
jakarta.persistence.TransactionRequiredException: No active transaction
2026-10-22T19:38:46.149-03:00 DEBUG 1191 --- [bookshop] [nio-8080-exec-2] o.s.orm.jpa.JpaTransactionManager        : Creating new transaction with name [com.example.bookshop.catalogue.BookService.get]: PROPAGATION_REQUIRED,ISOLATION_DEFAULT,readOnly
2026-10-22T19:38:46.151-03:00 DEBUG 1191 --- [bookshop] [nio-8080-exec-2] o.s.orm.jpa.JpaTransactionManager        : Participating in existing transaction
2026-10-22T19:38:46.179-03:00 DEBUG 1191 --- [bookshop] [nio-8080-exec-2] o.s.orm.jpa.JpaTransactionManager        : Committing JPA transaction on EntityManager [SessionImpl(1353071283<open>)]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"OrderController calls the proxy Spring made, which begins a transaction when the method called is annotated, calls the real OrderService, and commits or rolls back. Inside OrderService, place calls placeAt directly with this, which does not pass through the proxy, so placeAt runs with no transaction.\"><defs><marker id=\"px-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"px-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderController</text><rect x=\"200\" y=\"30\" width=\"240\" height=\"150\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the proxy Spring made</text><text x=\"215\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1. begin a transaction, if the</text><text x=\"228\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">method called is @Transactional</text><text x=\"215\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. call the real method</text><text x=\"215\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3. commit, or roll back on a</text><text x=\"228\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">RuntimeException</text><rect x=\"470\" y=\"30\" width=\"210\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderService</text><rect x=\"485\" y=\"70\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">place(request)</text><rect x=\"485\" y=\"192\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Transactional placeAt(…)</text><line x1=\"165\" y1=\"105\" x2=\"198\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"440\" y1=\"89\" x2=\"483\" y2=\"89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"512\" y1=\"108\" x2=\"512\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#px-am)\"></line><text x=\"524\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">this.placeAt(…)</text><text x=\"524\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no proxy, no transaction</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The controller was given the proxy,</text><text x=\"20\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never the object itself. Only a call</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">that comes in from outside crosses it.</text></svg>", "caption": "A call through the proxy gets a transaction. A call from one method of the service to another, as in this detour, never meets the proxy."}
```

The order failed with a `500`, and Dom Casmurro still has the 4 copies it had. The log says why: there
is no `Creating new transaction` for `placeAt`, or for anything else in that request until the `curl`
that read the book. The controller called `place` through the proxy, and `place` carries no
annotation, so the proxy passed the call straight on. `place` then called `placeAt` on `this`, and the
annotation on `placeAt` was never read. So `findByIdForUpdate` ran with no transaction at all, and a
locking read refuses that: `TransactionRequiredException: No active transaction`.

**This time the mistake was loud, and only by luck.** It was loud because the first thing `placeAt`
does is a locking read, and a lock has no meaning outside a transaction. Most of what a transaction
protects gives no such signal. Spring Data's `findById` and `save` each run in a short transaction of
their own when nobody else has begun one, so without the lock the same mistake would have saved the
order, never written the stock, and answered `201`.

There are two fixes. The annotation goes on the method the outside world calls, which is what the
lesson's `OrderService` does. Or the transactional work moves to another bean, so that the call
crosses a proxy. Put the lesson's `OrderService.java` back, from section 03, and rebuild.

## readOnly

`BookService` marks every read `@Transactional(readOnly = true)`, and `get` in `OrderService` does the
same. A read-only transaction is still a transaction: the reads in it share one connection and one
persistence context, as the writes of `place` do. Spring hands the flag to Hibernate, which then skips the snapshot it keeps of every loaded
entity for dirty checking and never flushes, and to the JDBC connection, which is marked read-only. It
is cheaper, and it states the method's intent where a reader sees it.
