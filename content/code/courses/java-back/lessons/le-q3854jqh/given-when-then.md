---
title: Given, when, then
version: 1
---

A REST Assured test is written in three clauses, and the names are the library's own methods.
`given()` describes the request: headers, a body, credentials. `when()` sends it, with a method and
a path. `then()` states what the answer must be, and **each statement after it is an expectation**
that fails the test if the answer disagrees. The shape is borrowed from behaviour-driven
development, which lesson 21 meets properly; here it is only a way of reading a test from top to
bottom.

Create `src/test/java/com/example/bookshop/BooksApiIT.java` with two tests. The section after this
one adds two more.

```schooling-example
{
  "language": "java",
  "file": "BooksApiIT.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport static io.restassured.RestAssured.given;\nimport static org.hamcrest.Matchers.equalTo;\n\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\nimport org.springframework.boot.test.context.SpringBootTest.WebEnvironment;\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.context.annotation.Import;\nimport org.springframework.test.context.ActiveProfiles;\n",
      "note": "`given` is the entry point of REST Assured, and `equalTo` is a Hamcrest matcher, which REST Assured uses for every check on a body. Both are imported statically, so the test reads as a sentence."
    },
    {
      "code": "@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)\n@ActiveProfiles(\"test\")\n@Import(TestcontainersConfiguration.class)\nclass BooksApiIT {\n",
      "note": "The same three annotations as `BookshopApplicationIT` of lesson 19, with one difference: `RANDOM_PORT`. The `test` profile supplies the JWT secret, and `TestcontainersConfiguration` supplies PostgreSQL."
    },
    {
      "code": "    @LocalServerPort\n    int port;\n\n    @BeforeEach\n    void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "`@LocalServerPort` injects the port Tomcat actually took. REST Assured sends to `localhost:8080` unless told otherwise, so every test first points it at this one. `RestAssured.port` is a static field, shared by everything in the JVM, which is harmless while one test class runs at a time."
    },
    {
      "code": "    @Test\n    void anyoneCanReadABook() {\n        given()\n            .accept(ContentType.JSON)",
      "note": "`given()`: the request, here only the `Accept` header, saying the test wants JSON back."
    },
    {
      "code": "        .when()\n            .get(\"/books/{id}\", 1)",
      "note": "`when()`: sending it, the method and the path. `{id}` is filled from the argument after it and encoded, the way a path variable is on the server side."
    },
    {
      "code": "        .then()\n            .statusCode(200)\n            .body(\"title\", equalTo(\"Dom Casmurro\"))\n            .body(\"author\", equalTo(\"Machado de Assis\"));\n    }",
      "note": "`then()`: what the answer must be. `body(\"title\", …)` reads the field `title` out of the JSON with a path expression and hands it to the matcher. A failure names the expectation that broke."
    },
    {
      "code": "\n    @Test\n    void anUnknownBookIsAProblemDetail() {\n        given()\n            .accept(ContentType.JSON)\n        .when()\n            .get(\"/books/{id}\", 999)\n        .then()\n            .statusCode(404)\n            .contentType(\"application/problem+json\")\n            .body(\"title\", equalTo(\"Book not found\"));\n    }",
      "note": "Book 999 does not exist, and lesson 7 promised a problem detail for it. The test holds the API to that promise on all three counts: the status, the media type `application/problem+json`, and the `title` the handler writes."
    },
    {
      "code": "}"
    }
  ]
}
```

## Running one integration test

`mvn verify` runs every test, unit and integration. To run one integration test class, name it in
the `it.test` property, which failsafe reads. The output of a whole build is long, so `grep` keeps
the lines worth reading here:

```
ana@vm:~/bookshop$ mvn verify -Dit.test=BooksApiIT | grep -E 'Tomcat started|Started BooksApiIT|Tests run:.*BooksApiIT|BUILD'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2026-10-22T20:24:29.074-03:00  INFO 23319 --- [bookshop] [           main] [] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 41725 (http) with context path '/'
2026-10-22T20:24:29.079-03:00  INFO 23319 --- [bookshop] [           main] [] com.example.bookshop.BooksApiIT          : Started BooksApiIT in 6.12 seconds (process running for 6.92)
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 7.630 s -- in com.example.bookshop.BooksApiIT
[INFO] BUILD SUCCESS
```

The two `OpenJDK 64-Bit Server VM warning` lines come first because they skip `grep` altogether:
the JVM writes them to standard error, and a pipe carries only standard output. Each test JVM
prints one, surefire's and then failsafe's, because the Mockito agent of lesson 19 puts a class of
its own on the boot class path. They say nothing about these tests.

Then read the rest from the top. `Tomcat started on port` names a port nobody chose: the number
differs on every run, and the test only knows it through `@LocalServerPort`. `Started BooksApiIT`
is the application starting inside the test's JVM, in the time a context and a PostgreSQL
container take. Then the two tests ran in the same class, against the same server.

`-Dit.test` narrows failsafe and nothing else. The unit tests of lessons 18 and 19 still ran
before these, under surefire, which is the first of the two warnings.

## A test that fails, read

Before trusting the test, see what it says when it fails. As a detour, put a wrong expectation into the
second test: the belief that an error answer is `application/json`, like every other answer of the
bookshop.

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

**`1 expectation failed.`** is REST Assured's own report, and the line under it says exactly which
expectation and what came back instead. The server answered `application/problem+json`, as lesson 7
made it, and a client that checks the media type before parsing would have treated that answer
differently from a book. That difference is what the test exists to protect.

The stack trace below it reads from the inside out. The four `io.restassured` lines are the
library, and three of them name `.groovy` files: REST Assured is partly written in the Groovy the
dependency tree showed. The last line is yours: `BooksApiIT.java:50` is the line of the `contentType` expectation, not of the request, so
a failing test points at the claim that broke.

Put the expectation back:

```
ana@vm:~/bookshop$ sed -i 's|contentType("application/json")|contentType("application/problem+json")|' src/test/java/com/example/bookshop/BooksApiIT.java
ana@vm:~/bookshop$ mvn verify -Dit.test=BooksApiIT | grep -E 'Tests run:.*BooksApiIT|BUILD'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 7.910 s -- in com.example.bookshop.BooksApiIT
[INFO] BUILD SUCCESS
```
