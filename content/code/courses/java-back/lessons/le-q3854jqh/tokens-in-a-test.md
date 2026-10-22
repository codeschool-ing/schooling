---
title: A token, inside a test
version: 1
---

Most of the bookshop is behind lesson 15's security. Reading the catalogue is open, but adding a
book needs the `catalogue:write` scope and an order needs `orders`, and both come only in a JWT
that `/auth/token` hands out in exchange for a username and a password. An API test of an order
therefore has to do what a client does: **ask for a token, then use it.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"A sequence between the test and the bookshop. First the test posts to /auth/token with HTTP Basic credentials; the first filter chain checks them and the answer is 200 with an accessToken. The test extracts the token. Then it posts to /orders with Authorization: Bearer and the token; the second filter chain verifies the JWT and the answer is 201 with the order, whose customer is ana.\"><defs><marker id=\"l20t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"15\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the test</text><rect x=\"490\" y=\"15\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the bookshop</text><polyline points=\"110,51 110,315\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 4\"></polyline><polyline points=\"560,51 560,315\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 4\"></polyline><text x=\"335\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /auth/token</text><text x=\"335\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Authorization: Basic YW5hOmFuYS1yZWFkcy1ib29rcw==</text><polyline points=\"110,98 558,98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"568\" y=\"84\" width=\"125\" height=\"28\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">chain 1: HTTP Basic</text><text x=\"335\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"accessToken\": \"eyJ…\", …}</text><polyline points=\"560,132 112,132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"15\" y=\"150\" width=\"190\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">extract().path(\"accessToken\")</text><text x=\"110\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">kept in a local variable</text><text x=\"335\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /orders</text><text x=\"335\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><polyline points=\"110,248 558,248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline><rect x=\"568\" y=\"234\" width=\"125\" height=\"28\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">chain 2: JWT</text><text x=\"335\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201 {\"customer\": \"ana\", …}</text><polyline points=\"560,284 112,284\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20t-ah)\"></polyline></svg>", "caption": "Two requests, and the second cannot be written until the first has answered: the token is read out of one response and sent in the next request."}
```

A tempting shortcut is to switch security off in the test profile, or to build a token by hand
with the secret the test already knows. Either one tests a different application from the one that
ships. The first never runs the filter chains at all; the second runs them against a token the
token controller did not make, so a bug in the claims it writes, such as a scope it leaves out,
passes. Going through `/auth/token` costs one request and tests both halves.

Replace `BooksApiIT.java` with this version. It keeps the two tests of the last section and adds
two.

```schooling-example
{
  "language": "java",
  "file": "BooksApiIT.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport static io.restassured.RestAssured.given;\nimport static org.hamcrest.Matchers.equalTo;\nimport static org.hamcrest.Matchers.hasSize;\n\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\nimport org.springframework.boot.test.context.SpringBootTest.WebEnvironment;\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.context.annotation.Import;\nimport org.springframework.test.context.ActiveProfiles;\n",
      "note": "One import is new: `hasSize`, a Hamcrest matcher for the length of a list."
    },
    {
      "code": "@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)\n@ActiveProfiles(\"test\")\n@Import(TestcontainersConfiguration.class)\nclass BooksApiIT {\n\n    @LocalServerPort\n    int port;\n\n    @BeforeEach\n    void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "Unchanged from the last section."
    },
    {
      "code": "    @Test\n    void anyoneCanReadABook() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 1)\n        .then()\n            .statusCode(200)\n            .body(\"title\", equalTo(\"Dom Casmurro\"))\n            .body(\"author\", equalTo(\"Machado de Assis\"));\n    }\n\n    @Test\n    void anUnknownBookIsAProblemDetail() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 999)\n        .then()\n            .statusCode(404)\n            .contentType(\"application/problem+json\")\n            .body(\"title\", equalTo(\"Book not found\"));\n    }\n",
      "note": "The two tests of the last section, unchanged."
    },
    {
      "code": "    @Test\n    void addingABookNeedsAToken() {\n        given()\n            .contentType(ContentType.JSON)\n            .body(\"\"\"\n                {\"isbn\": \"9786500000078\", \"title\": \"Emma\", \"author\": \"Jane Austen\",\n                 \"priceCents\": 3300, \"stock\": 3}\"\"\")\n        .when()\n            .post(\"/books\")\n        .then()\n            .statusCode(401);\n    }\n",
      "note": "A valid book, sent with no credentials at all. The expectation is 401, not 400 and not 201: the security filter chain refuses the request before the controller exists for it, so validation never runs and the book is never stored."
    },
    {
      "code": "    @Test\n    void aCustomerWithATokenCanPlaceAnOrder() {\n        String token =\n            given()\n                .auth().preemptive().basic(\"ana\", \"ana-reads-books\")\n            .when()\n                .post(\"/auth/token\")\n            .then()\n                .statusCode(200)\n                .extract().path(\"accessToken\");\n",
      "note": "The first request asks for a token, with ana's password in HTTP Basic. `preemptive()` sends the credentials on the first attempt instead of waiting for the server to ask. `extract().path(\"accessToken\")` reads one field of the answer back into Java, once the expectations above it have passed."
    },
    {
      "code": "        given()\n            .auth().oauth2(token)\n            .contentType(ContentType.JSON)\n            .body(\"\"\"\n                {\"lines\": [{\"bookId\": 2, \"quantity\": 1}]}\"\"\")\n        .when()\n            .post(\"/orders\")\n        .then()\n            .statusCode(201)\n            .body(\"customer\", equalTo(\"ana\"))\n            .body(\"lines\", hasSize(1))\n            .body(\"totalCents\", equalTo(2950));\n    }",
      "note": "The second request carries the token. `auth().oauth2(token)` is REST Assured's name for the header `Authorization: Bearer` followed by the token, which is what lesson 15's resource server reads. `lines` is a JSON array, and `hasSize(1)` checks its length; book 2 costs 2950 cents, so one copy is the total."
    },
    {
      "code": "}"
    }
  ]
}
```

The token lives in a local variable of the one test that needs it. It is not a field shared by the
class, because a test that depends on another test having run first fails or passes by the order
JUnit happens to choose.

## The whole build

`mvn verify` with no property runs every test of the project. The `grep` keeps the lines that tell
the story of the integration tests:

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

The three `Tests run` lines add up to seven integration tests, four of them this lesson's, and all passed. Count the containers, though:
**three PostgreSQL containers for three test classes.** `BookRepositoryIT` declares its own, as
lesson 19 wrote it. The other two each import `TestcontainersConfiguration`, where the container
is a bean, and a bean lives in an application context. `BookshopApplicationIT` runs in a `MOCK`
context and `BooksApiIT` in a `RANDOM_PORT` one; Spring caches a context and reuses it for every
test class that asks for the same configuration, and these two ask for different ones. So the
second context starts a second container. Each one costs the second or so the lines report, and on
a project with dozens of test classes, keeping their configurations identical is how a suite stays
fast.

## What these four tests leave behind

The order test placed a real order, and the database in that container now holds it, with the
stock of book 2 one copy lower. Nothing else in this class reads stock, so nothing notices. A
test written later that expects the stock of the migration would pass alone and fail beside this
one, which is the kind of failure that appears only on the build server. Two habits keep it away:
assert on what your own test created rather than on totals, and give a test that needs a known
state its own data. `testing-cicd` lesson 3 treats fixtures and test data sets properly.
