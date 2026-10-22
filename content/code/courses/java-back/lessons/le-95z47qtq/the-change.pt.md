---
title: O catálogo no Spring Data
version: 1
---

Oito arquivos do catálogo mudam. Dois deles saem, porque as classes escritas à mão na aula 10 não têm
mais o que fazer quando o Spring Data implementa as duas interfaces:

```
ana@vm:~/bookshop$ rm src/main/java/com/example/bookshop/catalogue/JpaBookRepository.java src/main/java/com/example/bookshop/catalogue/JpaAuthorRepository.java
```

O `AuthorRepository.java` vira a interface da seção anterior; troque-o agora se ainda não trocou.
Depois troque o `BookRepository.java` por este. Tudo o que está nele é uma das seções desta aula.
`findByIsbn` e o comprido `findByTitle…` são consultas derivadas, o assunto da próxima, e o
`@EntityGraph` é a seção seguinte. O `@Query` e o `TitleAndPrice` que ele devolve vêm depois, e `Page`
com `Pageable` é a última.

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findByIsbn(String isbn);

    @EntityGraph(attributePaths = "author")
    Page<Book> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = "author")
    List<Book> findByTitleContainingIgnoreCaseOrderByTitle(String text);

    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);
}
```

Crie o `TitleAndPrice.java` ao lado dele. É uma interface com dois getters e nenhuma implementação em
lugar nenhum do projeto, o que a seção sobre `@Query` explica:

```java
package com.example.bookshop.catalogue;

public interface TitleAndPrice {

    String getTitle();

    int getPriceCents();
}
```

O `BookService` mantém o formato, uma transação em volta de cada método e DTOs na saída, e ganha três
métodos para as três consultas novas. Troque-o por este:

```schooling-example
{"language": "java", "file": "BookService.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\n\nimport org.springframework.data.domain.Page;\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.stereotype.Service;\nimport org.springframework.transaction.annotation.Transactional;\n\n@Service\npublic class BookService {\n\n    private final BookRepository books;\n    private final AuthorRepository authors;\n\n    public BookService(BookRepository books, AuthorRepository authors) {\n        this.books = books;\n        this.authors = authors;\n    }\n", "note": "Os dois repositórios chegam pelo construtor, como sempre chegaram. Os tipos deles são as mesmas interfaces de que o `BookService` depende desde a aula 5, então nada aqui sabe que mudou o que as implementa."}, {"code": "    @Transactional(readOnly = true)\n    public long count() {\n        return books.count();\n    }\n", "note": "O `count` é herdado do `CrudRepository` e vira um único `select count(*)`. O relatório do catálogo chamava `list().size()`, que carregava todos os livros só para contá-los."}, {"code": "    @Transactional(readOnly = true)\n    public Page<BookResponse> list(Pageable pageable) {\n        return books.findAllBy(pageable).map(BookResponse::from);\n    }\n", "note": "Uma página de entidades, convertida em DTOs enquanto a transação ainda está aberta. O `Page.map` converte o conteúdo e mantém os números da página: qual página, de que tamanho, quantos no total."}, {"code": "    @Transactional(readOnly = true)\n    public List<BookResponse> search(String text) {\n        return books.findByTitleContainingIgnoreCaseOrderByTitle(text).stream().map(BookResponse::from).toList();\n    }\n", "note": "A consulta derivada da próxima seção. Os livros já voltam do banco ordenados, então nada aqui ordena."}, {"code": "    @Transactional(readOnly = true)\n    public List<TitleAndPrice> titlesBy(String author) {\n        return books.findTitlesByAuthor(author);\n    }\n", "note": "A projeção sai como entrou. Ela só tem um título e um preço, que já é tudo o que o cliente deve ver, então não há DTO para onde converter."}, {"code": "    @Transactional(readOnly = true)\n    public BookResponse get(long id) {\n        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));\n    }\n", "note": "O `findById` é herdado. O autor do livro é uma referência preguiçosa, e o `BookResponse.from` o carrega quando lê o nome, dentro desta transação."}, {"code": "    @Transactional\n    public BookResponse add(BookRequest request) {\n        if (books.findByIsbn(request.isbn()).isPresent()) {\n            throw new DuplicateIsbnException(request.isbn());\n        }\n        Author author = authors.findByName(request.author())\n                .orElseGet(() -> authors.save(new Author(request.author())));\n        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents()));\n        return BookResponse.from(book);\n    }\n}", "note": "Igual à aula 10, e agora são três chamadas ao Spring Data: `findByIsbn` e `findByName` são consultas derivadas, e o `save` é herdado."}]}
```

O controller ganha dois endpoints, e a lista dele vira uma página. O `GET /books` agora recebe um
`Pageable`, que o Spring Data monta a partir dos parâmetros `page`, `size` e `sort` da requisição, e
responde um `PagedModel`, o formato JSON de uma página. O `GET /books/search?q=…` procura nos títulos e
o `GET /books/by-author?name=…` lista os títulos de um autor com os preços. Troque o
`BookController.java`:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public PagedModel<BookResponse> list(@PageableDefault(size = 20, sort = "id") Pageable pageable) {
        return new PagedModel<>(books.list(pageable));
    }

    @GetMapping("/search")
    public List<BookResponse> search(@RequestParam String q) {
        return books.search(q);
    }

    @GetMapping("/by-author")
    public List<TitleAndPrice> byAuthor(@RequestParam String name) {
        return books.titlesBy(name);
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

E o `CatalogueReport` conta os livros em vez de listá-los:

```java
package com.example.bookshop.catalogue;

import java.time.Clock;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class CatalogueReport implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(CatalogueReport.class);

    private final BookService books;
    private final Clock clock;

    public CatalogueReport(BookService books, Clock clock) {
        this.books = books;
        this.clock = clock;
    }

    @Override
    public void run(String... args) {
        log.info("Catalogue opened on {} with {} books",
                LocalDateTime.now(clock).toLocalDate(), books.count());
    }
}
```

## Rodando com o SQL à vista

Faça o build. O `-q` deixa o Maven quieto a menos que algo falhe, então um build sem nada a relatar não
imprime nada:

```
ana@vm:~/bookshop$ mvn -q package
```

Depois suba a aplicação num **segundo terminal**, com o perfil `sql` da aula 10, que registra no log cada
comando que o Hibernate manda. O `grep` deixa passar três tipos de linha da inicialização: o relatório
do Spring Data sobre os repositórios que encontrou, o SQL e o relatório do catálogo.

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'interfaces|hibernate.SQL|Catalogue'
2026-10-22T19:18:03.006-03:00  INFO 21638 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 50 ms. Found 2 JPA repository interfaces.
2026-10-22T19:18:07.935-03:00 DEBUG 21638 --- [bookshop] [           main] org.hibernate.SQL                        : select count(*) from book b1_0
2026-10-22T19:18:07.962-03:00  INFO 21638 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

**`Found 2 JPA repository interfaces`** é a varredura da primeira seção, e ela aconteceu antes mesmo de o
banco ser acessado: os dois proxies existem desde o começo. **`select count(*) from book b1_0`** é o
`count()` herdado, mandado pelo `CatalogueReport` por meio do `BookService.count`, e `b1_0` é o apelido que
o Hibernate dá à tabela `book` em todo comando que escreve.

Deixe esse terminal rodando. Toda seção daqui em diante manda requisições pelo primeiro terminal e lê o
que chegou no segundo. Quando uma seção muda um arquivo, pare a aplicação com Ctrl+C, rode
`mvn -q package` e suba de novo com o mesmo comando.
