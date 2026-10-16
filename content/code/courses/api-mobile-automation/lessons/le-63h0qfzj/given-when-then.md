---
title: Given, when, then
version: 1
---

**A REST Assured test is one sentence in three parts, and each part is one part of an HTTP
exchange.** `given()` describes the request: where it goes, its headers, its parameters, its
body. `when()` names the method and the path, and sends it. `then()` lists what the response
must look like. The words come from the way testers wrote behaviour down long before this
library existed, and REST Assured borrowed them so a test reads in the order a person thinks
about it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A REST Assured test has three parts. given() describes the request and when() sends it, as GET /v1/shows?date=… to boxoffice. boxoffice answers with a status, headers and JSON, and then() checks that response.\"><defs><marker id=\"f07chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"95\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">in the test</text><text x=\"330\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">on the wire</text><rect x=\"20\" y=\"30\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">given()</text><text x=\"95\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">describes the request</text><rect x=\"20\" y=\"100\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">when()</text><text x=\"95\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">method, path: sends it</text><rect x=\"20\" y=\"170\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">then()</text><text x=\"95\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">checks the response</text><rect x=\"230\" y=\"46\" width=\"200\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the request</text><text x=\"330\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /v1/shows?date=…</text><rect x=\"230\" y=\"150\" width=\"200\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the response</text><text x=\"330\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 · headers · JSON</text><rect x=\"530\" y=\"98\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server</text><text x=\"605\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><line x1=\"170\" y1=\"53\" x2=\"228\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"170\" y1=\"123\" x2=\"228\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"430\" y1=\"73\" x2=\"528\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"528\" y1=\"138\" x2=\"432\" y2=\"177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"228\" y1=\"182\" x2=\"172\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><text x=\"330\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a check that fails stops the test at that line</text></svg>", "caption": "given() and when() build and send the request; then() checks what came back."}
```

## A class of tests for the shows

Five tests of the public part of boxoffice, the part lesson 1 read with curl. Save it as `restassured/src/test/java/boxoffice/ShowsTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;

import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

class ShowsTest {

    static final String BASE = "http://localhost:8080";

    @Test
    void theListHasThreeShows() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows")
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .header("cache-control", "max-age=60")
            .body("shows", hasSize(3))
            .body("shows.id", hasItems("sh-101", "sh-102", "sh-103"))
            .body("shows.price_cents", everyItem(greaterThan(0)));
    }

    @Test
    void aDateNarrowsTheList() {
        given()
            .baseUri(BASE)
            .queryParam("date", "2026-11-08")
        .when()
            .get("/v1/shows")
        .then()
            .statusCode(200)
            .body("shows.id", contains("sh-103"));
    }

    @Test
    void oneShowByItsId() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .header("etag", matchesPattern("\"[0-9a-f]{16}\""))
            .body("title", equalTo("O Pagador de Promessas"))
            .body("starts_at", equalTo("2026-11-08T18:00:00-03:00"))
            .body("price_cents", equalTo(6500));
    }

    @Test
    void theCheapestShowIsFoundWithGPath() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows")
        .then()
            .body("shows.findAll { it.price_cents < 7000 }.id", contains("sh-103"))
            .body("shows.min { it.price_cents }.title", equalTo("O Pagador de Promessas"));
    }

    @Test
    void anUnknownShowIs404WithAProblem() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows/{id}", "sh-999")
        .then()
            .statusCode(404)
            .contentType("application/problem+json")
            .body("status", equalTo(404))
            .body("detail", equalTo("there is no show sh-999"));
    }
}
```

Here are the pieces worth reading slowly, with what each one does:

```schooling-example
{
 "language": "java",
 "file": "ShowsTest.java",
 "parts": [
  {
   "code": "    @Test\n    void aDateNarrowsTheList() {\n        given()\n            .baseUri(BASE)\n            .queryParam(\"date\", \"2026-11-08\")",
   "note": "`given` is the request before it is sent: the server it goes to and, here, a query parameter. REST Assured writes `?date=2026-11-08` onto the path for you."
  },
  {
   "code": "        .when()\n            .get(\"/v1/shows\")",
   "note": "`when` is the method and the path. This is the line that sends the request; everything above it only described one."
  },
  {
   "code": "        .then()\n            .statusCode(200)\n            .body(\"shows.id\", contains(\"sh-103\"));\n    }",
   "note": "`then` is the list of checks on the answer, in order. The first one that fails stops the test, and the message names it."
  },
  {
   "code": "    @Test\n    void oneShowByItsId() {\n        given()\n            .baseUri(BASE)\n        .when()\n            .get(\"/v1/shows/{id}\", \"sh-103\")",
   "note": "A `{id}` in the path is filled from the argument after it. The report then names the template, which is easier to read than a path with an id glued in."
  },
  {
   "code": "        .then()\n            .statusCode(200)\n            .header(\"etag\", matchesPattern(\"\\\"[0-9a-f]{16}\\\"\"))\n            .body(\"title\", equalTo(\"O Pagador de Promessas\"))",
   "note": "`header` checks one header by name, in any case. `body` takes a path into the JSON and a Hamcrest matcher that says what the value there must satisfy."
  },
  {
   "code": "            .body(\"shows.findAll { it.price_cents < 7000 }.id\", contains(\"sh-103\"))\n            .body(\"shows.min { it.price_cents }.title\", equalTo(\"O Pagador de Promessas\"));",
   "note": "The path is GPath, Groovy's language for walking JSON. `findAll` keeps the items the braces accept, `it` is the item being tried, and `min` picks the smallest by what the braces compute."
  }
 ]
}
```

## The matchers

The second argument of `body` and `header` is a **matcher** from Hamcrest, a small library that
comes with REST Assured. A matcher is a description of what a value must satisfy, and when the
value fails it, the matcher writes the message. These are the ones this lesson uses:

| matcher | passes when the value | fails on |
|---|---|---|
| `equalTo(6500)` | is exactly that, of that type | `"6500"`, a string |
| `hasSize(3)` | is a list of exactly three | four shows |
| `hasItems("sh-101", "sh-103")` | is a list holding at least these, in any order | a list without `sh-103` |
| `contains("sh-103")` | is a list of exactly these, in this order | `["sh-103", "sh-104"]` |
| `everyItem(greaterThan(0))` | is a list whose every item passes the inner matcher | one price of `0` |
| `startsWith("/v1/orders/")` | is text that begins so | `/orders/ord-1001` |
| `containsString("expired")` | is text with that inside it | an empty header |
| `matchesPattern(…)` | is text the regular expression matches whole | an `etag` with no quotes |

**`contains` is the one people misread.** The name sounds like "has this among others", which is
`hasItems`. `contains` means the whole list, in order, and nothing else, so it is the strict one,
and the right one for `aDateNarrowsTheList`: a date filter that also returned `sh-101` would be a
defect, and `hasItems("sh-103")` would pass it.

Notice what the class does not check. **No test reads `seats_left` of `sh-101`**, because the
order tests of section 05 buy seats of that show, and what it says then depends on which tests ran
before. Lesson 12 is about tests that share state like that; the cheapest defence is not to assert
what another test changes.

## Running one class, and reading a failure

`-Dtest=ShowsTest` runs that class alone, and `-q`, for quiet, hides Maven's progress so that only
problems are printed:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=ShowsTest
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

**Silence is the pass**, and the exit code says so: `0`. A test is only worth something if it can
fail, so make it fail once on purpose. Change `hasSize(3)` to `hasSize(4)` in the first test and
run the same command:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=ShowsTest
[ERROR] Tests run: 5, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 2.232 s <<< FAILURE! -- in boxoffice.ShowsTest
[ERROR] boxoffice.ShowsTest.theListHasThreeShows -- Time elapsed: 0.050 s <<< FAILURE!
java.lang.AssertionError: 
1 expectation failed.
JSON path shows doesn't match.
Expected: a collection with size <4>
  Actual: <[{id=sh-101, title=Auto da Compadecida, starts_at=2026-11-06T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-102, title=Auto da Compadecida, starts_at=2026-11-07T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-103, title=O Pagador de Promessas, starts_at=2026-11-08T18:00:00-03:00, price_cents=6500, seats_left=4}]>

	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl$HamcrestAssertionClosure.validate(ResponseSpecificationImpl.groovy:516)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.validateResponseIfRequired(ResponseSpecificationImpl.groovy:714)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.body(ResponseSpecificationImpl.groovy:274)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.selectMethod(IndyInterface.java:373)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.body(ResponseSpecificationImpl.groovy:121)
	at io.restassured.internal.ValidatableResponseOptionsImpl.body(ValidatableResponseOptionsImpl.java:244)
	at boxoffice.ShowsTest.theListHasThreeShows(ShowsTest.java:29)

[ERROR] Failures: 
[ERROR]   ShowsTest.theListHasThreeShows:29 1 expectation failed.
JSON path shows doesn't match.
Expected: a collection with size <4>
  Actual: <[{id=sh-101, title=Auto da Compadecida, starts_at=2026-11-06T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-102, title=Auto da Compadecida, starts_at=2026-11-07T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-103, title=O Pagador de Promessas, starts_at=2026-11-08T18:00:00-03:00, price_cents=6500, seats_left=4}]>

[ERROR] Tests run: 5, Failures: 1, Errors: 0, Skipped: 0
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.6.0:test (default-test) on project boxoffice-api-tests: There are test failures.
[ERROR] 
[ERROR] See /home/ana/boxoffice/restassured/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

Read it from the line that names your file. `ShowsTest.theListHasThreeShows:29` is the test and
the line of the check that failed, and the message above it says the rest: the matcher expected
`a collection with size <4>`, and the actual value is the list of three shows, printed whole, so
you can see what came back without running anything else. The lines starting `at org.codehaus` are
REST Assured's own machinery, and you can skip them. Put the `3` back before going on.
