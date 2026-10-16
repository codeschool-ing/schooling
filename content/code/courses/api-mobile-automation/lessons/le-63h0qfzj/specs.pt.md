---
title: Especificações, para o que todo teste repete
version: 1
---

**Copiar as mesmas três linhas em todo teste parece inofensivo até uma delas mudar.** Os testes de
pedidos da seção 05 citam cada um o endereço do boxoffice, anexam cada um o token, rotulam cada um o
corpo como JSON. Aponte-os para outro servidor, em outra porta ou num pipeline, e toda cópia tem de
mudar, e a que ficou esquecida manda a requisição para outro lugar. Uma **especificação** é a
resposta do REST Assured: um pedaço de uma requisição, ou um conjunto de verificações sobre uma
resposta, montado uma vez e usado pelo nome.

## Um lugar para o que os testes compartilham

Salve como `restassured/src/test/java/boxoffice/Api.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static io.restassured.RestAssured.oauth2;

import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.config.LogConfig;
import io.restassured.config.RestAssuredConfig;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;

// What every test of boxoffice shares: where it is, how to log, how to sign in.
final class Api {

    static final String BASE = System.getProperty("boxoffice.url", "http://localhost:8080");

    // Print the request and the response, but only for a check that failed.
    static final RestAssuredConfig LOG_ON_FAILURE = RestAssuredConfig.config()
        .logConfig(LogConfig.logConfig().enableLoggingOfRequestAndResponseIfValidationFails());

    static final RequestSpecification ANYONE = new RequestSpecBuilder()
        .setBaseUri(BASE)
        .setConfig(LOG_ON_FAILURE)
        .build();

    // Every error boxoffice sends has this shape.
    static final ResponseSpecification PROBLEM = new ResponseSpecBuilder()
        .expectContentType("application/problem+json")
        .expectBody("type", org.hamcrest.Matchers.equalTo("about:blank"))
        .build();

    // A spec that carries a fresh token for one client, and sends JSON.
    static RequestSpecification as(String clientId, String secret) {
        String token = given()
            .spec(ANYONE)
            .formParam("grant_type", "client_credentials")
            .formParam("client_id", clientId)
            .formParam("client_secret", secret)
        .when()
            .post("/oauth/token")
        .then()
            .statusCode(200)
            .extract().path("access_token");

        return new RequestSpecBuilder()
            .addRequestSpecification(ANYONE)
            .setAuth(oauth2(token))
            .setContentType(ContentType.JSON)
            .build();
    }

    private Api() {
    }
}
```

Quatro coisas moram ali agora, cada uma escrita uma vez:

- **`BASE`, o endereço.** `System.getProperty("boxoffice.url", …)` lê um valor passado na linha de
  comando como `-Dboxoffice.url=…` e cai para `http://localhost:8080` quando não há nenhum. Os
  testes não sabem mais onde o servidor está; quem os roda é que diz.
- **`ANYONE`, uma especificação de requisição** com esse endereço e um ajuste: quando uma
  verificação falha, o REST Assured imprime a requisição inteira e a resposta inteira. Quando todas
  passam, não imprime nada. A seção 07 mostra o que isso compra.
- **`PROBLEM`, uma especificação de resposta**: todo erro que o boxoffice manda é
  `application/problem+json` com `type` igual a `about:blank`, a forma que a lição 2 descreveu. Um
  teste que espera um erro acrescenta `.spec(Api.PROBLEM)` e confere a forma sem repeti-la.
- **`as(clientId, secret)`**, que pede um token e devolve uma especificação que o carrega, junto
  com o endereço e o rótulo de JSON. Ela usa `ANYONE` para a própria requisição de token, então até
  essa requisição é registrada se falhar.

A classe é `final` com um construtor `private`, o jeito do Java de dizer que ela guarda valores
compartilhados e nunca é, ela mesma, algo a ser criado.

## Os testes de pedidos, usando-a

Os mesmos testes da seção 05, e mais um, no lugar do arquivo antigo. Salve como `restassured/src/test/java/boxoffice/OrdersTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.startsWith;

import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class OrdersTest {

    static RequestSpecification ci;
    static RequestSpecification auditor;

    @BeforeAll
    static void signIn() {
        ci = Api.as("ci-tests", "ci-secret");
        auditor = Api.as("auditor", "auditor-secret");
    }

    @Test
    void anOrderCanBeReadBack() {
        Response created = given()
            .spec(ci)
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

        given()
            .spec(ci)
        .when()
            .get(created.header("location"))
        .then()
            .statusCode(200)
            .body("id", equalTo(id))
            .body("seats", equalTo(2))
            .body("status", equalTo("confirmed"));
    }

    @Test
    void noTokenIs401AndSaysWhy() {
        given()
            .spec(Api.ANYONE)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(401)
            .spec(Api.PROBLEM)
            .header("www-authenticate", containsString("no bearer token"));
    }

    @Test
    void sevenSeatsAreRefused() {
        given()
            .spec(ci)
            .body("""
                {"show_id": "sh-101", "seats": 7}
                """)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(422)
            .spec(Api.PROBLEM)
            .body("detail", equalTo("seats must be a whole number from 1 to 6"));
    }

    @Test
    void theAuditorMayReadButNotBuy() {
        given()
            .spec(auditor)
            .body("""
                {"show_id": "sh-101", "seats": 1}
                """)
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(403)
            .spec(Api.PROBLEM)
            .header("www-authenticate", containsString("insufficient_scope"));
    }
}
```

`.spec(ci)` no `given()` traz o endereço, o token e o rótulo de uma vez, e o que sobra em cada teste
é o que o diferencia dos outros. O teste novo entra como `auditor`, o cliente da lição 3 que pode
ler e não pode comprar, e espera `403` com `insufficient_scope`: uma linha da matriz da lição 3 de
quem pode fazer o quê, agora um teste que roda em todo build.

`noTokenIs401AndSaysWhy` usa `Api.ANYONE`, a especificação sem token. Ele também não manda mais
corpo, e ainda recebe o seu `401`: o boxoffice confere o token antes de ler qualquer coisa, que é o
que um servidor deve fazer, e agora o teste mostra que ele faz.

## Os mesmos testes, outro servidor

Inicie um segundo boxoffice na porta 8081 num terceiro terminal, a partir de `~/boxoffice`, com
`PORT=8081 node boxoffice.mjs`, e aponte os testes de pedidos para ele:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=OrdersTest -Dboxoffice.url=http://localhost:8081
```

Silêncio, então passaram, e o terminal do segundo servidor diz que foi ele o consultado:

```
boxoffice listening on http://localhost:8081
POST /oauth/token 200
POST /oauth/token 200
POST /v1/orders 403
POST /v1/orders 401
POST /v1/orders 422
POST /v1/orders 201
GET /v1/orders/ord-1001 200
```

Essa linha de comando é como o pipeline da lição 6 rodaria estes testes contra um servidor que não
está no seu notebook: o endereço é um argumento, e nenhum arquivo muda. Pare o segundo boxoffice
com Ctrl-C antes de continuar.

`HealthTest` e `ShowsTest` ainda escrevem `http://localhost:8080` eles mesmos, como as seções 03 e
04 os deixaram, então ignorariam o `-Dboxoffice.url`. A prática final pergunta o que é preciso para
mudá-los.
