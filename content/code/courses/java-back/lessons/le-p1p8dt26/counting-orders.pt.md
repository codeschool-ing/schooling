---
title: Um counter seu
version: 1
---

Toda métrica até aqui descreve maquinário: requisições, conexões, memória. Nenhuma sabe o que é uma
livraria. Um `409` em `http.server.requests` pode ser um pedido de um livro que acabou, ou qualquer
outro conflito que uma aula futura acrescente; o timer não tem como saber, porque o motivo está no
código. Quando a pergunta é sobre o negócio, **o código tem de contar**, e o lugar de contar é onde a
decisão é tomada.

A livraria conta pedidos, com uma tag para o jeito como cada tentativa terminou: `placed` ou
`out-of-stock`. Substitua `src/main/java/com/example/bookshop/ordering/OrderService.java`:

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
      "note": "Novo: a API do próprio Micrometer. Nada neste arquivo cita o Prometheus, então trocar de backend não mudaria nada aqui."
    },
    {
      "code": "import org.slf4j.Logger;\nimport org.slf4j.LoggerFactory;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private static final Logger log = LoggerFactory.getLogger(OrderService.class);\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;"
    },
    {
      "code": "    private final Counter placed;\n    private final Counter refused;\n",
      "note": "Dois contadores, guardados em campos para que registrar custe uma chamada de método."
    },
    {
      "code": "    public OrderService(BookRepository books, OrderRepository orders, Clock clock, MeterRegistry meters) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;",
      "note": "O registry é um bean como outro qualquer, e chega pelo construtor (aula 5)."
    },
    {
      "code": "        this.placed = meters.counter(\"bookshop.orders\", \"outcome\", \"placed\");\n        this.refused = meters.counter(\"bookshop.orders\", \"outcome\", \"out-of-stock\");\n    }",
      "note": "Um nome, `bookshop.orders`, e uma tag `outcome` com dois valores: duas séries de uma família. Pedir de novo ao registry o mesmo nome com as mesmas tags devolve o mesmo contador."
    },
    {
      "code": "\n    @Transactional\n    public OrderResponse place(String customer, OrderRequest request) {\n        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));"
    },
    {
      "code": "            if (book.getStock() < line.quantity()) {\n                refused.increment();\n            }",
      "note": "Uma linha que pede mais do que o estoque conta como recusa. O `take` lança a exceção na linha seguinte e a transação sofre rollback, mas o contador já andou, e ele não volta atrás: uma recusa é justamente o que ele está ali para contar."
    },
    {
      "code": "            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }"
    },
    {
      "code": "        Order saved = orders.save(order);\n        placed.increment();",
      "note": "Contado depois que o pedido é salvo. O commit acontece quando o método retorna, então, no caso raro em que o próprio commit falha, este contador fica um à frente."
    },
    {
      "code": "        log.info(\"Order {} placed by {}: {} line(s), {} cents\",\n                saved.getId(), customer, saved.getLines().size(), saved.totalCents());\n        return OrderResponse.from(saved);\n    }\n\n    @Transactional(readOnly = true)\n    public OrderResponse get(long id, String customer) {\n        return orders.findWithLinesById(id)\n                .filter(order -> order.getCustomer().equals(customer))\n                .map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"
    }
  ]
}
```

O construtor mudou, então o teste unitário da aula 19 deixa de compilar. Ele precisa de um registry,
e o Micrometer traz um que guarda tudo na memória e não envia nada a lugar nenhum, que é exatamente o
que um teste quer. Substitua `src/test/java/com/example/bookshop/ordering/OrderServiceTest.java`:

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

E substitua `src/test/resources/application-test.properties`:

```properties
bookshop.jwt.secret=a-secret-for-tests-only-at-least-32-bytes
management.server.port=0
```

A linha nova importa para os testes de integração das aulas 19 a 21. Eles sobem a aplicação inteira,
servidor de gerenciamento incluído, e a porta `0` pede ao sistema operacional qualquer porta livre.
Sem ela, uma rodada de testes falharia enquanto uma livraria já estivesse rodando na 8081 em outro
terminal.

## Contando pedidos de verdade

Recompile e reinicie, e faça quatro pedidos como ana: o último exemplar de Frankenstein, o mesmo
livro de novo, um pedido de duas linhas e um livro que não existe.

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

Dois pedidos foram feitos, um foi recusado por falta de estoque e um pediu o livro 99. O counter
concorda:

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

O `COUNT` é a soma das duas séries. A tag escolhe uma:

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

O `404` não está em nenhuma das séries. Isso foi uma decisão, tomada quando o código pôs os
incrementos onde pôs: um pedido de um livro que não existe é um erro do cliente, e um pedido recusado
por falta de estoque é uma venda que a loja poderia ter feito. Se alguém quiser contar o primeiro tipo
também, ele é um terceiro valor da mesma tag, e não um meter novo.

## O que uma tag pode guardar

Os valores de uma tag têm de ser poucos e conhecidos de antemão. A `outcome` tem dois. Marcar cada
pedido com o cliente, `meters.counter("bookshop.orders", "customer", customer)`, pareceria inofensivo
com dois usuários. Também criaria uma série nova para cada cliente que a loja já teve: memória no
registry, uma linha em cada sistema que guarda os números, e um nome de conta copiado para um sistema
de monitoramento que o guarda por meses. Esse último custo é a regra da aula 16 sobre dados pessoais,
aplicada a números. Uma pergunta sobre um cliente pertence ao banco; uma métrica responde perguntas sobre todos
eles de uma vez.
