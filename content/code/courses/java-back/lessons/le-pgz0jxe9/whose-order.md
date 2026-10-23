---
title: An order belongs to the token that placed it
version: 1
---

In lesson 14 an order named its customer in the request body. Anybody could place an order in
anybody's name, and anybody could read any order by counting up its id. The scope rule now keeps out
whoever has no token with `orders` in it, but ana and the clerk both have one. A URL rule cannot
tell their orders apart: it sees a path and a list of authorities, not who owns row 1. That check
belongs to the data, so it goes in the code that reads the data.

The customer now comes from the one place the client cannot write: the **subject** of a token the
server signed. Replace `src/main/java/com/example/bookshop/ordering/OrderRequest.java`; the
`customer` component is gone:

```java
package com.example.bookshop.ordering;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record OrderRequest(@NotEmpty List<@Valid Line> lines) {

    public record Line(@NotNull Long bookId, @Positive int quantity) {
    }
}
```

Replace `src/main/java/com/example/bookshop/ordering/OrderController.java`.
`@AuthenticationPrincipal Jwt jwt` asks Spring for the token the bearer filter has already checked,
as an object, and `getSubject()` reads its `sub` claim:

```java
package com.example.bookshop.ordering;

import java.net.URI;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService orders;

    public OrderController(OrderService orders) {
        this.orders = orders;
    }

    @PostMapping
    public ResponseEntity<OrderResponse> place(@AuthenticationPrincipal Jwt jwt,
                                               @Valid @RequestBody OrderRequest request) {
        OrderResponse order = orders.place(jwt.getSubject(), request);
        return ResponseEntity.created(URI.create("/orders/" + order.id())).body(order);
    }

    @GetMapping("/{id}")
    public OrderResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable long id) {
        return orders.get(id, jwt.getSubject());
    }
}
```

And replace `src/main/java/com/example/bookshop/ordering/OrderService.java`. `place` takes the
customer as a parameter, and `get` keeps an order only if it belongs to the customer asking:

```java
package com.example.bookshop.ordering;

import java.time.Clock;
import java.time.temporal.ChronoUnit;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.bookshop.catalogue.Book;
import com.example.bookshop.catalogue.BookNotFoundException;
import com.example.bookshop.catalogue.BookRepository;

@Service
public class OrderService {

    private final BookRepository books;
    private final OrderRepository orders;
    private final Clock clock;

    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {
        this.books = books;
        this.orders = orders;
        this.clock = clock;
    }

    @Transactional
    public OrderResponse place(String customer, OrderRequest request) {
        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));
        for (OrderRequest.Line line : request.lines()) {
            Book book = books.findByIdForUpdate(line.bookId())
                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));
            book.take(line.quantity());
            order.add(book, line.quantity());
        }
        return OrderResponse.from(orders.save(order));
    }

    @Transactional(readOnly = true)
    public OrderResponse get(long id, String customer) {
        return orders.findWithLinesById(id)
                .filter(order -> order.getCustomer().equals(customer))
                .map(OrderResponse::from)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }
}
```

With the application running and the two token files from the previous sections, ana places an order,
then places another and tries to name the clerk as its customer; then the clerk asks for ana's order,
and for one that does not exist:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"lines":[{"bookId":1,"quantity":1}]}' localhost:8080/orders
{"id":1,"customer":"ana","placedAt":"2026-10-22T22:48:31Z","lines":[{"bookId":1,"title":"Dom Casmurro","quantity":1,"priceCents":3990}],"totalCents":3990}
ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"customer":"clerk","lines":[{"bookId":2,"quantity":1}]}' localhost:8080/orders
{"id":2,"customer":"ana","placedAt":"2026-10-22T22:48:31Z","lines":[{"bookId":2,"title":"The Time Machine","quantity":1,"priceCents":2950}],"totalCents":2950}
ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat clerk.token)" localhost:8080/orders/1
{"detail":"No order has id 1","instance":"/orders/1","status":404,"title":"Order not found","type":"https://bookshop.example/problems/order-not-found"}
ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat clerk.token)" localhost:8080/orders/99
{"detail":"No order has id 99","instance":"/orders/99","status":404,"title":"Order not found","type":"https://bookshop.example/problems/order-not-found"}
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" localhost:8080/orders/1
200
```

Both orders are ana's. The second request's `customer` is a property `OrderRequest` no longer has,
and Spring Boot's Jackson ignores what a record lacks, so the field a client could forge no longer
exists. The clerk's token has `SCOPE_orders`, so the clerk gets past the door, and is then told that
order 1 does not exist, word for word what the clerk is told about order 99. Ana still reads it.

**The answer is 404 and not 403, on purpose.** A 403 would confirm that the order exists, and the ids
count up from 1, so anybody with a token could learn how many orders the shop has taken and which
ids are live. A 404 says nothing about other people's data. The check is in the service, next to
the query, because that is the only place that knows whose row it is.
