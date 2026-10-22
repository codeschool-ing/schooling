---
title: Problem details, um formato para todo erro
version: 1
---

Uma resposta de erro tem dois leitores. Uma pessoa a lê uma vez, depurando. Um programa a lê toda vez,
para decidir o que fazer em seguida: pôr uma mensagem ao lado de um campo do formulário, pedir outro
ISBN, tentar de novo mais tarde. O programa precisa de todo erro no mesmo formato, com um campo que ele
possa comparar e que não mude quando alguém reescreve uma frase. **A RFC 9457, "Problem Details for HTTP
APIs"**, é esse formato. Ela substituiu a RFC 7807 em 2023 e mudou pouco, e é por isso que os dois
números ainda aparecem em documentação.

Um documento de problema é um objeto JSON enviado com o media type **`application/problem+json`**. A RFC
define cinco membros, todos opcionais:

| membro | o que guarda |
|---|---|
| `type` | uma URI que dá nome ao tipo de problema, e o membro que um programa compara. Ausente, significa `about:blank`: nenhum tipo além do próprio código de status |
| `title` | um resumo curto do tipo, o mesmo toda vez que esse tipo ocorre |
| `status` | o código de status HTTP, repetido no corpo |
| `detail` | uma explicação desta ocorrência, escrita para uma pessoa |
| `instance` | uma URI para esta ocorrência |

Um problema pode trazer membros próprios também, que a RFC chama de extensões. A livraria acrescenta um
para erros de validação, duas seções adiante.

O erro comum é um cliente que lê o `detail`. "No book has id 99" foi escrito para uma pessoa, e no dia
em que for reescrito como "Book 99 does not exist", todo cliente que comparava as palavras quebra sem
erro em lugar nenhum. **O `type` é o contrato.** É uma URI porque uma URI é um nome que ninguém mais
escolhe por acaso, e ela não precisa abrir nada, embora uma página nesse endereço explicando o problema
seja uma gentileza com quem lê.

## Uma classe para todos os controllers

A classe do Spring para o documento é a **`ProblemDetail`**, e um handler que devolve uma tem a resposta
escrita como `application/problem+json`. Quem escolhe o handler é a `@ExceptionHandler`: um método com
ela responde às exceções que ela nomeia. Escrito dentro de um controller, ele responde às exceções daquele
controller e de nenhum outro. Escrito numa classe anotada com **`@RestControllerAdvice`**, ele responde a
elas em todos os controllers da aplicação, e é isso que "global" quer dizer no título desta aula.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"Um diagrama de sequência com cinco linhas de vida: cliente, DispatcherServlet, BookController, BookService e ApiErrorHandler. O cliente envia GET /books/99; o DispatcherServlet chama BookController.get, que chama BookService.get. O serviço lança BookNotFoundException, que volta pelo controller até o DispatcherServlet. O DispatcherServlet acha o handler dela e chama ApiErrorHandler.notFound, que devolve um ProblemDetail com status 404, e o cliente recebe 404 com application/problem+json.\"><defs><marker id=\"flw-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"flw-x\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><line x1=\"70\" y1=\"50\" x2=\"70\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"30.0\" y=\"18\" width=\"80\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><line x1=\"225\" y1=\"50\" x2=\"225\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"163.0\" y=\"18\" width=\"124\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DispatcherServlet</text><line x1=\"365\" y1=\"50\" x2=\"365\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"313.0\" y=\"18\" width=\"104\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"365\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookController</text><line x1=\"505\" y1=\"50\" x2=\"505\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"463.0\" y=\"18\" width=\"84\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookService</text><line x1=\"635\" y1=\"50\" x2=\"635\" y2=\"325\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><rect x=\"580.0\" y=\"18\" width=\"110\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ApiErrorHandler</text><line x1=\"70\" y1=\"82\" x2=\"222\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"147.5\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /books/99</text><line x1=\"225\" y1=\"118\" x2=\"362\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"295.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">get(99)</text><line x1=\"365\" y1=\"154\" x2=\"502\" y2=\"154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"435.0\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">get(99)</text><line x1=\"505\" y1=\"196\" x2=\"228\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#flw-x)\"></line><text x=\"365.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">lança BookNotFoundException</text><text x=\"233\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acha o handler dela</text><line x1=\"225\" y1=\"250\" x2=\"632\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"430.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notFound(e)</text><line x1=\"635\" y1=\"284\" x2=\"228\" y2=\"284\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"430.0\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ProblemDetail, 404</text><line x1=\"225\" y1=\"316\" x2=\"73\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw-a)\"></line><text x=\"147.5\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 problem+json</text></svg>", "caption": "O controller nunca vê o erro como erro: a exceção passa por ele, e o DispatcherServlet procura um handler que a nomeie."}
```

Crie `src/main/java/com/example/bookshop/web/ApiErrorHandler.java`:

```schooling-example
{"language": "java", "file": "ApiErrorHandler.java", "parts": [{"code": "package com.example.bookshop.web;\n\nimport java.net.URI;\nimport java.util.Map;\nimport java.util.TreeMap;\n\nimport org.springframework.http.HttpHeaders;\nimport org.springframework.http.HttpStatus;\nimport org.springframework.http.HttpStatusCode;\nimport org.springframework.http.ProblemDetail;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.MethodArgumentNotValidException;\nimport org.springframework.web.bind.annotation.ExceptionHandler;\nimport org.springframework.web.bind.annotation.RestControllerAdvice;\nimport org.springframework.web.context.request.WebRequest;\nimport org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;\n\nimport com.example.bookshop.catalogue.BookNotFoundException;\nimport com.example.bookshop.catalogue.DuplicateIsbnException;\n", "note": "`ProblemDetail` é a classe do Spring para o documento da RFC. As duas exceções vêm de `catalogue`: a camada web conhece as exceções da loja, e a loja não sabe nada da web."}, {"code": "@RestControllerAdvice\npublic class ApiErrorHandler extends ResponseEntityExceptionHandler {\n", "note": "`@RestControllerAdvice` faz da classe um bean cujos handlers valem para todos os controllers, e escreve o que eles devolvem como corpo da resposta. Estender `ResponseEntityExceptionHandler` traz os handlers do próprio Spring, assunto da próxima seção."}, {"code": "    @ExceptionHandler(BookNotFoundException.class)\n    public ProblemDetail notFound(BookNotFoundException e) {\n        return problem(HttpStatus.NOT_FOUND, \"book-not-found\", \"Book not found\", e.getMessage());\n    }\n\n    @ExceptionHandler(DuplicateIsbnException.class)\n    public ProblemDetail duplicate(DuplicateIsbnException e) {\n        return problem(HttpStatus.CONFLICT, \"duplicate-isbn\", \"Duplicate ISBN\", e.getMessage());\n    }\n", "note": "Um método por exceção. `@ExceptionHandler` diz qual exceção o método responde, e o status dentro do documento devolvido vira o status da resposta."}, {"code": "    @Override\n    protected ResponseEntity<Object> handleMethodArgumentNotValid(\n            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {\n        Map<String, String> errors = new TreeMap<>();\n        e.getBindingResult().getFieldErrors()\n                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));\n        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, \"invalid-request\", \"Invalid request\",\n                errors.size() + \" field(s) failed validation\");\n        body.setProperty(\"errors\", errors);\n        return ResponseEntity.badRequest().body(body);\n    }\n", "note": "Falhas de validação, com uma entrada por campo. A seção depois da próxima lê este método linha a linha."}, {"code": "    private static ProblemDetail problem(HttpStatus status, String type, String title, String detail) {\n        ProblemDetail body = ProblemDetail.forStatusAndDetail(status, detail);\n        body.setType(URI.create(\"https://bookshop.example/problems/\" + type));\n        body.setTitle(title);\n        return body;\n    }\n}", "note": "Todo problema é montado aqui, então o formato não tem como variar de um handler para outro. `forStatusAndDetail` preenche `status` e `detail`. O `type` é uma URI no domínio da própria loja, uma por tipo de problema, e o `title` dá nome ao tipo."}]}
```

Compile, reinicie a aplicação e peça de novo o livro 99 e um segundo Dom Casmurro:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/99 -w '\n'
HTTP/1.1 404 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT

{"detail":"No book has id 99","instance":"/books/99","status":404,"title":"Book not found","type":"https://bookshop.example/problems/book-not-found"}
ana@vm:~/bookshop$ curl -si localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "title": "Dom Casmurro", "author": "Machado de Assis", "priceCents": 3990}' -w '\n'
HTTP/1.1 409 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Fri, 16 Oct 2026 23:42:38 GMT

{"detail":"A book with ISBN 9786500000016 is already in the catalogue","instance":"/books","status":409,"title":"Duplicate ISBN","type":"https://bookshop.example/problems/duplicate-isbn"}
```

Leia a primeira resposta de cima para baixo. A linha de status diz 404 sem frase depois do número: o
Tomcat 11 não envia nenhuma, o que o HTTP/1.1 permite, já que o cliente age pelo número. O `Content-Type:
application/problem+json` está ali porque o handler devolveu uma `ProblemDetail`. No corpo, `type`,
`title` e `detail` são os três que o handler preencheu, e o `status` veio do `forStatusAndDetail`. Nada
na livraria preencheu o `instance`: o Spring o preencheu com o caminho da requisição, `/books/99`, porque
o handler o deixou vazio.

A segunda resposta é um **409**, Conflict, e não um 400. A requisição estava bem formada e todo campo
dela era válido. O conflito é com o estado do catálogo, e a mesma requisição com outro ISBN teria dado
certo. A aula 1 de `apis` percorre os códigos de status e quando cada um se aplica.
