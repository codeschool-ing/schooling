---
title: Dizendo o que o código não diz, com anotações
version: 1
---

O controller tem um comentário Javadoc em cada método, e o springdoc não usou nenhum. É razoável
esperar o contrário, já que os comentários dizem exatamente o que falta no documento. O motivo está
em onde cada um olha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"BookController.java alimenta dois caminhos. Em cima, a ferramenta javadoc lê o código-fonte na hora do build e escreve páginas HTML em target/reports/apidocs, para quem programa em Java. Embaixo, o javac compila para BookController.class, que guarda as anotações e descarta os comentários; o springdoc lê a aplicação rodando e serve /v3/api-docs em JSON, para o Swagger UI e para clientes HTTP.\"><defs><marker id=\"l17a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"128\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookController.java</text><text x=\"105.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comentários e anotações</text><rect x=\"260\" y=\"30\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">javadoc</text><text x=\"335.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na hora do build</text><rect x=\"480\" y=\"30\" width=\"200\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">páginas HTML</text><text x=\"580.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">target/reports/apidocs</text><text x=\"580\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lidas por quem programa em Java</text><rect x=\"225\" y=\"190\" width=\"110\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">javac</text><text x=\"280.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na hora do build</text><rect x=\"365\" y=\"190\" width=\"160\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookController.class</text><text x=\"445.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem os comentários</text><rect x=\"555\" y=\"190\" width=\"125\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">springdoc</text><text x=\"617.5\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na aplicação rodando</text><rect x=\"555\" y=\"272\" width=\"125\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617.5\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/v3/api-docs</text><text x=\"617.5\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON</text><text x=\"545\" y=\"294\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lido pelo Swagger UI e por clientes HTTP</text><path d=\"M 190 145 C 225 145, 225 58, 258 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 410 58 L 478 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 190 172 C 205 172, 205 218, 223 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 335 218 L 363 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 525 218 L 553 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path><path d=\"M 617 246 L 617 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17a-ah)\"></path></svg>", "caption": "Os comentários chegam à ferramenta javadoc e param no javac. O que o springdoc consegue ler é o que sobrevive no arquivo .class: as anotações.", "same": ["JSON"]}
```

O `javadoc` lê o **código-fonte**, na hora do build, e os comentários estão no código-fonte. O
springdoc lê a **aplicação rodando**, e a essa altura os comentários já se foram: o `javac` não os
copia para o arquivo .class. As anotações sobrevivem, porque as que o springdoc lê são declaradas
para ficar disponíveis em tempo de execução. O arquivo .class confirma, para um comentário e uma
anotação do mesmo método:

```
ana@vm:~/bookshop$ javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep -c 'One page of the catalogue'
0
ana@vm:~/bookshop$ javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep 'List the catalogue'
   #82 = Utf8               List the catalogue, a page at a time
          summary="List the catalogue, a page at a time"
```

As palavras do comentário não aparecem em lugar nenhum de `BookController.class`; o `summary` que
você vai escrever daqui a pouco está lá duas vezes, como string na tabela de constantes da classe e
como valor da anotação.

Então o segundo leitor recebe anotações dos pacotes `io.swagger.v3.oas.annotations`, que o starter
do springdoc trouxe. A própria documentação do springdoc descreve um processador de anotações, o
therapi-runtime-javadoc, que guarda os comentários onde ele consegue lê-los; este projeto prefere
manter os dois separados, porque os dois leitores querem frases diferentes. Quem programa em Java
quer saber que `get` lança `BookNotFoundException`. Um cliente HTTP quer saber que recebe um 404.

## Um nome e um jeito de entrar

Duas coisas descrevem a API como um todo, e não uma operação: como ela se chama e como um cliente
prova quem é. As duas vão num bean só. Crie
`src/main/java/com/example/bookshop/web/OpenApiConfig.java`:

```java
package com.example.bookshop.web;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI bookshopApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Bookshop API")
                        .version("0.1.0")
                        .description("The catalogue and the orders of a small bookshop."))
                .components(new Components().addSecuritySchemes("bearer",
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT")));
    }
}
```

O springdoc usa um bean `OpenAPI`, quando existe um, como o começo do documento que monta. `Info`
substitui o título provisório. O **esquema de segurança** chamado `bearer` diz a um cliente que esta
API recebe um token no cabeçalho `Authorization`, como `Bearer` seguido do token, e que o token é um
JWT. Ele diz como enviar um token. Quais operações precisam de um é dito por operação, abaixo.

## O controller, anotado

Substitua o `BookController.java` pela versão final. O Javadoc é o da seção anterior, sem mudança:

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.net.URI;\nimport java.util.List;\n\nimport io.swagger.v3.oas.annotations.Operation;\nimport io.swagger.v3.oas.annotations.Parameter;\nimport io.swagger.v3.oas.annotations.media.Content;\nimport io.swagger.v3.oas.annotations.media.Schema;\nimport io.swagger.v3.oas.annotations.responses.ApiResponse;\nimport io.swagger.v3.oas.annotations.security.SecurityRequirement;\nimport io.swagger.v3.oas.annotations.tags.Tag;\nimport jakarta.validation.Valid;\n\nimport org.springdoc.core.annotations.ParameterObject;\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.data.web.PageableDefault;\nimport org.springframework.data.web.PagedModel;\nimport org.springframework.http.ProblemDetail;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RequestBody;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RequestParam;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "Os imports de `io.swagger.v3.oas.annotations` são as anotações do OpenAPI. `ParameterObject` é do próprio springdoc, e `ProblemDetail` é a classe do Spring que o tratador de erros da aula 7 devolve."
    },
    {
      "code": "/**\n * The catalogue over HTTP: reading it is open to anyone, adding to it needs\n * the {@code catalogue:write} scope.\n */\n@Tag(name = \"Catalogue\")\n@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "`@Tag` dá o nome do grupo em que as operações deste controller aparecem. Sem ela, o springdoc dá ao grupo o nome da classe, como fez com os pedidos: `order-controller`."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n"
    },
    {
      "code": "    /**\n     * One page of the catalogue, in the order the {@code sort} parameter asks for.\n     *\n     * @param pageable page number, page size and sort, from the query string\n     * @return the page, with the total count in its metadata\n     */\n    @Operation(summary = \"List the catalogue, a page at a time\")\n    @GetMapping\n    public PagedModel<BookResponse> list(@ParameterObject @PageableDefault(size = 20, sort = \"id\") Pageable pageable) {\n        return new PagedModel<>(books.list(pageable));\n    }\n",
      "note": "`@Operation(summary = ...)` é uma linha para quem lê pelo HTTP. `@ParameterObject` diz ao springdoc para descrever os campos de `Pageable` como parâmetros de consulta separados, que é como o Spring os lê."
    },
    {
      "code": "    /**\n     * Books whose title contains the text, ignoring case.\n     *\n     * @param q the text to look for\n     * @return the matching books, by title\n     */\n    @Operation(summary = \"Search titles\")\n    @GetMapping(\"/search\")\n    public List<BookResponse> search(@RequestParam String q) {\n        return books.search(q);\n    }\n\n    /**\n     * Titles and prices of one author's books.\n     *\n     * @param name the author's name, exactly as stored\n     * @return title and price of each book, by title\n     */\n    @Operation(summary = \"Titles and prices by one author\")\n    @GetMapping(\"/by-author\")\n    public List<TitleAndPrice> byAuthor(@RequestParam String name) {\n        return books.titlesBy(name);\n    }\n",
      "note": "Um resumo cada, e nada mais: os parâmetros de consulta `q` e `name` já estavam certos."
    },
    {
      "code": "    /**\n     * One book.\n     *\n     * @param id the book's id\n     * @return the book\n     * @throws BookNotFoundException when no book has that id\n     */\n    @Operation(summary = \"Get one book\")\n    @ApiResponse(responseCode = \"200\", description = \"The book\")\n    @ApiResponse(responseCode = \"404\", description = \"No book has that id\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @GetMapping(\"/{id}\")\n    public BookResponse get(@Parameter(description = \"the book's id\") @PathVariable long id) {\n        return books.get(id);\n    }\n",
      "note": "Cada `@ApiResponse` é uma resposta que a operação pode dar. O 404 declara seu tipo de mídia e seu schema; sem `content`, o springdoc dá a toda resposta o tipo de retorno do método, e um 404 não traz um `BookResponse`. `@Parameter` descreve um parâmetro."
    },
    {
      "code": "    /**\n     * Adds a book to the catalogue, creating its author if the name is new.\n     *\n     * @param request the book, validated before this method runs\n     * @return 201 with the new book and its address in {@code Location}\n     * @throws DuplicateIsbnException when the ISBN is already in the catalogue\n     */\n    @Operation(summary = \"Add a book\", security = @SecurityRequirement(name = \"bearer\"))\n    @ApiResponse(responseCode = \"201\", description = \"Added\")\n    @ApiResponse(responseCode = \"400\", description = \"The request failed validation\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @ApiResponse(responseCode = \"409\", description = \"The ISBN is already in the catalogue\",\n            content = @Content(mediaType = \"application/problem+json\", schema = @Schema(implementation = ProblemDetail.class)))\n    @PostMapping\n    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {\n        BookResponse book = books.add(request);\n        return ResponseEntity.created(URI.create(\"/books/\" + book.id())).body(book);\n    }",
      "note": "`security` se refere ao esquema pelo nome, `bearer`, vindo do `OpenApiConfig`, e diz que esta operação precisa dele. As três respostas de erro são problem details, como o 404."
    },
    {
      "code": "}"
    }
  ]
}
```

Gere o build, reinicie e salve o documento novo por cima do antigo:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json
```

O título, a descrição e a versão são os que o `Info` deu:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json info
{
  "title": "Bookshop API",
  "description": "The catalogue and the orders of a small bookshop.",
  "version": "0.1.0"
}
```

`GET /books/{id}` tem duas respostas agora:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books/{id} get responses
{
  "200": {
    "description": "The book",
    "content": {
      "*/*": {
        "schema": {
          "$ref": "#/components/schemas/BookResponse"
        }
      }
    }
  },
  "404": {
    "description": "No book has that id",
    "content": {
      "application/problem+json": {
        "schema": {
          "$ref": "#/components/schemas/ProblemDetail"
        }
      }
    }
  }
}
```

O 404 está no documento agora, como `application/problem+json` com uma referência a um schema
chamado `ProblemDetail`. O 200 continua dizendo `*/*`: o controller não declara tipo de mídia, e o
documento não inventa um. O schema para onde o 404 aponta também é novo:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json components schemas ProblemDetail
{
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "format": "uri"
    },
    "title": {
      "type": "string"
    },
    "status": {
      "type": "integer",
      "format": "int32"
    },
    "detail": {
      "type": "string"
    },
    "instance": {
      "type": "string",
      "format": "uri"
    },
    "properties": {
      "type": "object",
      "additionalProperties": {}
    }
  }
}
```

O springdoc montou este schema a partir da classe `ProblemDetail` do Spring, e os cinco primeiros
membros são os que a RFC 9457 define e a aula 7 usou. O sexto não é o que um cliente recebe.
`properties` é o campo Java que guarda os membros extras, e o Jackson os escreve no nível de cima do
corpo: o 400 da aula 7 traz `errors` ao lado de `title` e `detail`, e não dentro de um objeto chamado
`properties`. As anotações melhoram o documento, e ler o que ele diz continua sendo trabalho seu.

`@ParameterObject` substituiu o parâmetro impossível de `GET /books`:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books get parameters
[
  {
    "name": "page",
    "in": "query",
    "description": "Zero-based page index (0..N)",
    "required": false,
    "schema": {
      "type": "integer",
      "default": 0,
      "minimum": 0
    }
  },
  {
    "name": "size",
    "in": "query",
    "description": "The size of the page to be returned",
    "required": false,
    "schema": {
      "type": "integer",
      "default": 20,
      "minimum": 1
    }
  },
  {
    "name": "sort",
    "in": "query",
    "description": "Sorting criteria in the format: property,(asc|desc). Default sort order is ascending. Multiple sort criteria are supported.",
    "required": false,
    "schema": {
      "type": "array",
      "default": [
        "id,ASC"
      ],
      "items": {
        "type": "string"
      }
    }
  }
]
```

Três parâmetros opcionais, com os padrões de `@PageableDefault`, `size` 20 e `sort` `id,ASC`, e
descrições que o springdoc traz prontas para `Pageable`. Isto é o que um cliente consegue enviar de
verdade.

E a operação que acrescenta um livro, e o esquema a que ela se refere:

```
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json paths /books post security
[
  {
    "bearer": []
  }
]
ana@vm:~/bookshop$ python3 ~/oapi.py ~/api.json components securitySchemes
{
  "bearer": {
    "type": "http",
    "scheme": "bearer",
    "bearerFormat": "JWT"
  }
}
```

`POST /books` cita o esquema `bearer`, e o esquema é o que o `OpenApiConfig` declarou. A lista vazia
depois do nome é onde um esquema OAuth 2.0 listaria escopos. Este não lista nenhum, então o documento
diz que é preciso um token, e não que ele precisa trazer `catalogue:write`; essa frase está no
Javadoc da classe, onde quem lê pelo HTTP nunca vai vê-la. Se os clientes precisam saber, o
`description` do `@Operation` é o lugar para dizer.

Os pedidos continuam como o springdoc os encontrou: um 200 onde o código responde 201, e nenhum
`security` onde toda chamada precisa de token. Corrigi-los pede as mesmas anotações no
`OrderController`, e as questões do fim desta aula perguntam quais.
