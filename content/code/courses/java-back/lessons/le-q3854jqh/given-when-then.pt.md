---
title: Given, when, then
version: 1
---

Um teste com REST Assured se escreve em três cláusulas, e os nomes são métodos da própria
biblioteca. `given()` descreve a requisição: cabeçalhos, um corpo, credenciais. `when()` a envia,
com um método e um caminho. `then()` diz o que a resposta tem de ser, e **cada afirmação depois
dele é uma expectativa** que reprova o teste se a resposta discordar. A forma vem do
desenvolvimento guiado por comportamento, que a lição 21 apresenta direito; aqui ela é só um jeito
de ler um teste de cima para baixo.

Crie `src/test/java/com/example/bookshop/BooksApiIT.java` com dois testes. A seção seguinte
acrescenta mais dois.

```schooling-example
{
  "language": "java",
  "file": "BooksApiIT.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport static io.restassured.RestAssured.given;\nimport static org.hamcrest.Matchers.equalTo;\n\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\nimport org.springframework.boot.test.context.SpringBootTest.WebEnvironment;\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.context.annotation.Import;\nimport org.springframework.test.context.ActiveProfiles;\n",
      "note": "`given` é a porta de entrada do REST Assured, e `equalTo` é um matcher do Hamcrest, que o REST Assured usa em toda conferência de corpo. Os dois são importados de forma estática, para o teste se ler como uma frase."
    },
    {
      "code": "@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)\n@ActiveProfiles(\"test\")\n@Import(TestcontainersConfiguration.class)\nclass BooksApiIT {\n",
      "note": "As mesmas três anotações do `BookshopApplicationIT` da lição 19, com uma diferença: `RANDOM_PORT`. O perfil `test` fornece o segredo do JWT, e a `TestcontainersConfiguration` fornece o PostgreSQL."
    },
    {
      "code": "    @LocalServerPort\n    int port;\n\n    @BeforeEach\n    void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "`@LocalServerPort` injeta a porta que o Tomcat de fato pegou. O REST Assured envia para `localhost:8080` se ninguém disser outra coisa, então cada teste primeiro o aponta para esta. `RestAssured.port` é um campo estático, compartilhado por tudo na JVM, o que não faz mal enquanto uma classe de teste roda por vez."
    },
    {
      "code": "    @Test\n    void anyoneCanReadABook() {\n        given()\n            .accept(ContentType.JSON)",
      "note": "`given()`: a requisição, aqui só o cabeçalho `Accept`, dizendo que o teste quer JSON de volta."
    },
    {
      "code": "        .when()\n            .get(\"/books/{id}\", 1)",
      "note": "`when()`: o envio, o método e o caminho. `{id}` é preenchido com o argumento seguinte, já codificado, como uma variável de caminho do lado do servidor."
    },
    {
      "code": "        .then()\n            .statusCode(200)\n            .body(\"title\", equalTo(\"Dom Casmurro\"))\n            .body(\"author\", equalTo(\"Machado de Assis\"));\n    }",
      "note": "`then()`: o que a resposta tem de ser. `body(\"title\", …)` lê o campo `title` do JSON com uma expressão de caminho e o entrega ao matcher. Uma falha nomeia a expectativa que quebrou."
    },
    {
      "code": "\n    @Test\n    void anUnknownBookIsAProblemDetail() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 999)\n        .then()\n            .statusCode(404)\n            .contentType(\"application/problem+json\")\n            .body(\"title\", equalTo(\"Book not found\"));\n    }",
      "note": "O livro 999 não existe, e a lição 7 prometeu um problem detail para ele. O teste cobra essa promessa da API nos três pontos: o status, o tipo de mídia `application/problem+json` e o `title` que o tratador escreve."
    },
    {
      "code": "}"
    }
  ]
}
```

## Rodando um único teste de integração

`mvn verify` roda todos os testes, de unidade e de integração. Para rodar uma única classe de teste
de integração, dê o nome dela na propriedade `it.test`, que o failsafe lê. A saída de um build
inteiro é longa, então o `grep` guarda as linhas que interessam aqui:

```
ana@vm:~/bookshop$ mvn verify -Dit.test=BooksApiIT | grep -E 'Tomcat started|Started BooksApiIT|Tests run:.*BooksApiIT|BUILD'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2026-10-22T20:24:29.074-03:00  INFO 23319 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 41725 (http) with context path '/'
2026-10-22T20:24:29.079-03:00  INFO 23319 --- [bookshop] [           main] [] com.example.bookshop.BooksApiIT          : Started BooksApiIT in 6.12 seconds (process running for 6.92)
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 7.630 s -- in com.example.bookshop.BooksApiIT
[INFO] BUILD SUCCESS
```

As duas linhas `OpenJDK 64-Bit Server VM warning` aparecem primeiro porque passam por fora do
`grep`: a JVM as escreve na saída de erro, e um pipe só carrega a saída padrão. Cada JVM de teste
imprime uma, a do surefire e depois a do failsafe, porque o agente do Mockito da lição 19 põe uma
classe própria no boot class path. Elas não dizem nada sobre estes testes.

Depois leia o resto de cima para baixo. `Tomcat started on port` dá uma porta que ninguém escolheu:
o número muda a cada execução, e o teste só a conhece pelo `@LocalServerPort`. `Started BooksApiIT`
é a aplicação subindo dentro da JVM do teste, no tempo que um contexto e um contêiner PostgreSQL
levam. Depois os dois testes rodaram na mesma classe, contra o mesmo servidor.

`-Dit.test` restringe o failsafe e nada mais. Os testes de unidade das lições 18 e 19 rodaram
antes destes, no surefire, que é o primeiro dos dois avisos.

## Um teste que falha, lido

Antes de confiar no teste, veja o que ele diz quando falha. Como desvio, ponha uma expectativa errada no segundo
teste: a crença de que uma resposta de erro é `application/json`, como toda outra resposta da
livraria.

```
ana@vm:~/bookshop$ sed -i 's|"application/problem+json"|"application/json"|' src/test/java/com/example/bookshop/BooksApiIT.java
ana@vm:~/bookshop$ mvn verify -Dit.test=BooksApiIT | grep -A9 '<<< FAILURE'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 7.330 s <<< FAILURE! -- in com.example.bookshop.BooksApiIT
[ERROR] com.example.bookshop.BooksApiIT.anUnknownBookIsAProblemDetail -- Time elapsed: 0.796 s <<< FAILURE!
java.lang.AssertionError: 
1 expectation failed.
Expected content-type "application/json" doesn't match actual content-type "application/problem+json".

	at io.restassured.internal.ResponseSpecificationImpl$HamcrestAssertionClosure.validate(ResponseSpecificationImpl.groovy:527)
	at io.restassured.internal.ResponseSpecificationImpl.validateResponseIfRequired(ResponseSpecificationImpl.groovy:725)
	at io.restassured.internal.ResponseSpecificationImpl.contentType(ResponseSpecificationImpl.groovy:458)
	at io.restassured.internal.ValidatableResponseOptionsImpl.contentType(ValidatableResponseOptionsImpl.java:226)
	at com.example.bookshop.BooksApiIT.anUnknownBookIsAProblemDetail(BooksApiIT.java:50)
```

**`1 expectation failed.`** é o relatório do próprio REST Assured, e a linha de baixo diz
exatamente qual expectativa falhou e o que veio no lugar. O servidor respondeu
`application/problem+json`, como a lição 7 o fez, e um cliente que confere o tipo de mídia antes de
interpretar o corpo teria tratado essa resposta de forma diferente de um livro. Essa diferença é o
que o teste existe para proteger.

O stack trace abaixo se lê de dentro para fora. As quatro linhas `io.restassured` são a biblioteca,
e três delas apontam arquivos `.groovy`: o REST Assured é escrito em parte no Groovy que a árvore
de dependências mostrou. A última linha é sua: `BooksApiIT.java:50` é a linha da expectativa
`contentType`, não a da requisição, então um teste que falha aponta a afirmação que quebrou.

Ponha a expectativa de volta:

```
ana@vm:~/bookshop$ sed -i 's|contentType("application/json")|contentType("application/problem+json")|' src/test/java/com/example/bookshop/BooksApiIT.java
ana@vm:~/bookshop$ mvn verify -Dit.test=BooksApiIT | grep -E 'Tests run:.*BooksApiIT|BUILD'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 7.910 s -- in com.example.bookshop.BooksApiIT
[INFO] BUILD SUCCESS
```
