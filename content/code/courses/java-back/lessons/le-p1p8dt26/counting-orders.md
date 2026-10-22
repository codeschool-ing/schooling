---
title: A counter of your own
version: 1
---

Every metric so far describes machinery: requests, connections, memory. None of them knows what a
bookshop is. A `409` in `http.server.requests` could be an order for a book that ran out, or any
other conflict a later lesson adds; the timer cannot tell, because the reason is in the code. When the
question is about the business, **the code has to count it**, and the place to count is where the
decision is made.

The bookshop counts orders, with one tag for how each attempt ended: `placed` or `out-of-stock`.
Replace `src/main/java/com/example/bookshop/ordering/OrderService.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderService.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.temporal.ChronoUnit;\n"
    },
    {
      "code": "import io.micrometer.core.instrument.Counter;\nimport io.micrometer.core.instrument.MeterRegistry;\n",
      "note": "New: Micrometer's own API. Nothing in this file names Prometheus, so another backend would need no change here."
    },
    {
      "code": "import org.slf4j.Logger;\nimport org.slf4j.LoggerFactory;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private static final Logger log = LoggerFactory.getLogger(OrderService.class);\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;"
    },
    {
      "code": "    private final Counter placed;\n    private final Counter refused;\n",
      "note": "Two counters, held in fields so that recording costs one method call."
    },
    {
      "code": "    public OrderService(BookRepository books, OrderRepository orders, Clock clock, MeterRegistry meters) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;",
      "note": "The registry is a bean like any other, and arrives through the constructor (lesson 5)."
    },
    {
      "code": "        this.placed = meters.counter(\"bookshop.orders\", \"outcome\", \"placed\");\n        this.refused = meters.counter(\"bookshop.orders\", \"outcome\", \"out-of-stock\");\n    }",
      "note": "One name, `bookshop.orders`, and a tag `outcome` with two values: two series of one family. Asking the registry again for the same name and tags returns the same counter."
    },
    {
      "code": "\n    @Transactional\n    public OrderResponse place(String customer, OrderRequest request) {\n        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));"
    },
    {
      "code": "            if (book.getStock() < line.quantity()) {\n                refused.increment();\n            }",
      "note": "A line that asks for more than the stock counts as a refusal. `take` throws on the next line and the transaction rolls back, but the counter has already moved, and it does not roll back: a refusal is exactly what it is there to count."
    },
    {
      "code": "            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }"
    },
    {
      "code": "        Order saved = orders.save(order);\n        placed.increment();",
      "note": "Counted after the order is saved. The commit happens when the method returns, so in the rare case where the commit itself fails, this counter is one ahead."
    },
    {
      "code": "        log.info(\"Order {} placed by {}: {} line(s), {} cents\",\n                saved.getId(), customer, saved.getLines().size(), saved.totalCents());\n        return OrderResponse.from(saved);\n    }\n\n    @Transactional(readOnly = true)\n    public OrderResponse get(long id, String customer) {\n        return orders.findWithLinesById(id)\n                .filter(order -> order.getCustomer().equals(customer))\n                .map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"
    }
  ]
}
```

The constructor changed, so the unit test of lesson 19 no longer compiles. It needs a registry, and
Micrometer ships one that keeps everything in memory and reports nowhere, which is exactly what a
test wants. Replace `src/test/java/com/example/bookshop/ordering/OrderServiceTest.java`:

```java
package com.example.bookshop.ordering;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import com.example.bookshop.catalogue.Author;
import com.example.bookshop.catalogue.Book;
import com.example.bookshop.catalogue.BookRepository;
import com.example.bookshop.catalogue.OutOfStockException;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    BookRepository books;

    @Mock
    OrderRepository orders;

    OrderService service;

    Book frankenstein = new Book("9786500000030", "Frankenstein", new Author("Mary Shelley"), 3500, 1);

    @BeforeEach
    void setUp() {
        Clock noon = Clock.fixed(Instant.parse("2026-10-16T15:00:00Z"), ZoneOffset.UTC);
        service = new OrderService(books, orders, noon, new SimpleMeterRegistry());
        ReflectionTestUtils.setField(frankenstein, "id", 3L);
    }

    @Test
    void placingAnOrderTakesTheStockAndSavesTheOrder() {
        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));
        when(orders.save(any(Order.class))).thenAnswer(call -> {
            Order order = call.getArgument(0);
            ReflectionTestUtils.setField(order, "id", 7L);
            return order;
        });

        OrderResponse placed = service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 1))));

        assertThat(placed.id()).isEqualTo(7);
        assertThat(placed.totalCents()).isEqualTo(3500);
        assertThat(placed.placedAt()).isEqualTo(Instant.parse("2026-10-16T15:00:00Z"));
        assertThat(frankenstein.getStock()).isZero();
    }

    @Test
    void anOrderForMoreThanTheStockIsNeverSaved() {
        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));

        assertThatThrownBy(() -> service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))
                .isInstanceOf(OutOfStockException.class);

        verify(orders, never()).save(any());
    }
}
```

And replace `src/test/resources/application-test.properties`:

```properties
bookshop.jwt.secret=a-secret-for-tests-only-at-least-32-bytes
management.server.port=0
```

Its new line matters for the integration tests of lessons 19 to 21. They start the whole application,
management server included, and port `0` asks the operating system for any free one. Without it, a
test run would fail while a bookshop is already running on 8081 in another terminal.

## Counting real orders

Build and restart, then place four orders as ana: the last copy of Frankenstein, the same book again,
an order of two lines, and a book that does not exist.

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"lines":[{"bookId":3,"quantity":1}]}' localhost:8080/orders
201
ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"lines":[{"bookId":3,"quantity":1}]}' localhost:8080/orders
{"detail":"Only 0 of 'Frankenstein' left, 1 wanted","instance":"/orders","status":409,"title":"Out of stock","type":"https://bookshop.example/problems/out-of-stock"}
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"lines":[{"bookId":1,"quantity":2},{"bookId":2,"quantity":1}]}' localhost:8080/orders
201
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"lines":[{"bookId":99,"quantity":1}]}' localhost:8080/orders
404
```

Two orders were placed, one was refused for lack of stock, and one asked for book 99. The counter
agrees:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/metrics/bookshop.orders | python3 -m json.tool
{
    "availableTags": [
        {
            "tag": "outcome",
            "values": [
                "out-of-stock",
                "placed"
            ]
        }
    ],
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 3.0
        }
    ],
    "name": "bookshop.orders"
}
```

`COUNT` is the sum over both series. The tag picks one:

```
ana@vm:~/bookshop$ curl -s "localhost:8081/actuator/metrics/bookshop.orders?tag=outcome:out-of-stock" | python3 -m json.tool | tail -n 8
    "measurements": [
        {
            "statistic": "COUNT",
            "value": 1.0
        }
    ],
    "name": "bookshop.orders"
}
```

The `404` is in neither series. That was a decision, made when the code put the increments where it
did: an order for a book that does not exist is a client's mistake, while an order refused for lack of
stock is a sale the shop could have made. If somebody wants the first kind counted as well, it is a
third value of the same tag, not a new meter.

## What a tag may hold

A tag's values have to be few and known in advance. `outcome` has two. Tagging each order with the
customer instead, `meters.counter("bookshop.orders", "customer", customer)`, would look harmless with
two users. It would also create a new series for every customer the shop ever has: memory in the
registry, a row in every system that stores the numbers, and an account name copied into a monitoring
system that keeps it for months. That last cost is lesson 16's rule about personal data, applied to
numbers. A question about
one customer belongs in the database; a metric answers questions about all of them
at once.
