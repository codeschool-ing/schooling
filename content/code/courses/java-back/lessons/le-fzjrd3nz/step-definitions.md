---
title: Step definitions and Cucumber expressions
version: 1
---

A feature file does nothing on its own. Each of its steps runs because a Java method claims it. A
**step definition** is a method annotated with `@Given`, `@When` or `@Then` whose argument is a
pattern, and for every step Cucumber runs the one method whose pattern matches the sentence. The
classes that hold those methods are called the **glue**, because they are what sticks the
sentences to the code.

## The pattern is a Cucumber expression

`"she orders {int} copies of {string}"` is a **Cucumber expression**: literal text with typed holes
in braces. Matched against `When she orders 2 copies of "The War of the Worlds"`, it yields two
values, the number 2 and the title without its quotes, and Cucumber passes them to the method in
the order the holes appear.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"The step When she orders 2 copies of &quot;The War of the Worlds&quot; is matched by the expression she orders {int} copies of {string}. The 2 fills {int} and the quoted title fills {string}, and Cucumber calls sheOrders with 2 and the title, without its quotes. The keyword When plays no part in the match.\"><defs><marker id=\"f1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the step</text><text x=\"20.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the expression</text><text x=\"20.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the call</text><text x=\"176.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">When</text><text x=\"212.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">she orders 2 copies of &quot;The War of the Worlds&quot;</text><text x=\"176.0\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not part of the match</text><text x=\"176.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">@When(&quot;she orders {int} copies of {string}&quot;)</text><text x=\"176.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">sheOrders(quantity = 2, title = The War of the Worlds)</text><text x=\"176.0\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the order of the holes</text><rect x=\"289.2\" y=\"40\" width=\"11.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"303.6\" y=\"122\" width=\"40.0\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"325.2\" y=\"204\" width=\"11.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"375.6\" y=\"40\" width=\"169.6\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"418.8\" y=\"122\" width=\"61.6\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"404.4\" y=\"204\" width=\"155.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><line x1=\"294.8\" y1=\"61\" x2=\"323.6\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"323.6\" y1=\"143\" x2=\"330.8\" y2=\"202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"460.4\" y1=\"61\" x2=\"449.6\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"449.6\" y1=\"143\" x2=\"482.0\" y2=\"202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><text x=\"509.6\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the quotes are dropped</text></svg>", "caption": "Cucumber matches the sentence after the keyword, fills each hole from it, and calls the method with the values in order."}
```

The holes Cucumber knows without being told:

| hole | matches | arrives as |
|---|---|---|
| `{int}`, `{long}` | a whole number, such as `5` or `-1` | `int`, `long` |
| `{float}`, `{double}`, `{bigdecimal}` | a decimal number, such as `3.5` | `float`, `double`, `BigDecimal` |
| `{word}` | one word with no spaces | `String` |
| `{string}` | text in double or single quotes | `String`, without the quotes |

A pattern that starts with `^` or ends with `$` is read as a regular expression instead. Older
projects are full of them, `"^she orders (\\d+) copies of \"([^\"]*)\"$"` and the like; a Cucumber
expression says the same thing in a form the person who wrote the sentence can still read.

## The keyword is not part of the match

Cucumber matches the sentence and ignores the word in front of it. `Given`, `When`, `Then` and `And`
are for the reader: a method annotated `@Given` runs just as happily for a `Then` line with the same
words. Which means **one sentence cannot both arrange and check**, and the feature file has two
sentences about stock for that reason. *The shop has 5 copies of …* sets the stock. *… has 3 copies
left* reads it. Written as one sentence used in both places, the method behind it would have to
choose. If it only checked, the `Given` would pass only while the database still held the five
copies it was seeded with; against a database another test had already ordered from, it would fail
for a reason that has nothing to do with the rule. If it only set, the
`Then` would check nothing at all.

Every sentence has to match **exactly one** method in all of the glue. Two matches is an error, and
Cucumber names both methods rather than picking one. None is the undefined step of the last
section.

## The class

Create `src/test/java/com/example/bookshop/acceptance/OrderingSteps.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderingSteps.java",
  "parts": [
    {
      "code": "package com.example.bookshop.acceptance;\n\nimport static io.restassured.RestAssured.given;\nimport static org.assertj.core.api.Assertions.assertThat;\n\nimport java.util.Map;\n\nimport io.cucumber.java.Before;\nimport io.cucumber.java.en.Given;\nimport io.cucumber.java.en.Then;\nimport io.cucumber.java.en.When;\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\nimport io.restassured.response.Response;\n\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.jdbc.core.simple.JdbcClient;\n",
      "note": "The annotations come from `io.cucumber.java.en`, the English keywords; a `pt` package beside it has `@Dado`, `@Quando` and `@Então`. The HTTP calls are REST Assured, exactly as lesson 20 used it, and `JdbcClient` is lesson 9's."
    },
    {
      "code": "public class OrderingSteps {\n\n    private static final Map<String, String> PASSWORDS = Map.of(\"ana\", \"ana-reads-books\");\n\n    private final JdbcClient jdbc;\n    private final int port;\n\n    private String token;\n    private Response lastOrder;\n",
      "note": "A plain class: no annotation makes it glue, its package does. `token` and `lastOrder` carry what one step leaves for the next, because the steps of a scenario are separate method calls with nothing else in common."
    },
    {
      "code": "    public OrderingSteps(JdbcClient jdbc, @LocalServerPort int port) {\n        this.jdbc = jdbc;\n        this.port = port;\n    }\n",
      "note": "Constructor injection, as lesson 5 argued for it. Spring supplies both arguments, because cucumber-spring creates every glue class as a bean, a new one for each scenario. `@LocalServerPort` is the random port the test server started on."
    },
    {
      "code": "    @Before\n    public void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "Cucumber's `@Before`, not JUnit's `@BeforeEach`: a **hook**, run before every scenario and before its background. REST Assured keeps its port in a static field, so this points it at today's server."
    },
    {
      "code": "    @Given(\"the customer {string} has signed in\")\n    public void theCustomerHasSignedIn(String name) {\n        token = given().auth().preemptive().basic(name, PASSWORDS.get(name))\n                .post(\"/auth/token\")\n                .then().statusCode(200)\n                .extract().path(\"accessToken\");\n    }\n",
      "note": "`{string}` matches text in double or single quotes and passes it without them, so the background's line arrives here as `name` = `ana`. It goes through the front door, Basic authentication on `/auth/token`, and keeps the token."
    },
    {
      "code": "    @Given(\"the shop has {int} copies of {string}\")\n    public void theShopHas(int copies, String title) {\n        int rows = jdbc.sql(\"UPDATE book SET stock = ? WHERE title = ?\")\n                .params(copies, title)\n                .update();\n        assertThat(rows).as(\"books titled %s\", title).isEqualTo(1);\n    }\n",
      "note": "A `Given` ARRANGES. It writes the stock straight into the table, because the shop has no screen for setting stock and the scenario is not about one. Checking that exactly one row changed turns a misspelt title into a failure on this line, instead of a puzzling one three steps later."
    },
    {
      "code": "    @When(\"she orders {int} copies of {string}\")\n    public void sheOrders(int quantity, String title) {\n        int bookId = book(title).path(\"id\");\n        lastOrder = given().auth().oauth2(token)\n                .contentType(ContentType.JSON)\n                .body(\"{\\\"lines\\\": [{\\\"bookId\\\": \" + bookId + \", \\\"quantity\\\": \" + quantity + \"}]}\")\n                .post(\"/orders\");\n    }\n",
      "note": "The one action, through the same HTTP API a client uses. `{int}` arrives as an `int` and `{string}` as a `String`, in the order they appear in the sentence."
    },
    {
      "code": "    @Then(\"the order is accepted with a total of {int} cents\")\n    public void theOrderIsAccepted(int total) {\n        assertThat(lastOrder.statusCode()).isEqualTo(201);\n        assertThat(lastOrder.<Integer>path(\"totalCents\")).isEqualTo(total);\n    }\n",
      "note": "A `Then` only looks. AssertJ throws when the status or the total is not what the sentence says, and Cucumber reports the step that threw."
    },
    {
      "code": "    @Then(\"the order is refused as out of stock\")\n    public void theOrderIsRefused() {\n        assertThat(lastOrder.statusCode()).isEqualTo(409);\n        assertThat(lastOrder.<String>path(\"title\")).isEqualTo(\"Out of stock\");\n    }\n",
      "note": "409 and the title from lesson 7's problem details: the refusal the business person called \"out of stock\", in the API's own terms."
    },
    {
      "code": "    @Then(\"{string} has {int} copies left\")\n    public void hasCopiesLeft(String title, int copies) {\n        assertThat(book(title).<Integer>path(\"stock\")).isEqualTo(copies);\n    }\n",
      "note": "Read back through the API, which is what a customer could see, rather than from the table the `Given` wrote to."
    },
    {
      "code": "    private Response book(String title) {\n        Response found = given().queryParam(\"q\", title).get(\"/books/search\");\n        found.then().statusCode(200);\n        return given().get(\"/books/{id}\", found.<Integer>path(\"[0].id\"));\n    }\n}",
      "note": "A helper, not a step: it has no annotation, so no sentence reaches it. It finds a book's id by its title with the search endpoint from lesson 11."
    }
  ]
}
```

Read the methods in the order the first scenario calls them and the class tells the same story as
the feature file, one level down: sign in, set the stock, place the order, look at the answer and
at the shelf. The sentences stay in the shop's language and the methods speak HTTP and SQL, which
is the division of labour the previous section asked for.

## Glue is found by package

Cucumber does not look for step definitions everywhere. It loads glue from the packages it is told
to, here `com.example.bookshop.acceptance`, which the runner in the next section names. A step
definition in another package is invisible, and to Cucumber it looks exactly like a sentence nobody
wrote code for.
