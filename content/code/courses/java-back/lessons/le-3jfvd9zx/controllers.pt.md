---
title: Um controlador, e o curl como cliente dele
version: 1
---

A livraria é um servidor web desde a aula 4, e até hoje não respondeu a pergunta nenhuma. A aula 5 a
encheu de beans, um serviço e um repositório com três livros, mas nada liga uma requisição que chega
na porta 8080 a qualquer um deles. Compile o projeto da aula 5, inicie-o e peça os livros:

```
(pending lesson5-404)
```

Um 404, com um pequeno corpo JSON que o Spring Boot escreve para qualquer caminho que ninguém trata.
Esta aula escreve o código que trata `/books`.

## O mínimo de HTTP de que esta aula precisa

Uma requisição é um método, um caminho, alguns cabeçalhos e às vezes um corpo. `GET`
pede alguma coisa e `POST` envia algo para ser criado. A resposta é um **código de status**,
cabeçalhos e um corpo. Estes são os códigos que esta aula encontra:

| código | significado | onde você o encontra |
|---|---|---|
| 200 | aqui está | um livro que existe |
| 201 | criado | um livro novo, na seção sobre POST |
| 400 | a requisição está errada | JSON ruim, ou um valor que quebra uma regra |
| 404 | não há nada aqui | um livro que não existe, um caminho que ninguém trata |
| 405 | o caminho existe, mas não para este método | `DELETE` num livro |
| 415 | um corpo num formato que este endpoint não lê | um POST sem o `Content-Type` |

Se você veio pela trilha `backend`, a aula 6 de `web-fundamentals` tratou de métodos, cabeçalhos e
códigos de status, e a aula 1 de `apis` leva os códigos de status e o desenho de uma API muito mais
longe.

## Uma classe que é chamada, não um laço que lê

A imagem comum de um framework web é um código que lê a requisição: tira os bytes do socket, analisa
a primeira linha, olha o caminho, desvia para a função certa. **O Spring MVC inverte isso.** Você
escreve uma classe cujos métodos são rotulados com as requisições que atendem, e o framework faz a
leitura e os chama. Nada no controlador abaixo toca num socket, num cabeçalho ou num byte de JSON.

Primeiro o record com que a API responde. Crie
`src/main/java/com/example/bookshop/catalogue/BookResponse.java`:

```java
package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.id(), book.isbn(), book.title(), book.author(), book.priceCents());
    }
}
```

Ele é o que a API diz sobre um livro, montado a partir de um `Book` por `from`. Hoje tem os mesmos
cinco componentes de `Book`, e a seção sobre DTOs explica por que ele é um segundo record mesmo assim.

Depois o **controlador**, ao lado dele, em `BookController.java`. Esta versão atende as duas
requisições `GET`; a seção sobre POST acrescenta um terceiro método.

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\n\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "Tudo o que é importado aqui vem do `spring-web`, que o starter web traz desde a aula 4."
    },
    {
      "code": "@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "`@RestController` faz da classe um bean, achado pela varredura de componentes da aula 5, e diz que o que os métodos devolvem é o corpo da resposta. `@RequestMapping` na classe põe `/books` na frente de todo caminho abaixo dela."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n",
      "note": "Injeção pelo construtor, como na aula 5: o controlador pede o serviço e nunca constrói um."
    },
    {
      "code": "    @GetMapping\n    public List<BookResponse> list() {\n        return books.list().stream().map(BookResponse::from).toList();\n    }\n",
      "note": "`@GetMapping` sem caminho próprio atende `GET /books`. O método devolve uma lista de records e nunca menciona JSON; a próxima seção mostra quem o escreve."
    },
    {
      "code": "    @GetMapping(\"/{id}\")\n    public ResponseEntity<BookResponse> get(@PathVariable long id) {\n        return books.find(id)\n                .map(BookResponse::from)\n                .map(ResponseEntity::ok)\n                .orElse(ResponseEntity.notFound().build());\n    }",
      "note": "`{id}` é uma variável do modelo de caminho, e `@PathVariable` entrega o valor dela ao parâmetro de mesmo nome, convertido para `long`. `ResponseEntity` deixa o método escolher o status além do corpo: `ok` é 200 com o livro, `notFound().build()` é 404 sem corpo nenhum."
    },
    {
      "code": "}"
    }
  ]
}
```

## Compilar, rodar, perguntar

`-q` diz ao Maven para imprimir só avisos e erros, então um build que não imprime nada funcionou:

```
(pending build)
```

Inicie a aplicação num **segundo terminal** e deixe-a rodando ali. Daqui em diante, toda mudança no
código significa pará-la com Ctrl+C, compilar de novo e iniciá-la de novo.

```sh
java -jar target/bookshop-0.1.0.jar
```

De volta ao primeiro terminal, o **curl** é o cliente. Ele envia uma requisição e imprime a resposta:

```
(pending get-one)
```

Três opções, usadas a aula inteira. `-i` imprime a linha de status e os cabeçalhos antes do corpo.
`-s` impede o curl de imprimir qualquer coisa própria, como um medidor de progresso. `-w '\n'`
escreve uma quebra de linha depois da resposta, porque o JSON não termina com uma e o próximo prompt
começaria na mesma linha.

Leia a primeira resposta de cima para baixo. `HTTP/1.1 200` é o status; o Tomcat envia o número sem
frase depois dele, onde outros servidores escrevem `200 OK`. `Content-Type: application/json` diz que
o corpo é JSON, uma escolha que o Spring fez sem ninguém pedir. O corpo é o `BookResponse` do livro 1.

O livro 99 é um 404 com `Content-Length: 0`: o controlador achou um `Optional` vazio e devolveu
`notFound().build()`, que é um status e nenhum corpo.

Sem `-i`, o curl imprime só o corpo. A lista inteira é um array JSON, numa linha só:

```
(pending list)
```

## Respostas que você não escreveu

```
(pending not-mapped)
```

`DELETE /books/1` recebe **405** e um cabeçalho, `Allow: GET`. O Spring sabe que `/books/{id}` existe e
quais métodos ele atende, e diz isso. `/authors` recebe um 404, como o livro 99, mas este tem corpo:
nada está mapeado para esse caminho, então a requisição terminou no tratamento de erro do próprio
Spring Boot, que escreve `timestamp`, `status`, `error` e `path`.

Uma variável de caminho que não vira `long` é recusada antes de o método rodar:

```
(pending path-abc)
```

O segundo terminal diz por quê, numa linha que a aplicação registrou em `WARN`:

```
(pending path-abc-log)
```

Então já existem dois tipos de resposta de erro: as que o seu controlador decide, como o 404 vazio do
livro 99, e as que o Spring decide, com o corpo do Spring Boot. A aula 7 põe as duas num formato só,
que diz a um cliente o que deu errado. A próxima seção mostra de onde vêm as do Spring.
