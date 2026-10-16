---
title: stub
version: 1
---

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
