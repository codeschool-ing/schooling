---
title: Escrevendo o JPQL você mesmo, e selecionando menos
version: 1
---

O `GET /books/by-author?name=…` quer os títulos e os preços dos livros de um autor, em ordem de título.
Uma consulta derivada conseguiria pedir isso, `findByAuthorNameOrderByTitle`, e carregaria entidades
`Book` inteiras para responder uma pergunta sobre dois campos delas. O `findTitlesByAuthor` escreve a
consulta:

```java
    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);
```

**O `@Query` recebe JPQL**, a linguagem que a aula 10 escreveu à mão, então ele nomeia a entidade `Book`
e o campo `priceCents`, nunca a tabela ou a coluna. **`b.author.name` percorre o relacionamento**, e o
Hibernate transforma o caminho num join. **`:name` é um parâmetro nomeado**, vinculado a partir do
parâmetro do método que tem o mesmo nome. O Java só guarda os nomes dos parâmetros na classe compilada
quando isso é pedido, e o pom pai do Spring Boot pede ao compilador, então não é preciso mais nada para
ligar os dois.

O tipo de retorno é a outra metade. O `TitleAndPrice` é uma interface com dois getters, `getTitle` e
`getPriceCents`, e nada no projeto a implementa. É uma **projeção por interface**. O Spring Data casa
cada getter com um valor de mesmo nome no resultado da consulta, que é para isso que servem os apelidos
`as title` e `as priceCents`. O que volta é um pequeno proxy por linha, que responde aos getters a
partir daquela linha.

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/by-author?name=H.%20G.%20Wells"; echo
[{"priceCents":2950,"title":"The Time Machine"},{"priceCents":3200,"title":"The War of the Worlds"}]
```

```
2026-10-22T19:19:25.049-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.title,b1_0.price_cents from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where a1_0.name=? order by b1_0.title
```

**Duas colunas, e nenhuma entidade em lugar nenhum.** O comando seleciona o título e o preço e mais
nada, e como nenhum `Book` foi carregado, nada entrou no contexto de persistência, nenhum substituto de
autor foi criado e não há problema N+1 possível. O join com `author` é o caminho no `where`.

Uma projeção não precisa ser uma interface. Um record também funcionaria, digamos um `TitlePrice` com
um construtor que recebe os dois valores, escrito em JPQL como
`select new com.example.bookshop.catalogue.TitlePrice(b.title, b.priceCents) from …`. A interface
dispensa a expressão de construtor e o record dispensa o proxy; para dois valores lidos direto para o
JSON, qualquer um serve, e este curso fica com a interface.

## Uma consulta também é conferida na inicialização

O Spring Data entrega todo `@Query` ao Hibernate enquanto a aplicação sobe, e o Hibernate analisa a
consulta contra as entidades. Como desvio, troque `b.priceCents` por `b.price` na consulta, pare a
aplicação, faça o build e suba no primeiro terminal:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1
Caused by: org.hibernate.query.sqm.PathElementException: Could not resolve attribute 'price' of 'com.example.bookshop.catalogue.Book'
```

**Nenhum `Book` tem um `price`**, e a aplicação parou antes de atender alguém, como fez com a consulta
derivada escrita errado. Devolva o `b.priceCents`.

Essa conferência só alcança o que o Hibernate enxerga. Com `nativeQuery = true`, o `@Query` manda a
string ao PostgreSQL como SQL, e o Hibernate não confere nada dela contra as entidades, então os erros
de uma consulta nativa esperam a primeira chamada. Ela também fica presa ao dialeto de um banco. A loja
não precisa de nenhuma.
