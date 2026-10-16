---
title: Tirando um valor de uma resposta para a próxima requisição
version: 1
---

**Um cliente de verdade nunca manda uma requisição sozinha.** Ele pede um token, manda o token com
um pedido e lê o pedido de volta no endereço que a resposta lhe deu. Um teste desse fluxo tem de
fazer o mesmo, o que significa tirar um valor de uma resposta e colocá-lo na próxima requisição.
`extract()` é a chamada que faz isso: encerra as verificações do `then()` e devolve um valor em vez
de mais verificações.

Salve como `restassured/src/test/java/boxoffice/OrdersTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.startsWith;

import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class OrdersTest {

    static final String BASE = "http://localhost:8080";
    static String token;

    @BeforeAll
    static void askForAToken() {
        token = given()
            .baseUri(BASE)
            .formParam("grant_type", "client_credentials")
            .formParam("client_id", "ci-tests")
            .formParam("client_secret", "ci-secret")
        .when()
            .post("/oauth/token")
        .then()
            .statusCode(200)
            .body("token_type", equalTo("Bearer"))
            .extract().path("access_token");
    }

    @Test
    void anOrderCanBeReadBack() {
        Response created = given()
            .baseUri(BASE)
            .auth().oauth2(token)
            .contentType(ContentType.JSON)
            .body("""
                {"show_id": "sh-101", "seats": 2}
                """)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(201)
            .header("location", startsWith("/v1/orders/ord-"))
            .body("total_cents", equalTo(16000))
            .extract().response();

        String id = created.path("id");
        String location = created.header("location");

        given()
            .baseUri(BASE)
            .auth().oauth2(token)
        .when()
            .get(location)
        .then()
            .statusCode(200)
            .body("id", equalTo(id))
            .body("seats", equalTo(2))
            .body("status", equalTo("confirmed"));
    }

    @Test
    void noTokenIs401AndSaysWhy() {
        given()
            .baseUri(BASE)
            .contentType(ContentType.JSON)
            .body("""
                {"show_id": "sh-101", "seats": 2}
                """)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(401)
            .header("www-authenticate", containsString("no bearer token"));
    }

    @Test
    void sevenSeatsAreRefused() {
        given()
            .baseUri(BASE)
            .auth().oauth2(token)
            .contentType(ContentType.JSON)
            .body("""
                {"show_id": "sh-101", "seats": 7}
                """)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(422)
            .body("detail", equalTo("seats must be a whole number from 1 to 6"));
    }
}
```

## O token, uma vez para a classe

`askForAToken` está marcado com `@BeforeAll`, então o JUnit o roda **uma vez, antes de qualquer
teste da classe**, e ele é `static` porque roda antes de existir qualquer outra coisa sobre a qual
rodar. É a requisição de token da lição 3 escrita em Java: `formParam` manda os campos como
formulário, do jeito que o `curl -d` fazia, e a resposta é conferida como qualquer outra antes de
se tirar algo dela. Depois `.extract().path("access_token")` lê um campo e o devolve, e o campo
estático `token` o guarda para os testes abaixo.

Conferir antes de extrair é o motivo da ordem. **Um token tirado de um `401` é `null`**, e todo
teste depois dele falha com uma mensagem sobre pedidos, longe da causa; um `statusCode(200)` antes
do `extract()` faz a falha dizer o que realmente deu errado.

## Um pedido, e o pedido lido de volta

`anOrderCanBeReadBack` faz três movimentos:

1. `auth().oauth2(token)` acrescenta `Authorization: Bearer` e o token, o cabeçalho que a lição 3
   montou à mão, e `contentType(ContentType.JSON)` rotula o corpo, que a lição 1 mostrou que o
   boxoffice recusa com `415` se não vier rotulado.
2. O corpo é um **bloco de texto**, o jeito do Java de escrever texto em várias linhas entre marcas
   `"""`. O JSON dentro dele é exatamente o que o curl mandou na lição 1.
3. `.extract().response()` guarda a resposta inteira em vez de um campo, porque o teste precisa de
   duas coisas dela: o `id` do corpo e o cabeçalho `location`. O `GET` seguinte vai para esse
   `location`, então o teste também confere que o endereço que o servidor deu funciona, que é uma
   das perguntas que a lição 1 mandou fazer a um `201`.

Os outros dois testes perguntam o que o servidor recusa: um pedido sem token, que tem de ser um
`401` que diz o motivo em `www-authenticate`, e sete lugares, um a mais do que a regra permite.

## O que o servidor viu

Rode a classe:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=OrdersTest
```

Silêncio de novo, então os três passaram. O terminal do próprio boxoffice mostra o que eles
mandaram, uma linha por requisição:

```
POST /oauth/token 200
POST /v1/orders 401
POST /v1/orders 422
POST /v1/orders 201
GET /v1/orders/ord-1001 200
```

Um token, pedido uma vez, como o `@BeforeAll` prometeu. Depois as requisições dos três testes, e
**não na ordem em que o arquivo os lista**: o JUnit escolhe uma ordem própria, estável de uma
execução para outra e diferente da do arquivo. Um teste que só passa quando outro rodou antes é um
defeito nos testes, e a lição 12 mostra como um deles se esconde.

Cada execução desta classe compra dois lugares do `sh-101`, que tem 120, então a 61ª execução
seguida é recusada com `409`. Reiniciar o boxoffice devolve todos os lugares. O espetáculo pequeno,
`sh-103`, esgotaria em duas execuções, e é por isso que nenhum destes testes o compra.
