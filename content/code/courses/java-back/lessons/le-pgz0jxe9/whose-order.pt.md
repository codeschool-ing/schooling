---
title: Um pedido pertence ao token que o fez
version: 1
---

Na aula 14 um pedido nomeava o cliente no corpo da requisição. Qualquer um podia fazer pedido em nome
de qualquer um, e qualquer um podia ler qualquer pedido contando os ids. A regra de escopo agora barra
quem não tem token com `orders`, mas a ana e o clerk têm. Uma regra de URL não distingue os pedidos
de um e de outro: ela vê um caminho e uma lista de autoridades, não quem é dono da linha 1. Essa
verificação pertence aos dados, então vai no código que lê os dados.

O cliente agora vem do único lugar que o cliente HTTP não consegue escrever: o **subject** de um token
que o servidor assinou. Substitua `src/main/java/com/example/bookshop/ordering/OrderRequest.java`; o
componente `customer` sumiu:

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

Substitua `src/main/java/com/example/bookshop/ordering/OrderController.java`. O
`@AuthenticationPrincipal Jwt jwt` pede ao Spring o token que o filtro bearer já conferiu, como objeto,
e o `getSubject()` lê o claim `sub` dele:

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

E substitua `src/main/java/com/example/bookshop/ordering/OrderService.java`. O `place` recebe o cliente
como parâmetro, e o `get` só fica com um pedido se ele for do cliente que pede:

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

Com a aplicação no ar e os dois arquivos de token das seções anteriores, a ana faz um pedido, depois
faz outro e tenta nomear o clerk como cliente; então o clerk pede o pedido da ana, e um que não existe:

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

Os dois pedidos são da ana. O `customer` da segunda requisição é uma propriedade que o `OrderRequest`
não tem mais, e o Jackson do Spring Boot ignora o que um record não tem, então o campo que um cliente
podia forjar deixou de existir. O token do clerk tem `SCOPE_orders`, então o clerk passa pela porta, e
depois ouve que o pedido 1 não existe, palavra por palavra o que ouve sobre o pedido 99. A ana continua
lendo o dela.

**A resposta é 404 e não 403, de propósito.** Um 403 confirmaria que o pedido existe, e os ids contam a
partir de 1, então qualquer um com um token descobriria quantos pedidos a loja já recebeu e quais ids
estão vivos. Um 404 não diz nada sobre os dados dos outros. A verificação fica no serviço, junto da
consulta, porque é o único lugar que sabe de quem é a linha.
