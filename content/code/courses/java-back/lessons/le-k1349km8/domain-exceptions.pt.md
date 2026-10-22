---
title: Exceções nas palavras da própria loja
version: 1
---

## De onde esta aula parte

Esta aula parte da livraria como a aula 6 a deixou, compilada e rodando num segundo terminal com
`java -jar target/bookshop-0.1.0.jar`. Peça a ela três coisas que ela deveria recusar. O `-i` faz o curl
imprimir a linha de status e os cabeçalhos antes do corpo, e o `-w '\n'` acrescenta uma quebra de linha
depois do corpo, coisa com que uma resposta JSON não termina:

```
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 404 
Content-Length: 0
Date: Fri, 16 Oct 2026 23:42:22 GMT


ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' -w '\n'
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:22 GMT
Connection: close

{"timestamp":"2026-10-16T23:42:22.264Z","status":400,"error":"Bad Request","path":"/books"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author": "Machado de Assis", "priceCents": 3990}' -w '\n'
HTTP/1.1 201 
Location: /books/4
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:22 GMT

{"id":4,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990}
```

Cada resposta está errada de um jeito. A primeira é um 404 com `Content-Length: 0`: correta, e não diz
nada, então um cliente não consegue distinguir "não existe livro 99" de "não existe esse endereço". A
segunda é a página de erro do próprio Spring Boot, servida como JSON. Quatro campos violaram suas
restrições e o corpo não cita nenhum deles. A terceira é um bug. O ISBN `9786500000016` é Dom Casmurro,
o livro 1, e a loja acabou de gravá-lo uma segunda vez como livro 4, porque nada na aula 6 conferia.

## Onde um erro é decidido

A imagem tentadora é que erros são assunto do controller: cada método olha o que aconteceu e monta a
resposta, como o `get` da aula 6 transformava um `Optional` vazio em `ResponseEntity.notFound()`. Isso
funciona para um método e para de funcionar na segunda regra, porque **a regra e a resposta moram em
camadas diferentes**. "Um ISBN aparece uma vez só no catálogo" vale por qualquer caminho que um livro
chegue, por este controller, por uma importação ou por um teste, então a regra pertence ao
`BookService`. E o `BookService` não sabe nada de HTTP. Um 409 é o jeito de a web dizer isso, não o
jeito de a loja dizer.

Então o serviço diz o que deu errado nas palavras da loja, lançando uma exceção com o nome do problema,
e um único lugar na camada web transforma cada exceção em HTTP. Crie duas classes em
`src/main/java/com/example/bookshop/catalogue/`. `BookNotFoundException.java`:

```java
package com.example.bookshop.catalogue;

public class BookNotFoundException extends RuntimeException {

    public BookNotFoundException(long id) {
        super("No book has id " + id);
    }
}
```

E `DuplicateIsbnException.java`:

```java
package com.example.bookshop.catalogue;

public class DuplicateIsbnException extends RuntimeException {

    public DuplicateIsbnException(String isbn) {
        super("A book with ISBN " + isbn + " is already in the catalogue");
    }
}
```

As duas estendem `RuntimeException`, então nenhum método precisa declará-las. É essa a ideia: o
controller entre o serviço e o cliente não faz nada com elas, e uma exceção checada o obrigaria a
capturar ou declarar algo que ele não sabe tratar. Isso volta a importar na aula 14, em que o Spring
desfaz uma transação diante de uma `RuntimeException` e, por padrão, não diante de uma checada. Cada
mensagem é uma frase que o cliente pode ler, montada só com o que o próprio cliente mandou; a última
seção desta aula diz por que isso importa.

Substitua o `BookService.java` por este. O `find`, que devolvia um `Optional`, vira `get`, que devolve o
livro ou lança a exceção, e o `add` recusa um ISBN que o catálogo já tem:

```java
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.stereotype.Service;

@Service
public class BookService {

    private final BookRepository books;

    public BookService(BookRepository books) {
        this.books = books;
    }

    public List<Book> list() {
        return books.findAll();
    }

    public Book get(long id) {
        return books.findById(id).orElseThrow(() -> new BookNotFoundException(id));
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        if (books.findByIsbn(isbn).isPresent()) {
            throw new DuplicateIsbnException(isbn);
        }
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
```

A verificação e o salvamento são dois passos, então duas requisições chegando juntas com o mesmo ISBN
novo podem passar as duas pela verificação. Um mapa em memória não fecha essa brecha. Um banco de dados
fecha, e a tabela da aula 9 faz isso com uma restrição `UNIQUE` na coluna.

Depois substitua o `BookController.java`. Só o `get` mudou: ele devolve um `BookResponse` e deixa o livro
inexistente por conta da exceção.

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
        return books.list().stream().map(BookResponse::from).toList();
    }

    @GetMapping("/{id}")
    public BookResponse get(@PathVariable long id) {
        return BookResponse.from(books.get(id));
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

## Uma exceção que ninguém traduz

Compile com `mvn -q package`. O `-q` imprime erros e mais nada, então silêncio quer dizer sucesso. Pare a
aplicação no segundo terminal com Ctrl+C, inicie de novo e peça o livro 99:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 500 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:30 GMT
Connection: close

{"timestamp":"2026-10-16T23:42:30.119Z","status":500,"error":"Internal Server Error","path":"/books/99"}
```

Um **500**, Internal Server Error, para um livro que simplesmente não existe. A exceção saiu do
controller, atravessou o Spring MVC sem que nada a reclamasse e chegou ao contêiner de servlets, e a
página de erro do Spring Boot respondeu com o único status que tem para esse caso: o servidor falhou. O
segundo terminal registrou o erro, e o stack trace continua abaixo destas linhas:

```
2026-10-16T20:42:30.104-03:00 ERROR 16421 --- [bookshop] [nio-8080-exec-1] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: com.example.bookshop.catalogue.BookNotFoundException: No book has id 99] with root cause

com.example.bookshop.catalogue.BookNotFoundException: No book has id 99
```

Essa é a resposta certa para uma exceção que ninguém previu, e a errada para esta, que foi prevista. A
próxima seção dá a ela o seu 404.
