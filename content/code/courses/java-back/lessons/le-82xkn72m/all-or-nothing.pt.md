---
title: Tudo ou nada, com @Transactional
version: 1
---

Uma **transação** é um grupo de instruções que o banco trata como uma só: ou todas valem, ou nenhuma
vale. O código JDBC da aula 9 nunca pediu uma, e não precisava, porque uma conexão JDBC começa em modo
**autocommit**, em que cada instrução é uma transação sozinha. Isso basta para um `INSERT`. Um pedido
são três tipos de gravação, e o autocommit deixaria as primeiras ficarem quando uma posterior falha.

As quatro propriedades que uma transação promete se chamam **ACID**:

| letra | propriedade | o que significa para um pedido |
|---|---|---|
| A | atomicidade | o pedido, as linhas e a mudança de estoque acontecem juntos, ou nada acontece |
| C | consistência | toda restrição vale no commit, então `CHECK (stock >= 0)` nunca é violado |
| I | isolamento | o que um pedido enxerga de outro feito no mesmo instante (seção 05) |
| D | durabilidade | depois que o commit retorna, uma queda não o desfaz |

Em SQL, uma transação é `BEGIN`, as instruções, e depois `COMMIT` ou `ROLLBACK`. No Spring ninguém
escreve essas três palavras: uma anotação diz onde a transação começa e termina, e o Spring as emite.

## O serviço que faz o pedido

Crie `src/main/java/com/example/bookshop/ordering/OrderService.java`:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.temporal.ChronoUnit;\n\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n", "note": "Um serviço comum: dois repositórios e o bean `Clock` da aula 5, todos pelo construtor. Nada nele abre uma conexão ou diz `commit`."}, {"code": "    @Transactional\n    public OrderResponse place(OrderRequest request) {\n        Order order = new Order(request.customer(), clock.instant().truncatedTo(ChronoUnit.SECONDS));", "note": "`@Transactional` põe tudo o que `place` faz, em todos os repositórios, numa só transação do banco. Ela começa antes da primeira linha e termina quando o método retorna: com um commit, ou com um rollback se sair dele uma `RuntimeException`."}, {"code": "        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }", "note": "Para cada linha, `findByIdForUpdate` lê o livro e trava a linha dele até a transação terminar (seção 06), e `take` baixa o estoque no objeto. Nenhum `update` é escrito aqui: a verificação de mudanças do Hibernate, da aula 10, o envia depois, no máximo no commit."}, {"code": "        return OrderResponse.from(orders.save(order));\n    }\n", "note": "Salvar o pedido insere o pedido e, pela cascata, as linhas dele. Se um `take` lançou exceção, esta linha nunca é alcançada."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id) {\n        return orders.findWithLinesById(id).map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}", "note": "Uma leitura ganha uma transação somente leitura. A seção 04 diz o que `readOnly` muda."}]}
```

Compile, e inicie a aplicação num segundo terminal. O `grep` deixa só as linhas sobre a migração; sem ele
você vê a partida inteira, como nas aulas anteriores:

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

O Flyway encontrou o banco na versão 2, onde a aula 13 o deixou, e aplicou o `V3`. Deixe a aplicação
rodando e volte ao primeiro terminal.

## Um pedido que não pode ser atendido

Peça um Dom Casmurro e dois exemplares de Frankenstein, do qual a loja tem um. O `-w '\n'` só acrescenta
a quebra de linha com que o JSON não termina:

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

O `409` é o `ApiErrorHandler` respondendo pela `OutOfStockException`. O comando que importa é o último:
Dom Casmurro continua com 5 exemplares. A primeira linha do pedido foi tratada antes de a segunda falhar.
`take(1)` rodou em Dom Casmurro, e o Hibernate chegou a enviar o `update` ao banco, como o log da próxima
seção mostra. A mudança sumiu do mesmo jeito, porque a exceção saiu de `place` e o Spring desfez a
transação inteira. Nenhuma linha em `customer_order` foi gravada também.

Um pedido que a loja consegue atender passa, e os dois estoques mudam:

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

## O que é desfeito, e o que não é

Por padrão o Spring desfaz a transação quando uma `RuntimeException` ou um `Error` sai do método, e
**confirma quando sai uma exceção verificada**. A regra vem do EJB, em que uma exceção verificada
significava um resultado de negócio que o chamador devia tratar, e não uma falha. Ela surpreende quem
declara `throws SomeCheckedException` num método de serviço e encontra o trabalho pela metade
confirmado. `OutOfStockException` estende `RuntimeException`, então está do lado certo da regra. Um
método que precisa desfazer diante de uma exceção verificada diz isso com
`@Transactional(rollbackFor = SomeCheckedException.class)`.

O outro jeito de perder o rollback é capturar a exceção dentro do método. Um `try` que captura a
`OutOfStockException` em `place` e retorna normalmente diz ao Spring que tudo correu bem, e ele confirma
o que foi feito antes do lançamento.
