---
title: Specifications, for what every test repeats
version: 1
---

**Copying the same three lines into every test feels harmless until one of them changes.** The
order tests of section 05 each name the address of boxoffice, each attach the token, each label
the body as JSON. Point them at another server, on another port or in a pipeline, and every copy
has to change, and the one that was missed sends its request somewhere else. A
**specification** is REST Assured's answer: a piece of a request, or a set of checks on a
response, built once and used by name.

## One place for what the tests share

Save it as `restassured/src/test/java/boxoffice/Api.java`:

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

Four things live there now, each written once:

- **`BASE`, the address.** `System.getProperty("boxoffice.url", …)` reads a value given on the
  command line as `-Dboxoffice.url=…` and falls back to `http://localhost:8080` when there is
  none. The tests no longer know where the server is; whoever runs them says so.
- **`ANYONE`, a request spec** with that address and one setting: when a check fails, REST
  Assured prints the whole request and the whole response. When every check passes it prints
  nothing. Section 07 shows what that buys.
- **`PROBLEM`, a response spec**: every error boxoffice sends is `application/problem+json`
  with `type` set to `about:blank`, the shape lesson 2 described. A test that expects an error
  adds `.spec(Api.PROBLEM)` and checks the shape without repeating it.
- **`as(clientId, secret)`**, which asks for a token and returns a spec carrying it, together
  with the address and the JSON label. It uses `ANYONE` for the token request itself, so even
  that request is logged if it fails.

The class is `final` with a `private` constructor, the Java way of saying it holds shared values
and is never itself a thing to create.

## The order tests, using it

The same tests as section 05, and one more, replacing the old file. Save it as `restassured/src/test/java/boxoffice/OrdersTest.java`:

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

`.spec(ci)` in `given()` brings in the address, the token and the label at once, and what is
left in each test is what makes it different from the others. The new test signs in as
`auditor`, lesson 3's client that may read and not buy, and expects `403` with
`insufficient_scope`: a row of lesson 3's matrix of who may do what, now a test that runs on
every build.

`noTokenIs401AndSaysWhy` uses `Api.ANYONE`, the spec with no token. It no longer sends a body
either, and still gets its `401`: boxoffice checks the token before it reads anything, which is
what a server should do, and the test now shows that it does.

## The same tests, another server

Start a second boxoffice on port 8081 in a third terminal, from `~/boxoffice`, with
`PORT=8081 node boxoffice.mjs`, and point the order tests at it:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=OrdersTest -Dboxoffice.url=http://localhost:8081
```

Silent, so they passed, and the second server's terminal says it was the one asked:

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

That command line is how lesson 6's pipeline would run these tests against a server that is not
on your laptop: the address is an argument, and no file changes. Stop the second boxoffice with
Ctrl-C before going on.

`HealthTest` and `ShowsTest` still write `http://localhost:8080` themselves, as sections 03 and 04
left them, so they would ignore `-Dboxoffice.url`. The drill asks what moving them takes.
