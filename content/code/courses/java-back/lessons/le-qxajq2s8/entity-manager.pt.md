---
title: O entity manager e a JPQL
version: 1
---

O **`EntityManager`** é a única interface com que um programa conversa: `find` carrega uma entidade
pela chave, `persist` acrescenta uma nova, `createQuery` roda uma consulta em **JPQL**, a Jakarta
Persistence Query Language. A JPQL parece SQL e não é SQL. Ela cita entidades e os campos delas, nunca
tabelas e colunas, e o Hibernate a traduz para o SQL do banco com que estiver falando.

Os repositórios mantêm as interfaces que a aula 5 lhes deu, e assim nada acima deles precisa saber que
o mapeador existe. `BookRepository` não muda nada. Apague `JdbcBookRepository.java` e crie
`JpaBookRepository.java` ao lado:

```schooling-example
{
  "language": "java",
  "file": "JpaBookRepository.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport jakarta.persistence.EntityManager;\n\nimport org.springframework.stereotype.Repository;\n",
      "note": "O mesmo pacote de antes e um import que importa: `EntityManager`, a interface da especificação para o mapeador."
    },
    {
      "code": "@Repository\npublic class JpaBookRepository implements BookRepository {\n\n    private final EntityManager em;\n\n    public JpaBookRepository(EntityManager em) {\n        this.em = em;\n    }\n",
      "note": "`@Repository`, como na aula 9. O `EntityManager` chega pelo construtor, como qualquer outro bean. O que o Spring injeta é um substituto que repassa cada chamada ao contexto de persistência da transação em andamento naquele momento, e por isso um único repositório atende todas as requisições ao mesmo tempo."
    },
    {
      "code": "    @Override\n    public List<Book> findAll() {\n        return em.createQuery(\"select b from Book b order by b.id\", Book.class)\n                .getResultList();\n    }\n",
      "note": "JPQL, não SQL. `Book` é a entidade e `b.id` é o campo dela; não há nome de tabela nem lista de colunas. O Hibernate transforma isso num `SELECT` em `book` com todas as colunas que a entidade mapeia. Repare no que não foi pedido: o autor."
    },
    {
      "code": "    @Override\n    public Optional<Book> findById(long id) {\n        return Optional.ofNullable(em.find(Book.class, id));\n    }\n",
      "note": "`find` carrega uma entidade pela chave, ou devolve `null` quando ela não existe, e o `Optional.ofNullable` transforma isso no caso vazio que o serviço já responde com a `BookNotFoundException` da aula 7."
    },
    {
      "code": "    @Override\n    public Optional<Book> findByIsbn(String isbn) {\n        return em.createQuery(\"select b from Book b where b.isbn = :isbn\", Book.class)\n                .setParameter(\"isbn\", isbn)\n                .getResultStream()\n                .findFirst();\n    }\n",
      "note": "Um parâmetro leva dois-pontos e é ligado pelo nome, nunca colado na string: a JPQL fica protegida contra injeção do mesmo jeito que os `?` da aula 9."
    },
    {
      "code": "    @Override\n    public Book save(Book book) {\n        em.persist(book);\n        return book;\n    }\n}",
      "note": "`persist` torna gerenciado um objeto novo. Não há `INSERT` neste arquivo, e com chaves `IDENTITY` o Hibernate executa um na hora, porque só o banco sabe dizer qual é o id."
    }
  ]
}
```

O autor agora tem um repositório próprio, porque acrescentar um livro significa achar o autor dele ou
criar um. Crie `AuthorRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

public interface AuthorRepository {

    Optional<Author> findByName(String name);

    Author save(Author author);
}
```

e `JpaAuthorRepository.java`, que repete o mesmo padrão:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

import jakarta.persistence.EntityManager;

import org.springframework.stereotype.Repository;

@Repository
public class JpaAuthorRepository implements AuthorRepository {

    private final EntityManager em;

    public JpaAuthorRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<Author> findByName(String name) {
        return em.createQuery("select a from Author a where a.name = :name", Author.class)
                .setParameter("name", name)
                .getResultStream()
                .findFirst();
    }

    @Override
    public Author save(Author author) {
        em.persist(author);
        return author;
    }
}
```

## Onde fica a transação

Toda chamada acima roda dentro de um **contexto de persistência**, a memória de trabalho do mapeador
para uma unidade de trabalho, e numa aplicação Spring essa unidade é uma transação. **Quem a abre é o
serviço, não o repositório**, porque é o serviço que sabe onde um trabalho começa e termina. Substitua
`BookService.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BookService {

    private final BookRepository books;
    private final AuthorRepository authors;

    public BookService(BookRepository books, AuthorRepository authors) {
        this.books = books;
        this.authors = authors;
    }

    @Transactional(readOnly = true)
    public List<BookResponse> list() {
        return books.findAll().stream().map(BookResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public BookResponse get(long id) {
        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));
    }

    @Transactional
    public BookResponse add(BookRequest request) {
        if (books.findByIsbn(request.isbn()).isPresent()) {
            throw new DuplicateIsbnException(request.isbn());
        }
        Author author = authors.findByName(request.author())
                .orElseGet(() -> authors.save(new Author(request.author())));
        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents()));
        return BookResponse.from(book);
    }
}
```

O `@Transactional` vem do Spring, não do JPA. Num método ele quer dizer: comece uma transação antes de
o método rodar, faça o commit quando ele retornar, faça rollback se ele lançar uma exceção. O
`readOnly = true` avisa o Hibernate de que nada lido ali será gravado de volta, e ele pula o trabalho
que faria para perceber alterações. A aula 14 trata de transações a fundo; aqui elas importam por um
motivo só, que as duas próximas seções mostram de cada lado.

**O serviço devolve `BookResponse`, nunca uma entidade.** O mapeamento da entidade para o record que a
API envia acontece dentro da transação, enquanto o autor ainda pode ser carregado. `BookResponse.from`
muda para ler os getters da entidade:

```java
package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle(),
                book.getAuthor().getName(), book.getPriceCents());
    }
}
```

e o controller perde o mapeamento que fazia, já que o que ele recebe já é a resposta. Substitua
`BookController.java`:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public List<BookResponse> list() {
        return books.list();
    }

    @GetMapping("/{id}")
    public BookResponse get(@PathVariable long id) {
        return books.get(id);
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        BookResponse book = books.add(request);
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(book);
    }
}
```

## Rodando

Compile, e suba a aplicação num segundo terminal com `java -jar target/bookshop-0.1.0.jar`:

```
ana@vm:~/bookshop$ mvn -q package
```

O relatório do catálogo da aula 5 roda na inicialização e chama `list()`, então a linha dele no
segundo terminal é o primeiro sinal de que o mapeador funciona:

```
2026-10-16T20:33:16.175-03:00  INFO 2270 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-16 with 6 books
```

E a API responde como na aula 9, com três livros a mais e um formato diferente por baixo:

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
    },
    {
        "id": 4,
        "isbn": "9786500000047",
        "title": "Persuasion",
        "author": "Jane Austen",
        "priceCents": 3100
    },
    {
        "id": 5,
        "isbn": "9786500000054",
        "title": "Quincas Borba",
        "author": "Machado de Assis",
        "priceCents": 3690
    },
    {
        "id": 6,
        "isbn": "9786500000061",
        "title": "The War of the Worlds",
        "author": "H. G. Wells",
        "priceCents": 3200
    }
]
```

## Se você pulou o drop

Se o banco ainda tem a tabela da aula 9, a aplicação não sobe. Isto é o que o segundo terminal
imprime, reduzido com `grep` à linha que importa:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'Application run failed|PSQLException'
2026-10-16T20:33:11.667-03:00 ERROR 2209 --- [bookshop] [           main] o.s.boot.SpringApplication               : Application run failed
Caused by: org.postgresql.util.PSQLException: ERROR: column "author_id" of relation "book" does not exist
```

O `data.sql` pediu uma coluna que a tabela velha não tem, e o Spring para a aplicação em vez de rodar
contra um esquema que não conseguiu preparar. Volte ao fim da seção anterior e rode os dois comandos.

## Vendo o SQL

A aplicação agora roda SQL que não aparece em lugar nenhum do código-fonte, e o resto desta aula
precisa enxergá-lo. O Hibernate registra cada comando que envia no logger `org.hibernate.SQL`, no
nível `debug`. Crie `src/main/resources/application-sql.properties`:

```properties
logging.level.org.hibernate.SQL=debug
```

Esse arquivo só vale quando o perfil `sql` está ativo (aula 4), e o barulho fica fora de uma execução
normal. Pare a aplicação, suba de novo com o perfil e peça um livro:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/2
{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
```

O segundo terminal mostra quanto essa requisição custou:

```
2026-10-16T20:33:22.952-03:00 DEBUG 2406 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.id=?
2026-10-16T20:33:22.955-03:00 DEBUG 2406 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

**Dois comandos para um livro.** O `find` carregou a linha de `book` e mais nada; o autor era um proxy.
Depois `BookResponse.from` chamou `getAuthor().getName()`, o proxy precisou de um nome que não tinha e
pediu a linha de `author`. É o carregamento lazy funcionando exatamente como projetado, e é também, em
miniatura, o problema de duas seções adiante.
