---
title: O relacionamento, e quando a outra ponta é carregada
version: 1
---

O catálogo tem um relacionamento, e a aula 10 o mapeou: todo `Book` tem um `Author`, declarado em
`Book.author` como `@ManyToOne(fetch = FetchType.LAZY, optional = false)` e guardado na coluna
`author_id`. **`LAZY` quer dizer que carregar um livro não carrega o autor dele.** O campo guarda um
substituto que só conhece o id do autor, e na primeira vez que alguém pede mais a ele, o nome por
exemplo, ele manda um `select` próprio. **`optional = false`** diz que todo livro tem autor, que é também
o que `author_id bigint NOT NULL` diz no esquema.

O `Author` não tem uma lista dos seus livros. O relacionamento é mapeado de um lado só, que é tudo o
que a loja lê: do livro para o autor, nunca ao contrário. Uma coleção do outro lado,
`@OneToMany(mappedBy = "author")`, o tornaria **bidirecional**, e o pedido com as suas linhas, na aula
14, é onde uma coleção se paga.

## O problema N+1, de novo

A aula 10 viu que uma lista de livros com autores preguiçosos custa um `select` para os livros e mais
um para cada autor, e resolveu isso com `join fetch` no JPQL. Uma consulta derivada não tem JPQL onde
escrever `join fetch`. **`@EntityGraph(attributePaths = "author")` é a mesma instrução presa a um
método**: seja qual for a consulta que esse método roda, carregue o `author` junto com os livros.

A correção errada mais comum é trocar o mapeamento para `FetchType.EAGER`. Isso carrega o autor em toda
consulta que um dia tocar num livro, inclusive nas que nunca o leem, e é uma decisão sobre a entidade
tomada para resolver um problema de uma consulta. Um entity graph é uma decisão sobre uma consulta.

Para ver o que o grafo está fazendo, tire-o. Como desvio, apague a linha `@EntityGraph` acima do
`findAllBy` no `BookRepository`, depois faça o build, reinicie o segundo terminal e peça a primeira
página:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -s localhost:8080/books > /dev/null
```

```
2026-10-22T19:19:00.472-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id fetch first ? rows only
2026-10-22T19:19:00.908-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.933-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.938-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.944-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.946-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

Um `select` para a página de livros, depois um por autor. Devolva a linha, faça o build, reinicie e
peça de novo:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -s localhost:8080/books > /dev/null
```

```
2026-10-22T19:19:23.866-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.id fetch first ? rows only
```

Um comando só, com as colunas do autor dentro dele. É um **`join`**, um inner join, e não um
`left join`, porque o `optional = false` disse ao Hibernate que nenhum livro fica sem autor, então
nenhuma linha se perde ao exigir um.

## Um livro são dois comandos, e tudo bem

O `findById` é herdado do `CrudRepository` e não tem entity graph:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/2; echo
{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
```

```
2026-10-22T19:19:24.492-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:19:24.497-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

O livro, e depois o autor, quando o `BookResponse.from` lê o nome. É o mesmo carregamento preguiçoso, e
para um livro custa uma ida a mais ao banco. O problema N+1 é um problema de listas, em que o N cresce
com os dados; uma leitura isolada com uma referência preguiçosa não é motivo para anotar nada.

As duas cargas acontecem dentro do `BookService.get`, que é `@Transactional(readOnly = true)`. A aula 10
definiu `spring.jpa.open-in-view=false`, então um autor preguiçoso tocado depois de o serviço retornar,
no controller ou enquanto o Jackson escreve o JSON, lançaria `LazyInitializationException` em vez de
rodar mais uma consulta em silêncio. É por isso que o serviço entrega DTOs e nunca entidades.
