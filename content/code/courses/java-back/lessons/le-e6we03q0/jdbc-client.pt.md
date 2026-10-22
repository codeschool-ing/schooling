---
title: JdbcClient, e um catálogo que sobrevive a um reinício
version: 1
---

A última peça é o repositório. Apague o que guarda tudo em memória, para que reste um único
`BookRepository` para o Spring injetar, e crie
`src/main/java/com/example/bookshop/catalogue/JdbcBookRepository.java`:

```schooling-example
{"language": "java", "file": "JdbcBookRepository.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.springframework.jdbc.core.simple.JdbcClient;\nimport org.springframework.stereotype.Repository;\n", "note": "Nada nos imports é `java.sql`. O `JdbcClient` é do Spring, e faz a abertura, a preparação e o fechamento que o `Jdbc.java` escrevia à mão."}, {"code": "@Repository\npublic class JdbcBookRepository implements BookRepository {\n\n    private static final String COLUMNS = \"SELECT id, isbn, title, author, price_cents FROM book\";\n\n    private final JdbcClient jdbc;\n\n    public JdbcBookRepository(JdbcClient jdbc) {\n        this.jdbc = jdbc;\n    }\n", "note": "Continua `@Repository`, continua a interface `BookRepository` da aula 5, então o `BookService` não muda nada. O `JdbcClient` chega por injeção no construtor: o Boot monta um em volta do pool."}, {"code": "    @Override\n    public List<Book> findAll() {\n        return jdbc.sql(COLUMNS + \" ORDER BY id\").query(Book.class).list();\n    }\n", "note": "`query(Book.class)` mapeia cada linha para o construtor do record, pelo nome da coluna, e `list()` as junta. `price_cents` chega a `priceCents` porque um sublinhado seguido de letra casa com a maiúscula."}, {"code": "    @Override\n    public Optional<Book> findById(long id) {\n        return jdbc.sql(COLUMNS + \" WHERE id = ?\").param(id).query(Book.class).optional();\n    }\n\n    @Override\n    public Optional<Book> findByIsbn(String isbn) {\n        return jdbc.sql(COLUMNS + \" WHERE isbn = ?\").param(isbn).query(Book.class).optional();\n    }\n", "note": "`param` preenche o `?` em ordem, como fazia o `setLong`. `optional()` devolve um `Optional` vazio quando não há linhas e lança erro se houver duas, o que um ISBN único torna impossível."}, {"code": "    @Override\n    public Book save(Book book) {\n        long id = jdbc.sql(\"\"\"\n                INSERT INTO book (isbn, title, author, price_cents)\n                VALUES (:isbn, :title, :author, :priceCents)\n                RETURNING id\"\"\")\n                .paramSource(book)\n                .query(Long.class)\n                .single();\n        return book.withId(id);\n    }\n}", "note": "Parâmetros nomeados, `:isbn` e os outros, são preenchidos pelos acessores do record via `paramSource`. `RETURNING id` faz o `INSERT` responder com o número que o banco escolheu, e `single()` lê esse único valor."}]}
```

Leia-o ao lado do `Jdbc.java`. Cada método é uma única cadeia: o SQL, os parâmetros, o que cada
linha vira, e quantas linhas esperar. O que falta é tudo o que lá era cerimônia. O **`JdbcClient`**
pega uma conexão emprestada do pool, prepara o comando, define os parâmetros, percorre o
`ResultSet`, mapeia cada linha e fecha tudo na ordem certa, inclusive quando algo lança exceção. Os
parâmetros continuam sendo parâmetros, `?` ou `:nome`, nunca texto colado.

Ele acrescenta duas coisas que o `Jdbc.java` não tinha. Uma falha sai como uma das
`DataAccessException` do Spring, não verificadas, em vez de uma `SQLException` verificada, então o
`BookService` não precisa declarar nada. E o **`RETURNING id`**, um acréscimo do PostgreSQL ao
`INSERT`, faz o comando responder com o `id` que a sequência acabou de escolher. O serviço passou
`0`, o banco escolheu o número de verdade, e o `withId` devolve um `Book` que o carrega.

Compile, depois de apagar a classe antiga:

```
ana@vm:~/bookshop$ rm src/main/java/com/example/bookshop/catalogue/InMemoryBookRepository.java
ana@vm:~/bookshop$ mvn -q package
```

## Subindo a aplicação

Suba a aplicação num segundo terminal, com `java -jar target/bookshop-0.1.0.jar` em `~/bookshop`:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:15:46.183-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 15076 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:15:46.186-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:15:47.013-03:00  INFO 15076 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-22T19:15:47.022-03:00  INFO 15076 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:15:47.023-03:00  INFO 15076 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:15:47.044-03:00  INFO 15076 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 807 ms
2026-10-22T19:15:47.124-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2026-10-22T19:15:47.368-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@427a12b6
2026-10-22T19:15:47.370-03:00  INFO 15076 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2026-10-22T19:15:47.661-03:00  INFO 15076 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T19:15:47.669-03:00  INFO 15076 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 1.755 seconds (process running for 2.059)
2026-10-22T19:15:47.696-03:00  INFO 15076 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 3 books
```

Três linhas entre o Tomcat e o `Started` são novas, e são o pool: `HikariPool-1 - Starting...`,
`Added connection` com o `PgConnection` do driver, e `Start completed`. A primeira conexão rodou o
`schema.sql` e o `data.sql`, e a última linha é o `CatalogueReport` da aula 5 contando **3 livros**
que agora vêm de um `SELECT`. Pergunte ao servidor quem está conectado enquanto ela roda:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c "SELECT application_name, state, count(*) FROM pg_stat_activity WHERE usename = 'bookshop' GROUP BY 1, 2"
    application_name    | state  | count 
------------------------+--------+-------
 PostgreSQL JDBC Driver | idle   |    10
 psql                   | active |     1
(2 rows)
```

**Dez conexões, todas `idle`**, abertas pelo driver para o pool, e a única `active` é o `psql`
perguntando. Dez é o tamanho padrão do HikariCP. Uma requisição pega uma emprestada por alguns
milissegundos e a devolve; a aula 14 mede o que acontece quando todas estão emprestadas ao mesmo
tempo, e como dimensionar o pool.

## A API, sem mudança, sobre um banco

```
ana@vm:~/bookshop$ curl -s localhost:8080/books | python3 -m json.tool
[
    {
        "id": 1,
        "isbn": "9786500000016",
        "title": "Dom Casmurro",
        "author": "Machado de Assis",
        "priceCents": 3990
    },
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 3,
        "isbn": "9786500000030",
        "title": "Frankenstein",
        "author": "Mary Shelley",
        "priceCents": 3500
    }
]
ana@vm:~/bookshop$ curl -si -w '\n' localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000054", "title": "Wise Blood", "author": "Flannery O'\''Connor", "priceCents": 4100}'
HTTP/1.1 201 
Location: /books/4
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:15:48 GMT

{"id":4,"isbn":"9786500000054","title":"Wise Blood","author":"Flannery O'Connor","priceCents":4100}
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'SELECT id, title, author FROM book'
 id |      title       |      author       
----+------------------+-------------------
  1 | Dom Casmurro     | Machado de Assis
  2 | The Time Machine | H. G. Wells
  3 | Frankenstein     | Mary Shelley
  4 | Wise Blood       | Flannery O'Connor
(4 rows)
```

A lista são os três livros do `data.sql`, lidos pelo `findAll`. O `POST` é o da aula 6, respondido
como antes com `201` e um `Location`, e o `id` nele, **4**, é o que o `RETURNING` trouxe da
sequência. O `-w '\n'` só imprime uma quebra de linha depois do corpo, que termina sem uma. E o
`psql` mostra que a linha está na tabela, onde qualquer outro programa pode lê-la.

Agora o teste para o qual esta aula existia. Pare a aplicação com `Ctrl+C` e suba de novo. Entre as
linhas da subida, no segundo terminal:

```
2026-10-22T19:15:51.622-03:00  INFO 15244 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 4 books
```

**4 livros.** A livraria da aula 7 teria dito 3, porque o livro que você acrescentou morava num `Map`
e o mapa acabava junto com o processo. Este está no PostgreSQL, e o `data.sql` rodou de novo sem
acrescentar cópia de nada.
