---
title: O proxy, e a chamada que passa ao lado dele
version: 1
---

A imagem comum de `@Transactional` é a de que a anotação muda o método: alguma coisa é compilada dentro
de `place` para abrir e confirmar. Nada é. `OrderService` é compilado exatamente como foi escrito. O que
muda é o objeto que o controller recebe. Quando o Spring encontra `@Transactional` num bean, ele cria um
**proxy**, uma subclasse gerada na partida que envolve cada chamada: o proxy abre a transação, chama o
método de verdade, e confirma ou desfaz. O contêiner da aula 5 injeta o proxy onde quer que um
`OrderService` seja pedido, então o controller segura o proxy e nunca o objeto em si.

## Vendo o proxy trabalhar

`JpaTransactionManager` é a classe a quem o proxy pede para abrir e fechar transações, e no nível
`debug` ela conta o que faz. Reinicie a aplicação no segundo terminal com esse logger ligado pela linha
de comando, e o perfil `sql` da aula 10 ao lado, e então faça de novo o pedido que falha:

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

As quatro primeiras linhas são da partida. `CatalogueReport` chama `BookService.count`, cujo proxy cria
uma transação somente leitura, e o próprio `count()` do Spring Data, que tem um `@Transactional` seu,
**se junta** a ela em vez de abrir uma segunda.

Depois vem o pedido. O proxy em volta de `place` criou uma transação, `PROPAGATION_REQUIRED` no
isolamento padrão do banco. Dentro dela, o Hibernate leu Dom Casmurro com uma leitura com trava, depois
enviou o `update` que `take(1)` tinha tornado necessário, porque ele descarrega as mudanças pendentes
antes de rodar uma consulta que poderia vê-las, e então leu Frankenstein. Quando a
`OutOfStockException` saiu de `place`, o proxy pediu um rollback, e o `update` foi junto com todo o
resto.

## Propagação: juntar-se, ou começar do zero

O `PROPAGATION_REQUIRED` desse log é a **propagação** padrão: juntar-se à transação de quem chamou, se
houver uma, e abrir uma nova se não houver. É por isso que o `count()` do Spring Data virou parte da
transação de `BookService.count` no log acima, em vez de confirmar sozinho.

O outro valor que vale conhecer é `REQUIRES_NEW`: suspende a transação de quem chamou, roda numa nova e
a confirma, faça o chamador o que fizer depois. Serve para um trabalho que precisa sobreviver ao rollback
do chamador, como uma linha registrando que um pedido foi tentado e recusado. Ele tem um custo que o pool
da seção 07 deixa visível: a transação suspensa mantém a sua conexão, então uma chamada `REQUIRES_NEW`
segura duas conexões ao mesmo tempo. Os outros valores de propagação existem e raramente são o que
alguém quer.

## Um desvio: a chamada que nunca encontra o proxy

O proxy só vê as chamadas que vêm de fora. Uma chamada de um método de `OrderService` para outro é uma
chamada Java comum por `this`, e nunca passa pelo proxy. Isso se chama **autoinvocação**
(*self-invocation*), e é fácil de escrever sem querer. Suponha que alguém divida `place` em dois, para
que um teste possa passar a hora, e leve a anotação para o método que faz o trabalho:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.time.temporal.ChronoUnit;\n\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n\n@Service\npublic class OrderService {\n\n    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n"}, {"code": "    public OrderResponse place(OrderRequest request) {\n        return placeAt(request, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n    }\n", "note": "`place` mantém o nome que o controller chama, calcula a hora e repassa. Não tem mais anotação."}, {"code": "    @Transactional\n    public OrderResponse placeAt(OrderRequest request, Instant placedAt) {\n        Order order = new Order(request.customer(), placedAt);\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }\n        return OrderResponse.from(orders.save(order));\n    }\n", "note": "O trabalho veio para cá, com anotação e tudo. O corpo é o `place` da aula, com a hora recebida de fora. Chamado de fora, este método ganharia a sua transação."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id) {\n        return orders.findWithLinesById(id).map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"}]}
```

Isto é um desvio: o arquivo é substituído, e a versão da aula volta no fim. Recompile, reinicie com o
logger de transações e peça um Dom Casmurro:

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
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"OrderController chama o proxy que o Spring criou, que abre uma transação quando o método chamado é anotado, chama o OrderService de verdade e confirma ou desfaz. Dentro do OrderService, place chama placeAt diretamente por this, sem passar pelo proxy, e placeAt roda sem transação.\"><defs><marker id=\"px-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"px-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderController</text><rect x=\"200\" y=\"30\" width=\"240\" height=\"150\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o proxy que o Spring criou</text><text x=\"215\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1. abre uma transação, se o</text><text x=\"228\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">método chamado for @Transactional</text><text x=\"215\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. chama o método de verdade</text><text x=\"215\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3. confirma, ou desfaz diante</text><text x=\"228\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de uma RuntimeException</text><rect x=\"470\" y=\"30\" width=\"210\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderService</text><rect x=\"485\" y=\"70\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">place(request)</text><rect x=\"485\" y=\"192\" width=\"180\" height=\"38\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Transactional placeAt(…)</text><line x1=\"165\" y1=\"105\" x2=\"198\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"440\" y1=\"89\" x2=\"483\" y2=\"89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#px-ah)\"></line><line x1=\"512\" y1=\"108\" x2=\"512\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#px-am)\"></line><text x=\"524\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">this.placeAt(…)</text><text x=\"524\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem proxy, sem transação</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">O controller recebeu o proxy,</text><text x=\"20\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca o objeto em si. Só uma chamada</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que vem de fora passa por ele.</text></svg>", "caption": "Uma chamada que passa pelo proxy ganha uma transação. Uma chamada de um método do serviço para outro, como neste desvio, nunca encontra o proxy."}
```

O pedido falhou com um `500`, e Dom Casmurro continua com os 4 exemplares que tinha. O log diz por quê:
não há `Creating new transaction` para `placeAt`, nem para mais nada naquela requisição até o `curl` que
leu o livro. O controller chamou `place` pelo proxy, e `place` não tem anotação, então o proxy repassou a
chamada direto. `place` então chamou `placeAt` por `this`, e a anotação de `placeAt` nunca foi lida.
Assim, `findByIdForUpdate` rodou sem transação nenhuma, e uma leitura com trava recusa isso:
`TransactionRequiredException: No active transaction`.

**Desta vez o erro fez barulho, e só por sorte.** Fez barulho porque a primeira coisa que `placeAt` faz é
uma leitura com trava, e uma trava não tem sentido fora de uma transação. A maior parte do que uma
transação protege não dá sinal nenhum. O `findById` e o `save` do Spring Data rodam cada um numa
transação curta própria quando ninguém abriu uma antes, então sem a trava o mesmo erro teria salvado o
pedido, nunca gravado o estoque, e respondido `201`.

Há duas correções. A anotação vai no método que o mundo de fora chama, que é o que o `OrderService` da
aula faz. Ou o trabalho transacional vai para outro bean, para que a chamada atravesse um proxy. Ponha de
volta o `OrderService.java` da aula, da seção 03, e recompile.

## readOnly

`BookService` marca toda leitura com `@Transactional(readOnly = true)`, e `get` em `OrderService` faz o
mesmo. Uma transação somente leitura continua sendo uma transação: as leituras dela dividem uma conexão e
um contexto de persistência, como as gravações de `place`. O Spring passa o indicador ao Hibernate, que
então deixa de guardar a cópia que mantém de cada entidade carregada para a verificação de mudanças e
nunca descarrega, e à conexão JDBC, que é marcada como somente leitura. Sai mais barato, e deixa a
intenção do método escrita onde quem lê a vê.
