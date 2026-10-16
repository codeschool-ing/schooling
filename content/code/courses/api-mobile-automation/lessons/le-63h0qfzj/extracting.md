---
title: Taking a value out of one answer for the next request
version: 1
---

**A real client never sends one request alone.** It asks for a token, sends the token with an
order, and reads the order back from the address the answer gave it. A test of that flow has to
do the same, which means taking a value out of a response and putting it into the next request.
`extract()` is the call that does it: it ends the checks of `then()` and hands back a value
instead of more checks.

Save it as `restassured/src/test/java/boxoffice/OrdersTest.java`:

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

## The token, once for the class

`askForAToken` is marked `@BeforeAll`, so JUnit runs it **once, before any test of the class**,
and it is `static` because it runs before there is anything else to run it on. It is lesson 3's
token request written in Java: `formParam` sends the fields as a form, the way `curl -d` did,
and the answer is checked like any other before anything is taken out of it. Then
`.extract().path("access_token")` reads one field and returns it, and the static field `token`
keeps it for the tests below.

Checking before extracting is the point of the order. **A token taken from a `401` is `null`**,
and every test after it fails with a message about orders, a long way from the cause; a
`statusCode(200)` in front of `extract()` makes the failure say what actually went wrong.

## An order, and the order read back

`anOrderCanBeReadBack` makes three moves:

1. `auth().oauth2(token)` adds `Authorization: Bearer` and the token, the header lesson 3
   built by hand, and `contentType(ContentType.JSON)` labels the body, which lesson 1 showed
   boxoffice refuses with `415` otherwise.
2. The body is a **text block**, Java's way of writing text over several lines between `"""`
   marks. The JSON in it is exactly what curl sent in lesson 1.
3. `.extract().response()` keeps the whole response rather than one field, because the test
   needs two things from it: the `id` from the body and the `location` header. The `GET` that
   follows goes to that `location`, so the test also checks that the address the server gave
   out works, which is one of the questions lesson 1 said to ask of a `201`.

The two other tests ask what the server refuses: an order with no token, which must be a `401`
that says why in `www-authenticate`, and seven seats, one more than the rule allows.

## What the server saw

Run the class:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=OrdersTest
```

Silent again, so all three passed. boxoffice's own terminal shows what they sent, one line per
request:

```
POST /oauth/token 200
POST /v1/orders 401
POST /v1/orders 422
POST /v1/orders 201
GET /v1/orders/ord-1001 200
```

One token, asked for once, as `@BeforeAll` promised. Then the requests of the three tests, and
**not in the order the file lists them**: JUnit chooses an order of its own, stable from run to
run and not the one in the file. A test that only passes when another ran first is a defect in
the tests, and lesson 12 shows how one hides.

Each run of this class buys two seats of `sh-101`, which has 120, so the 61st run in a row is
refused with `409`. Restarting boxoffice puts every seat back. The small show, `sh-103`, would
sell out in two runs, which is why none of these tests buys it.
