---
title: Criando um livro com POST, 201 e Location
version: 1
---

Substitua `BookController.java` por esta versão. Os dois métodos `GET` não mudam, e o novo está no
final:

```java
package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

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
    public ResponseEntity<BookResponse> get(@PathVariable long id) {
        return books.find(id)
                .map(BookResponse::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

O que o método novo diz, anotação por anotação:

- **`@PostMapping`** sem caminho próprio atende `POST /books`, o mesmo caminho da lista com outro
  método. Essa é a convenção do HTTP: um `GET` numa coleção a lê, um `POST` nela acrescenta algo.
- **`@RequestBody`** é o passo 2 com corpo: o Jackson lê o JSON num `BookRequest`, e só então o
  método é chamado.
- O serviço monta o `Book` e o repositório escolhe o id dele, continuando a contagem a partir dos três
  livros com que começou.
- **`ResponseEntity.created(uri)`** define o status como **201 Created** e acrescenta um cabeçalho
  **`Location`** dizendo onde o livro novo mora agora. O corpo é o livro como foi guardado, então o
  cliente fica sabendo o id sem perguntar de novo.

Compile com `mvn -q package`, pare a aplicação no segundo terminal com Ctrl+C e inicie-a de novo com
`java -jar target/bookshop-0.1.0.jar`.

## Enviando um corpo com o curl

Mais duas opções. `-d '...'` envia o texto como corpo, e faz da requisição um `POST` sem precisar
dizer. `-H 'Content-Type: application/json'` acrescenta o cabeçalho que diz ao servidor que o corpo é
JSON.

```
(pending post-201)
```

Um 201, `Location: /books/4` e o livro novo no corpo. Pedir o `Location` devolve o mesmo livro: o
cabeçalho é um endereço que um cliente pode usar na hora.

## O id que o cliente não escolhe

Este corpo diz `"id": 1`, o id de *Dom Casmurro*:

```
(pending post-id)
```

O livro novo é o número 5, e o livro 1 está intacto. O Jackson não achou componente `id` em
`BookRequest` e descartou a propriedade, sem erro e sem linha no log. O record da requisição decidiu o
que um cliente tem permissão de dizer.

## Esquecendo o cabeçalho

```
(pending post-415)
```

Sem `-H`, o curl rotula um corpo de `-d` como `application/x-www-form-urlencoded`, o formato que um
formulário HTML envia. Nada neste controlador lê formulários, então a resposta é **415 Unsupported
Media Type**, e o cabeçalho `Accept` dela lista o que `POST /books` lê. Quando um POST que você esperava
que funcionasse responde 415, o `Content-Type` é a primeira coisa a conferir.

## Um corpo sem sentido

```
(pending post-junk)
```

Um ISBN de cinco dígitos, um título vazio e um preço abaixo de zero, aceitos e guardados como o livro
6. O Jackson garantiu que o JSON estava bem formado e que cada valor cabia no seu tipo. Se os valores
fazem sentido é outra pergunta, e nada na aplicação a faz ainda. A próxima seção faz.
