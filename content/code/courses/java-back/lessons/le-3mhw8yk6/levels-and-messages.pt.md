---
title: Níveis, nomes de logger e mensagens
version: 1
---

Toda linha é escrita num de cinco **níveis**, do mais falante ao mais grave: `TRACE`, `DEBUG`, `INFO`,
`WARN` e `ERROR`. Cada logger tem um **limiar**, e uma linha abaixo do limiar do seu logger é jogada
fora antes de qualquer outra coisa acontecer com ela. O Logback sozinho deixou passar `DEBUG`, e por
isso a execução do `Hello` imprimiu as quatro linhas. O Spring Boot define o limiar do **logger
raiz**, aquele de quem todos os outros herdam, como `INFO`.

Os limiares são definidos por nome de logger, e os nomes são hierárquicos nos pontos: um limiar em
`com.example.bookshop` vale para `com.example.bookshop.ordering.OrderService` e para todo outro logger
abaixo dele, a menos que algo mais específico o substitua. No Boot um limiar é uma propriedade,
`logging.level.<nome>=<nível>`, que o perfil `dev` da aula 4 já usou para subir
`org.springframework.web` para `debug`.

## Duas das mudanças desta aula

Esta aula muda quatro arquivos da livraria. Substitua `src/main/resources/application.properties` por
este; a última linha é nova, e a próxima seção a explica:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

bookshop.jwt.secret=${BOOKSHOP_JWT_SECRET}
bookshop.jwt.lifetime=15m

logging.pattern.correlation=[%X{requestId:-}] 
```

E substitua `src/main/java/com/example/bookshop/ordering/OrderService.java`, que até agora fazia um
pedido sem dizer nada:

```schooling-example
{"language": "java", "file": "OrderService.java", "parts": [{"code": "package com.example.bookshop.ordering;\n\nimport java.time.Clock;\nimport java.time.temporal.ChronoUnit;\n\nimport org.slf4j.Logger;\nimport org.slf4j.LoggerFactory;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.BookRepository;\n", "note": "`Logger` e `LoggerFactory` vêm de `org.slf4j`. A classe depende da fachada e de nenhum backend."}, {"code": "@Service\npublic class OrderService {\n\n    private static final Logger log = LoggerFactory.getLogger(OrderService.class);\n", "note": "Um logger por classe, `static final`, com o nome da classe, então as linhas dele dizem `c.e.bookshop.ordering.OrderService`."}, {"code": "    private final BookRepository books;\n    private final OrderRepository orders;\n    private final Clock clock;\n\n    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {\n        this.books = books;\n        this.orders = orders;\n        this.clock = clock;\n    }\n"}, {"code": "    @Transactional\n    public OrderResponse place(String customer, OrderRequest request) {\n        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));\n        for (OrderRequest.Line line : request.lines()) {\n            Book book = books.findByIdForUpdate(line.bookId())\n                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));\n            book.take(line.quantity());\n            order.add(book, line.quantity());\n        }\n        Order saved = orders.save(order);", "note": "Como na aula 14, menos a última linha: o pedido salvo fica numa variável, porque a linha de log precisa do id dele."}, {"code": "        log.info(\"Order {} placed by {}: {} line(s), {} cents\",\n                saved.getId(), customer, saved.getLines().size(), saved.totalCents());\n        return OrderResponse.from(saved);\n    }\n", "note": "A linha é escrita depois do `save`, então o id existe, e dentro da transação, logo antes do commit. Quatro valores, quatro `{}`."}, {"code": "    @Transactional(readOnly = true)\n    public OrderResponse get(long id, String customer) {\n        return orders.findWithLinesById(id)\n                .filter(order -> order.getCustomer().equals(customer))\n                .map(OrderResponse::from)\n                .orElseThrow(() -> new OrderNotFoundException(id));\n    }\n}"}]}
```

```
ana@vm:~/bookshop$ mvn -q package
```

## O log da livraria, lido

Daqui em diante a aplicação roda num **segundo terminal**, com o que ela imprime mandado para um
arquivo, para o primeiro terminal poder pesquisar. É parecido com como um servidor roda: a aplicação
escreve na saída padrão e outra coisa recolhe. Lembre que `BOOKSHOP_JWT_SECRET` precisa estar
exportada neste terminal também, como a aula 15 fez:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar > app.log
```

O segundo terminal não mostra nada agora; tudo vai para o `app.log`. No primeiro terminal:

```
ana@vm:~/bookshop$ grep -E 'Starting Bookshop|Started|Catalogue' app.log
2026-10-22T19:30:41.658-03:00  INFO 18927 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 18927 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:30:46.856-03:00  INFO 18927 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.588 seconds (process running for 6.085)
2026-10-22T19:30:46.921-03:00  INFO 18927 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

Esse é o padrão do Boot para o Logback, e cada campo tem o seu lugar:

| campo | o que é |
|---|---|
| o primeiro | a hora, ao milissegundo, com a diferença para o UTC |
| `INFO` | o nível |
| o número depois dele | o id do processo |
| `[bookshop]` | `spring.application.name` |
| `[           main]` | a thread, completada ou cortada em 15 caracteres |
| `[]` | o espaço de correlação que `logging.pattern.correlation` acrescentou, vazio aqui |
| `c.example.bookshop.BookshopApplication` | o nome do logger, com os pacotes encurtados para caber em 40 caracteres |
| depois dos dois-pontos | a mensagem |

Pare a aplicação com Ctrl+C no segundo terminal, e inicie de novo com o limiar da raiz em `WARN`:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --logging.level.root=warn > app.log
```

```
ana@vm:~/bookshop$ cat app.log

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

```

O banner não é uma linha de log, então nenhum limiar o toca. Toda linha abaixo dele era `INFO`, e a
partida não escreveu nenhum aviso, então não sobra nada. Agora uma exceção para o pacote da própria
livraria:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --logging.level.root=warn --logging.level.com.example.bookshop=info > app.log
```

```
ana@vm:~/bookshop$ grep INFO app.log
2026-10-22T19:32:26.469-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 21234 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:32:26.472-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:32:30.707-03:00  INFO 21234 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.556 seconds (process running for 4.929)
2026-10-22T19:32:30.782-03:00  INFO 21234 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

A linha do catálogo voltou, como esperado. As outras três são uma lição sobre nomes. **Quem escreveu
essas linhas foi o Spring Boot, não a livraria**, e elas passaram porque o Boot registra a partida com
o nome da classe da própria aplicação. O nome de um logger é o que quem chama pediu; a convenção é a
classe de quem chama, e a maioria das bibliotecas a segue, mas é o nome que filtra as linhas, e o
código que as escreveu pode estar em qualquer lugar.

## Para que serve cada nível

Os níveis só são úteis se significam a mesma coisa para todo mundo que lê o log:

- `ERROR`: algo falhou e alguém precisa agir. Num servidor, é o nível que um alerta vigia.
- `WARN`: algo inesperado que a aplicação tratou, e que importaria se continuasse acontecendo.
- `INFO`: os eventos do negócio e da vida da aplicação: iniciou, um pedido foi feito.
- `DEBUG` e `TRACE`: detalhe para quem desenvolve e está atrás de um problema, desligado a menos que
  alguém ligue.

Uma cliente que pede dois exemplares de um livro com um só no estoque recebe um 409 da livraria, e
isso é a aplicação funcionando. Registrar isso como `ERROR` acordaria quem estiver de plantão numa
terça-feira qualquer; o `OrderService` nem registra, porque a resposta já diz.

## Placeholders, e por que não `+`

O `OrderService` escreve a sua linha com placeholders `{}` e os valores depois da mensagem:

```java
log.info("Order {} placed by {}: {} line(s), {} cents",
        saved.getId(), customer, saved.getLines().size(), saved.totalCents());
```

A versão tentadora monta a string por conta própria: `log.info("Order " + saved.getId() + " placed by "
+ customer ...)`. Ela imprime a mesma linha, e faz o trabalho de montar essa string **antes mesmo de
`info` ser chamado**, seja a linha escrita ou não. Em `INFO` isso quase não importa. Numa chamada
`debug` dentro de um laço sobre cada linha de pedido, com o limiar em `INFO`, ela monta e joga fora
uma string por volta, chamando `toString` em tudo que foi concatenado. Com placeholders, o backend
confere o limiar primeiro e formata só as linhas que mantém.

Os argumentos em si ainda são avaliados, porém: `log.debug("Stock {}", books.count())` roda a consulta
mesmo com debug desligado. Para um argumento que custa algo, o SLF4J 2 tem uma forma fluente que
recebe um supplier e só o chama quando a linha é mantida:

```java
log.atDebug().setMessage("Stock {}").addArgument(() -> books.count()).log();
```

**Uma exceção vai por último, sem placeholder para ela.** O `Hello` registrou
`log.error("Quantity '{}' is not a number", "two", e)`: um `{}` e dois argumentos, e o SLF4J trata um
`Throwable` que sobra no fim como a exceção da linha e imprime o stack trace. Os dois erros comuns
perdem esse stack trace. `log.error("Failed: " + e)` imprime só o `toString` da exceção, e
`log.error("Failed: {}", e.getMessage())` imprime só a mensagem dela. O stack trace é a parte que diz
onde.
