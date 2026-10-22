---
title: Um token, dentro de um teste
version: 1
---

Quase toda a livraria está atrás da segurança da lição 15. Ler o catálogo é livre, mas cadastrar
um livro exige o escopo `catalogue:write` e um pedido exige `orders`, e os dois só vêm num JWT que
`/auth/token` entrega em troca de um usuário e uma senha. Um teste de API de um pedido, portanto,
tem de fazer o que um cliente faz: **pedir um token, e depois usá-lo.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Uma sequência entre o teste e a livraria. Primeiro o teste faz POST em /auth/token com credenciais HTTP Basic; a primeira cadeia de filtros as confere e a resposta é 200 com um accessToken. O teste extrai o token. Depois faz POST em /orders com Authorization: Bearer e o token; a segunda cadeia de filtros verifica o JWT e a resposta é 201 com o pedido, cujo cliente é ana.\"><defs><marker id=\"l20t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"15\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o teste</text><rect x=\"490\" y=\"15\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a livraria</text><polyline points=\"110,51 110,315\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 4\"></polyline><polyline points=\"560,51 560,315\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 4\"></polyline><text x=\"335\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /auth/token</text><text x=\"335\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Authorization: Basic YW5hOmFuYS1yZWFkcy1ib29rcw==</text><polyline points=\"110,98 558,98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"568\" y=\"84\" width=\"125\" height=\"28\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cadeia 1: HTTP Basic</text><text x=\"335\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"accessToken\": \"eyJ…\", …}</text><polyline points=\"560,132 112,132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"15\" y=\"150\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">extract().path(\"accessToken\")</text><text x=\"110\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guardado numa variável local</text><text x=\"335\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /orders</text><text x=\"335\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><polyline points=\"110,248 558,248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"568\" y=\"234\" width=\"125\" height=\"28\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cadeia 2: JWT</text><text x=\"335\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201 {\"customer\": \"ana\", …}</text><polyline points=\"560,284 112,284\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline></svg>", "caption": "Duas requisições, e a segunda não pode ser escrita antes de a primeira responder: o token é lido de uma resposta e enviado na requisição seguinte."}
```

Um atalho tentador é desligar a segurança no perfil de teste, ou montar um token à mão com o
segredo que o teste já conhece. Os dois testam uma aplicação diferente da que vai para produção. O
primeiro nunca executa as cadeias de filtros; o segundo as executa contra um token que o controller
de token não fez, então um defeito nas claims que ele escreve, como um escopo que ele esquece, passa.
Passar por `/auth/token` custa uma requisição e testa as duas metades.

Substitua o `BooksApiIT.java` por esta versão. Ela mantém os dois testes da seção anterior e
acrescenta dois.

```schooling-example
{
  "language": "java",
  "file": "BooksApiIT.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport static io.restassured.RestAssured.given;\nimport static org.hamcrest.Matchers.equalTo;\nimport static org.hamcrest.Matchers.hasSize;\n\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\nimport org.springframework.boot.test.context.SpringBootTest.WebEnvironment;\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.context.annotation.Import;\nimport org.springframework.test.context.ActiveProfiles;\n",
      "note": "Um import é novo: `hasSize`, um matcher do Hamcrest para o tamanho de uma lista."
    },
    {
      "code": "@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)\n@ActiveProfiles(\"test\")\n@Import(TestcontainersConfiguration.class)\nclass BooksApiIT {\n\n    @LocalServerPort\n    int port;\n\n    @BeforeEach\n    void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "Igual à seção anterior."
    },
    {
      "code": "    @Test\n    void anyoneCanReadABook() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 1)\n        .then()\n            .statusCode(200)\n            .body(\"title\", equalTo(\"Dom Casmurro\"))\n            .body(\"author\", equalTo(\"Machado de Assis\"));\n    }\n\n    @Test\n    void anUnknownBookIsAProblemDetail() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 999)\n        .then()\n            .statusCode(404)\n            .contentType(\"application/problem+json\")\n            .body(\"title\", equalTo(\"Book not found\"));\n    }\n",
      "note": "Os dois testes da seção anterior, sem mudança."
    },
    {
      "code": "    @Test\n    void addingABookNeedsAToken() {\n        given()\n            .contentType(ContentType.JSON)\n            .body(\"\"\"\n                {\"isbn\": \"9786500000078\", \"title\": \"Emma\", \"author\": \"Jane Austen\",\n                 \"priceCents\": 3300, \"stock\": 3}\"\"\")\n        .when()\n            .post(\"/books\")\n        .then()\n            .statusCode(401);\n    }\n",
      "note": "Um livro válido, enviado sem credencial nenhuma. A expectativa é 401, não 400 nem 201: a cadeia de filtros de segurança recusa a requisição antes que o controller entre em cena, então a validação não roda e o livro não é gravado."
    },
    {
      "code": "    @Test\n    void aCustomerWithATokenCanPlaceAnOrder() {\n        String token =\n            given()\n                .auth().preemptive().basic(\"ana\", \"ana-reads-books\")\n            .when()\n                .post(\"/auth/token\")\n            .then()\n                .statusCode(200)\n                .extract().path(\"accessToken\");\n",
      "note": "A primeira requisição pede um token, com a senha de ana em HTTP Basic. `preemptive()` envia as credenciais já na primeira tentativa, em vez de esperar o servidor pedir. `extract().path(\"accessToken\")` traz um campo da resposta de volta para o Java, depois que as expectativas acima dele passaram."
    },
    {
      "code": "        given()\n            .auth().oauth2(token)\n            .contentType(ContentType.JSON)\n            .body(\"\"\"\n                {\"lines\": [{\"bookId\": 2, \"quantity\": 1}]}\"\"\")\n        .when()\n            .post(\"/orders\")\n        .then()\n            .statusCode(201)\n            .body(\"customer\", equalTo(\"ana\"))\n            .body(\"lines\", hasSize(1))\n            .body(\"totalCents\", equalTo(2950));\n    }",
      "note": "A segunda requisição leva o token. `auth().oauth2(token)` é o nome que o REST Assured dá ao cabeçalho `Authorization: Bearer` seguido do token, que é o que o resource server da lição 15 lê. `lines` é um array JSON, e `hasSize(1)` confere o tamanho dele; o livro 2 custa 2950 centavos, então um exemplar é o total."
    },
    {
      "code": "}"
    }
  ]
}
```

O token mora numa variável local do único teste que precisa dele. Não é um campo compartilhado
pela classe, porque um teste que depende de outro ter rodado antes passa ou falha conforme a ordem
que o JUnit resolver usar.

## O build inteiro

`mvn verify` sem propriedade nenhuma roda todos os testes do projeto. O `grep` guarda as linhas
que contam a história dos testes de integração:

```
ana@vm:~/bookshop$ mvn verify | grep -E 'postgres:16-alpine started|Tomcat started|Tests run:.*IT$|BUILD'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2026-10-22T20:13:45.180-03:00  INFO 30360 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.448122278S
2026-10-22T20:13:50.006-03:00  INFO 30360 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.449991375S
2026-10-22T20:13:53.714-03:00  INFO 30360 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.418075091S
2026-10-22T20:13:54.195-03:00  INFO 30360 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 42599 (http) with context path '/'
[INFO] BUILD SUCCESS
```

As três linhas `Tests run` somam sete testes de integração, quatro deles desta lição, e todos passaram. Mas conte os contêineres: **três contêineres PostgreSQL para três classes de
teste.** O `BookRepositoryIT` declara o seu, como a lição 19 o escreveu. As outras duas importam a
`TestcontainersConfiguration`, onde o contêiner é um bean, e um bean vive num contexto da
aplicação. O `BookshopApplicationIT` roda num contexto `MOCK` e o `BooksApiIT` num `RANDOM_PORT`; o
Spring guarda um contexto em cache e o reaproveita para toda classe de teste que pede a mesma
configuração, e estas duas pedem configurações diferentes. Então o segundo contexto sobe um segundo
contêiner. Cada um custa o segundo e pouco que as linhas mostram, e num projeto com dezenas de
classes de teste, manter as configurações idênticas é o que mantém a suíte rápida.

## O que estes quatro testes deixam para trás

O teste de pedido fez um pedido de verdade, e o banco naquele contêiner agora o guarda, com o
estoque do livro 2 um exemplar menor. Nada mais nesta classe lê estoque, então ninguém percebe. Um
teste escrito depois que espere o estoque da migração passaria sozinho e falharia ao lado deste, que
é o tipo de falha que só aparece no servidor de build. Dois hábitos a mantêm longe: afirmar sobre o
que o seu próprio teste criou em vez de totais, e dar a um teste que precisa de um estado conhecido
os seus próprios dados. A lição 3 de `testing-cicd` trata de fixtures e conjuntos de dados de teste
direito.
