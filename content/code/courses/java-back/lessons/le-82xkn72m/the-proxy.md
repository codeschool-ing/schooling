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
level it says what it does. Restart the application in the second terminal with that logger turned
up from the command line, and place the failing order again:

```
MISSING CAPTURE txlog
```

Each line is one decision. The proxy around `place` created a transaction, `PROPAGATION_REQUIRED` and
the database's default isolation. The two repository calls inside `place` are proxies too, and each
found a transaction already running and **joined it** instead of starting its own. When
`OutOfStockException` came out of `place`, the proxy asked for a rollback.

## Propagation: joining, or starting fresh

`PROPAGATION_REQUIRED` in that log is the default **propagation**: join the caller's transaction if
there is one, start a new one if not. It is why a repository method, which carries its own
`@Transactional` inside Spring Data, becomes part of the order instead of committing on its own.

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

This is a detour: the file is replaced, the lesson's version comes back at the end. Rebuild, restart
with the same logger, and place an order for one Dom Casmurro:

```
MISSING CAPTURE selfcall
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"OrderController calls the proxy Spring made, which begins a transaction when the method called is annotated, calls the real OrderService, and commits or rolls back. Inside OrderService, place calls placeAt directly with this, which does not pass through the proxy, so placeAt runs with no transaction.\"><defs><marker id=\"px-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"px-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderController</text><rect x=\"200\" y=\"30\" width=\"240\" height=\"150\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the proxy Spring made</text><text x=\"215\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1. begin a transaction, if the</text><text x=\"228\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">method called is @Transactional</text><text x=\"215\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. call the real method</text><text x=\"215\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3. commit, or roll back on a</text><text x=\"228\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">RuntimeException</text><rect x=\"470\" y=\"30\" width=\"210\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderService</text><rect x=\"485\" y=\"70\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">place(request)</text><rect x=\"485\" y=\"192\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Transactional placeAt(…)</text><line x1=\"165\" y1=\"105\" x2=\"198\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"440\" y1=\"89\" x2=\"483\" y2=\"89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"512\" y1=\"108\" x2=\"512\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#px-am)\"></line><text x=\"524\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">this.placeAt(…)</text><text x=\"524\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no proxy, no transaction</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The controller was given the proxy,</text><text x=\"20\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never the object itself. Only a call</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">that comes in from outside crosses it.</text></svg>", "caption": "A call through the proxy gets a transaction. A call from one method of the service to another, as in the detour below, never meets the proxy."}
```

The order came back `201`, and Dom Casmurro still has 5 copies. The log says why. The controller
called `place` through the proxy, and `place` carries no annotation, so the proxy just passed the call
on. `place` then called `placeAt` on `this`, and the annotation on `placeAt` was never read. With no
transaction around them, each repository call ran in a short transaction of its own, the one Spring
Data declares, and the `readOnly` on the lock query's transaction is that declaration's. The book was
read and its row locked and released at once, `take` changed a `Book` object nobody was watching any
more, and the order was saved in a transaction of its own. **Nothing failed, and the stock is wrong.**

There are two fixes. The annotation goes on the method the outside world calls, which is what the
lesson's `OrderService` does. Or the transactional work moves to another bean, so that the call
crosses a proxy. Put the lesson's `OrderService.java` back, from section 03, and rebuild.

## readOnly

`BookService` marks every read `@Transactional(readOnly = true)`, and `get` in `OrderService` does the
same. A read-only transaction is still a transaction, so a read that touches two tables sees them at
one moment. Spring hands the flag to Hibernate, which then skips the snapshot it keeps of every loaded
entity for dirty checking and never flushes, and to the JDBC connection, which is marked read-only. It
is cheaper, and it states the method's intent where a reader sees it.
