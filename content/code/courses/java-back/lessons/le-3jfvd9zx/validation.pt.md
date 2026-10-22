---
title: Bean Validation, regras na requisição
version: 1
---

Antes de mudar qualquer coisa, envie à aplicação como está um livro sem preço:

```
ana@vm:~/bookshop$ curl -si -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000061","title":"Lucíola","author":"José de Alencar"}' localhost:8080/books
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:32:15 GMT
Connection: close

{"timestamp":"2026-10-16T23:32:15.242Z","status":400,"error":"Bad Request","path":"/books"}
```

O segundo terminal diz o que aconteceu:

```
2026-10-16T20:32:15.240-03:00  WARN 393 --- [bookshop] [nio-8080-exec-1] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Cannot map `null` into type `int` (set `DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES` to 'false' to allow)]
```

Um 400, e uma recusa do **Jackson**: um preço ausente não cabe num `int`, e o Jackson 3 recusa em vez
de inventar um 0. É a resposta certa vinda do lugar errado. O Jackson recusou no passo 2, antes de o
record existir, e a mensagem dele cita um tipo Java, não um campo que um cliente enviou. Toda outra
regra sobre os valores de um livro tem de rodar depois que o record existe, e tem de dizer de que
campo está falando.

## O padrão e o starter

O **Bean Validation** é o padrão Jakarta para isso. As regras dele são anotações nos campos de um
objeto, chamadas **restrições**, e um validador confere um objeto contra elas e informa toda violação
que encontra, não só a primeira. A API fica em `jakarta.validation`, e o **Hibernate
Validator** é a implementação que o Spring Boot usa; ele divide nome e origem com o Hibernate da aula
10 e é uma biblioteca separada.

Substitua o `pom.xml` por este. A única mudança é a segunda dependência, e ela não traz versão porque
o parent a gerencia, como a aula 4 explicou:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

Depois substitua `BookRequest.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents) {
}
```

| restrição | recusa |
|---|---|
| `@NotNull` | `null`, o que inclui uma propriedade que falta no JSON |
| `@NotBlank` | `null`, uma string vazia, ou uma string só de espaços |
| `@Size(max = 200)` | uma string com mais de 200 caracteres |
| `@PositiveOrZero` | um número abaixo de zero |

**O preço agora é um `Integer`.** Um preço ausente chega como `null`, que um `Integer` consegue
guardar, então o Jackson não tem o que recusar e o `@NotNull` informa o problema como erro de campo,
ao lado de qualquer outro. O ISBN tem só `@NotNull` por enquanto.

Compile, reinicie e envie de novo o absurdo da seção anterior:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"12345","title":"","author":"José de Alencar","priceCents":-5}' localhost:8080/books
{"id":4,"isbn":"12345","title":"","author":"José de Alencar","priceCents":-5}
```

**Aceito, como antes.** As restrições estão no record e nada as lê. O Spring valida um argumento
`@RequestBody` só quando o parâmetro pede, e este não pede.

## @Valid pede

Substitua `BookController.java` pela versão final. Mudou uma palavra, `@Valid` na frente de
`@RequestBody`, e o import de que ela precisa:

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
    public ResponseEntity<BookResponse> get(@PathVariable long id) {
        return books.find(id)
                .map(BookResponse::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        Book book = books.add(request.isbn(), request.title(), request.author(), request.priceCents());
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(BookResponse.from(book));
    }
}
```

**`@Valid`** manda o passo 2 rodar o validador no record que o Jackson montou, e chamar o método só se
ele não informar nada. Compile, reinicie e tente o absurdo mais uma vez:

```
ana@vm:~/bookshop$ curl -si -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"12345","title":"","author":"José de Alencar","priceCents":-5}' localhost:8080/books
HTTP/1.1 400 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:32:33 GMT
Connection: close

{"timestamp":"2026-10-16T23:32:33.177Z","status":400,"error":"Bad Request","path":"/books"}
```

Um 400, enfim, com o corpo que o Spring Boot escreve para qualquer erro: um horário, o status, o nome
dele e o caminho. Ele diz que a requisição falhou e não por quê. O segundo terminal sabe por quê:

```
2026-10-16T20:32:33.171-03:00  WARN 1083 --- [bookshop] [nio-8080-exec-1] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in public org.springframework.http.ResponseEntity<com.example.bookshop.catalogue.BookResponse> com.example.bookshop.catalogue.BookController.add(com.example.bookshop.catalogue.BookRequest) with 2 errors: [Field error in object 'bookRequest' on field 'title': rejected value []; codes [NotBlank.bookRequest.title,NotBlank.title,NotBlank.java.lang.String,NotBlank]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [bookRequest.title,title]; arguments []; default message [title]]; default message [must not be blank]] [Field error in object 'bookRequest' on field 'priceCents': rejected value [-5]; codes [PositiveOrZero.bookRequest.priceCents,PositiveOrZero.priceCents,PositiveOrZero.java.lang.Integer,PositiveOrZero]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [bookRequest.priceCents,priceCents]; arguments []; default message [priceCents]]; default message [must be greater than or equal to 0]] ]
```

`MethodArgumentNotValidException` é o que o Spring lança quando o `@Valid` acha violações, e a linha
lista todo **erro de campo**. `title` foi rejeitado com o valor `[]` e "must not be blank";
`priceCents`, com `[-5]` e "must be greater than or equal to 0". Cada mensagem é o texto padrão da
sua restrição. O ISBN `12345` passou, porque `@NotNull` é tudo o que ele pede.

Por padrão, o Spring Boot deixa esses erros de campo fora do corpo, então um cliente vê um 400 seco e
precisa adivinhar que campo errou. A aula 7 monta um corpo de erro que cita cada campo e diz o que
há de errado com ele.

Um preço ausente agora é um erro de campo como os outros:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000061","title":"Lucíola","author":"José de Alencar"}' localhost:8080/books
{"timestamp":"2026-10-16T23:32:33.744Z","status":400,"error":"Bad Request","path":"/books"}
```

```
2026-10-16T20:32:33.743-03:00  WARN 1083 --- [bookshop] [nio-8080-exec-2] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in public org.springframework.http.ResponseEntity<com.example.bookshop.catalogue.BookResponse> com.example.bookshop.catalogue.BookController.add(com.example.bookshop.catalogue.BookRequest): [Field error in object 'bookRequest' on field 'priceCents': rejected value [null]; codes [NotNull.bookRequest.priceCents,NotNull.priceCents,NotNull.java.lang.Integer,NotNull]; arguments [org.springframework.context.support.DefaultMessageSourceResolvable: codes [bookRequest.priceCents,priceCents]; arguments []; default message [priceCents]]; default message [must not be null]] ]
```

## Dois portões, e o método atrás dos dois

O Jackson não foi embora. Envie um corpo que nem é JSON, cortado depois do ISBN:

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000061",' localhost:8080/books
{"timestamp":"2026-10-16T23:32:34.280Z","status":400,"error":"Bad Request","path":"/books"}
```

```
2026-10-16T20:32:34.279-03:00  WARN 1083 --- [bookshop] [nio-8080-exec-3] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Unexpected end-of-input within/between Object entries]
```

Então um corpo passa por dois portões antes de `add` rodar, e cada um falha do seu jeito:

| o que está errado | quem recusa | o que o log cita |
|---|---|---|
| o corpo não é JSON, ou um valor não cabe no seu tipo | o Jackson, ao montar o record | `HttpMessageNotReadableException` |
| o record existe, e um valor quebra uma restrição | o Bean Validation, por causa do `@Valid` | `MethodArgumentNotValidException`, um erro de campo por regra quebrada |

Nos dois casos o método nunca é chamado, e é isso que deixa curto o código do próprio controlador:
quando `add` roda, a requisição está bem formada e toda regra foi cumprida.

## O que as restrições padrão não sabem dizer

```
ana@vm:~/bookshop$ curl -s -w '\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000048","title":"Senhora","author":"José de Alencar","priceCents":3100}' localhost:8080/books
{"id":4,"isbn":"9786500000048","title":"Senhora","author":"José de Alencar","priceCents":3100}
```

`9786500000048` tem treze dígitos, então o `@NotNull` fica satisfeito e nada mais é perguntado. Não é
um ISBN: o último dígito de um ISBN é calculado a partir dos outros doze, e aqui ele está errado.
Nenhuma restrição do padrão conhece essa regra. O Hibernate Validator tem um `@ISBN` próprio, fora do
padrão, mas uma regra do seu domínio é exatamente para o que o mecanismo serve, e a próxima seção
escreve uma.
