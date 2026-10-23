---
title: Dois pedidos, um exemplar
version: 1
---

A loja tem um Frankenstein. Dois clientes apertam o botão no mesmo instante. Cada requisição roda
`place` na sua própria transação, na sua própria conexão, e a pergunta é o que cada uma lê quando pede
o livro. A imagem errada é a de que uma transação cuida disso sozinha: `READ COMMITTED` deixa as duas
lerem estoque 1, as duas decidem que o exemplar é delas, e as duas gravam 0. O banco aceita as duas
gravações, o `CHECK` fica satisfeito, e passam a existir dois pedidos para um livro.

## Um desvio: o pedido sem a trava

Para ver isso acontecer, tire a trava. Em `OrderService.place`, troque `books.findByIdForUpdate(line.bookId())`
por `books.findById(line.bookId())`, a leitura simples que todo repositório tem. Isto é um desvio: ponha
a linha original de volta no fim dele. Recompile e reinicie no segundo terminal com o perfil `sql` da
aula 10, para que as instruções apareçam.

Dois pedidos pelo último exemplar, enviados no mesmo instante: o `&` roda cada `curl` em segundo plano
para que saiam juntos, e `wait` espera os dois. Depois, o livro e os pedidos que o banco guarda:

```
ana@vm:~/bookshop$ for c in ana bia; do curl -s -o /dev/null -w "$c %{http_code}\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":3,\"quantity\":1}]}" localhost:8080/orders & done; wait
ana 201
bia 201
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/3
{"id":3,"isbn":"9786500000030","title":"Frankenstein","author":"Mary Shelley","priceCents":3500,"stock":0}
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'SELECT o.id, o.customer, l.quantity FROM customer_order o JOIN order_line l ON l.order_id = o.id WHERE l.book_id = 3'
 id | customer | quantity 
----+----------+----------
  2 | ana      |        1
  3 | bia      |        1
(2 rows)
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'from book b1_0 where|update book'
2026-10-22T19:39:02.420-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:39:02.421-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:39:02.503-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,stock=?,title=? where id=?
2026-10-22T19:39:02.504-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,stock=?,title=? where id=?
2026-10-22T19:39:02.563-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 275\" role=\"img\" aria-label=\"Duas linhas do tempo lado a lado. À esquerda, com findById: ana e bia leem estoque 1, as duas gravam 0 e confirmam, e saem dois pedidos para um exemplar. À direita, com findByIdForUpdate: ana trava a linha e lê 1, bia espera a trava, ana grava 0 e confirma, bia então lê 0 e desfaz, e sai um pedido e um 409.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"330\" height=\"255\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findById</text><text x=\"95\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana</text><text x=\"255\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">bia</text><line x1=\"95\" y1=\"66\" x2=\"95\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"255\" y1=\"66\" x2=\"255\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"23\" y=\"74\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê estoque 1</text><rect x=\"183\" y=\"104\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"255\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê estoque 1</text><rect x=\"23\" y=\"134\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"95\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grava 0, confirma</text><rect x=\"183\" y=\"164\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"255\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grava 0, confirma</text><text x=\"175\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">dois pedidos, um exemplar</text><rect x=\"360\" y=\"10\" width=\"330\" height=\"255\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findByIdForUpdate</text><text x=\"445\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana</text><text x=\"605\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">bia</text><line x1=\"445\" y1=\"66\" x2=\"445\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"605\" y1=\"66\" x2=\"605\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"373\" y=\"74\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"445\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">trava a linha, lê 1</text><line x1=\"605\" y1=\"104\" x2=\"605\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"3\" stroke-dasharray=\"3 3\"></line><text x=\"613\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">espera</text><rect x=\"373\" y=\"134\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"445\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grava 0, confirma</text><rect x=\"533\" y=\"164\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"605\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">trava a linha, lê 0</text><rect x=\"533\" y=\"194\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"605\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não basta: desfaz tudo</text><text x=\"525\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um pedido, um 409</text></svg>", "caption": "Os mesmos dois pedidos pelo último Frankenstein, com o tempo correndo para baixo. Sem a trava, os dois leem 1; com ela, a segunda leitura espera a primeira transação terminar."}
```

Os dois pedidos foram aceitos. No log, duas threads rodam cada uma um `select` simples e depois um
`update`; o último `select` é o `curl` que leu o livro. Cada transação leu `stock` 1, cada `take(1)` deixou 0, e cada `update`
gravou 0: a segunda gravação não subtraiu da primeira, ela a substituiu. Essa é a **atualização
perdida**, e nada na saída diz que algo deu errado. Aqui as duas requisições saíram no mesmo
instante de propósito. Numa loja, basta que cheguem dentro dos poucos milissegundos que uma transação
dura, e o último exemplar de qualquer coisa procurada é exatamente onde isso acontece.

## A trava

Ponha `findByIdForUpdate` de volta. É o método que o `BookRepository` ganhou na seção 02:

```java
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Book b where b.id = :id")
    Optional<Book> findByIdForUpdate(long id);
```

`@Lock(LockModeType.PESSIMISTIC_WRITE)` pede ao Hibernate que leia a linha **e a trave até a transação
terminar**. O Hibernate transforma isso na leitura com trava do PostgreSQL, que o perfil `sql` mostra:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'for no key update'
2026-10-22T19:39:19.060-03:00 DEBUG 2369 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
2026-10-22T19:39:19.067-03:00 DEBUG 2369 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
```

`for no key update` é a trava de linha do PostgreSQL para uma gravação que não mexe na chave. Ela
bloqueia outra leitura com trava da linha, que é o objetivo, e ainda deixa inserir uma `order_line` que
aponta para o livro.

Uma segunda transação que pede a mesma linha com uma leitura com trava espera até a primeira confirmar
ou desfazer. Em `READ COMMITTED` a leitura dela então enxerga o resultado confirmado, 0 exemplares, e
`take` recusa. Os mesmos dois pedidos, com a trava, contra um estoque de volta a 1:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'UPDATE book SET stock = 1 WHERE id = 3'
UPDATE 1
ana@vm:~/bookshop$ for c in ana bia; do curl -s -o /dev/null -w "$c %{http_code}\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":3,\"quantity\":1}]}" localhost:8080/orders & done; wait
bia 409
ana 201
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/3
{"id":3,"isbn":"9786500000030","title":"Frankenstein","author":"Mary Shelley","priceCents":3500,"stock":0}
```

Um pedido e um `409`, e o estoque é 0, como deve ser. Qual cliente ganha é questão de microssegundos e
muda a cada execução; que exatamente um ganhe é o que a trava garante.

## O que a trava custa, e os outros caminhos

Uma trava faz a segunda transação esperar, então **uma transação que segura uma trava precisa ser
curta**. Nada lento cabe entre a leitura com trava e o commit: nenhuma chamada a um serviço de
pagamento, nenhum e-mail. Uma transação que espera pela rede segura a trava, e todo pedido daquele livro
entra na fila atrás dela, cada um segurando uma conexão enquanto espera, que é onde a seção 07 continua.

Travar antes de gravar se chama trava **pessimista**, e combina com uma linha que muita gente disputa,
como o último exemplar. Dois outros desenhos resolvem o mesmo problema:

- **Trava otimista**: a entidade tem uma coluna de versão anotada com `@Version`, o Hibernate acrescenta
  `where version = ?` ao seu `update`, e a transação que perde falha com uma exceção que a aplicação
  tenta de novo. Ninguém espera, o que combina com linhas que raramente colidem.
- **Uma atualização atômica**: `update book set stock = stock - ? where id = ? and stock >= ?`, e zero
  linhas atualizadas significa exemplares insuficientes. O banco faz a conta na linha que ele já está
  travando, ao custo de tirar a regra de `Book.take`.

A aula 8 de `sql-databases` vai mais fundo em travas, deadlocks e novas tentativas.
