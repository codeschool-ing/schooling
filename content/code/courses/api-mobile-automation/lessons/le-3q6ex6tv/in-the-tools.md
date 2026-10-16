---
title: The same schema in Postman and REST Assured
version: 1
---

**A schema file is meant to be shared: the Node check, the Postman collection and the Java tests can
all read the same one.** What they cannot all do is understand it the same way, because each tool
ships its own validator and each validator implements its own draft of JSON Schema. That is worth
finding out on purpose, because one of the two tools below fails loudly and the other does not.

## Postman and Newman

Postman's test scripts can assert a schema in one line, `pm.response.to.have.jsonSchema(schema)`. A
script cannot read a file from disk, in the app or in Newman, so the schema travels inside the
collection, as the text of a collection variable. This collection holds `schemas/show.json` in the
variable `showSchema`, and two requests that check against it.
Save it as `postman/schemas.postman_collection.json`:

```json
{
  "info": {
    "name": "boxoffice schemas",
    "description": "The JSON schemas of lesson 10, checked inside Postman and Newman.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "One show",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "const show = JSON.parse(pm.collectionVariables.get('showSchema'));",
              "pm.test('the show matches schemas/show.json', () => {",
              "  pm.response.to.have.jsonSchema(show);",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/v1/shows/sh-103"
      }
    },
    {
      "name": "List shows",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "const show = JSON.parse(pm.collectionVariables.get('showSchema'));",
              "pm.test('every show in the list matches schemas/show.json', () => {",
              "  pm.response.to.have.jsonSchema({",
              "    type: 'object', required: ['shows'],",
              "    properties: { shows: { type: 'array', items: show } },",
              "  });",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/v1/shows"
      }
    }
  ],
  "variable": [
    {
      "key": "showSchema",
      "value": "{\"$schema\":\"https://json-schema.org/draft/2020-12/schema\",\"$id\":\"https://boxoffice.example/schemas/show.json\",\"title\":\"Show\",\"description\":\"One show, as GET /v1/shows/{id} answers it.\",\"type\":\"object\",\"required\":[\"id\",\"title\",\"starts_at\",\"price_cents\",\"seats_left\"],\"additionalProperties\":false,\"properties\":{\"id\":{\"type\":\"string\",\"pattern\":\"^sh-[0-9]+$\"},\"title\":{\"type\":\"string\",\"minLength\":1},\"starts_at\":{\"type\":\"string\",\"format\":\"date-time\"},\"price_cents\":{\"type\":\"integer\",\"minimum\":0},\"seats_left\":{\"type\":\"integer\",\"minimum\":0}}}"
    }
  ]
}
```

In the Postman app it imports like lesson 4's collection, and the variable is on the collection's
*Variables* tab; the app was not run for this course. Run it with the Newman lesson 6 installed,
against the lab environment:

```
ana@laptop:~/boxoffice$ npx newman run postman/schemas.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

boxoffice schemas

Root One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 26ms]
  1. the show matches schemas/show.json

Root List shows
  GET http://localhost:8080/v1/shows [200 OK, 569B, 4ms]
  Pass  every show in the list matches schemas/show.json

-----------------------------------------------------------------
|                         |         executed |           failed |
--------------------------+------------------+-------------------
|              iterations |                1 |                0 |
--------------------------+------------------+-------------------
|                requests |                2 |                0 |
--------------------------+------------------+-------------------
|            test-scripts |                2 |                0 |
--------------------------+------------------+-------------------
|      prerequest-scripts |                0 |                0 |
--------------------------+------------------+-------------------
|              assertions |                2 |                1 |
-----------------------------------------------------------------
| total run duration: 137ms                                     |
-----------------------------------------------------------------
| total data received: 502B (approx)                            |
-----------------------------------------------------------------
| average response time: 15ms [min: 4ms, max: 26ms, s.d.: 11ms] |
-----------------------------------------------------------------

  #  failure  detail                                                                   
                                                                                       
 1.  Error    the show matches schemas/show.json                                       
              no schema with key or ref "https://json-schema.org/draft/2020-12/schema" 
              at assertion:0 in test-script                                            
              inside "One show"                                                        
ana@laptop:~/boxoffice$ echo $?
1
```

**`no schema with key or ref "https://json-schema.org/draft/2020-12/schema"`.** The validator inside
Postman knows the drafts up to draft-07, and when the `$schema` line names one it does not have, it
refuses the schema outright. The second request passed only because the `$schema` sat inside a
nested schema, where that validator ignores it.

The schemas of this lesson use nothing that draft-07 lacks, so the fix is to take the line away before
asserting. Add this line after the `JSON.parse` in each of the two scripts:

```js
delete show.$schema; // Postman's validator knows draft-07, not 2020-12
```

```
ana@laptop:~/boxoffice$ npx newman run postman/schemas.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode | grep -E 'Pass|^  [0-9]+\.|assertions'
  Pass  the show matches schemas/show.json
  Pass  every show in the list matches schemas/show.json
|              assertions |               2 |               0 |
ana@laptop:~/boxoffice$ cd restassured
```

That fix is only safe because of what the schema uses. A schema that relied on a 2020-12 keyword
draft-07 does not have would now be checked without it, and the next tool shows what that looks like.

## REST Assured

REST Assured has a module for schemas, `json-schema-validator`, released with the same version
numbers as REST Assured itself. Add it to the project of lesson 7: the whole file has one new
dependency, after `rest-assured`; save it as `restassured/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>boxoffice</groupId>
  <artifactId>boxoffice-api-tests</artifactId>
  <version>1.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.rest-assured</groupId>
      <artifactId>rest-assured</artifactId>
      <version>6.0.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.rest-assured</groupId>
      <artifactId>json-schema-validator</artifactId>
      <version>6.0.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>6.1.3</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
      </plugin>
    </plugins>
  </build>
</project>
```

Then a test class that reads the very files in `~/boxoffice/schemas`. Maven runs tests from the
project's directory, `restassured`, so the path starts with `..`.
Save it as `restassured/src/test/java/boxoffice/SchemaTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchema;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.not;

import java.io.File;
import org.junit.jupiter.api.Test;

// The schemas of lesson 10, the same files the Node check reads.
class SchemaTest {

    static final File SHOW = new File("../schemas/show.json");
    static final File ORDER = new File("../schemas/order.json");

    @Test
    void aShowMatchesItsSchema() {
        given()
            .spec(Api.ANYONE)
        .when()
            .get("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .body(matchesJsonSchema(SHOW));
    }

    @Test
    void aNewOrderMatchesItsSchema() {
        given()
            .spec(Api.as("ci-tests", "ci-secret"))
            .body("{\"show_id\": \"sh-101\", \"seats\": 1}")
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(201)
            .body(matchesJsonSchema(ORDER));
    }

    // A confirmed order must carry its payment: the schema's if/then says so.
    @Test
    void aConfirmedOrderWithoutPaymentBreaksTheSchema() {
        String noPayment = """
            {"id": "ord-1001", "show_id": "sh-101", "seats": 1, "total_cents": 8000, "status": "confirmed"}
            """;
        assertThat(noPayment, not(matchesJsonSchema(ORDER)));
    }
}
```

The first two tests check live answers. The third checks the schema itself: a confirmed order with
no `payment` must *not* match, because of the `if`/`then` at the bottom of `order.json`. From
`~/boxoffice/restassured`:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=SchemaTest
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 3.725 s <<< FAILURE! -- in boxoffice.SchemaTest
[ERROR] boxoffice.SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema -- Time elapsed: 0.029 s <<< FAILURE!
java.lang.AssertionError: 

Expected: not The content to match the given JSON schema.
warning: the following keywords are unknown and will be ignored: [$id, if, then]
    level: "warning"
    schema: {"loadingURI":"#","pointer":""}
    domain: "syntax"
    ignored: ["$id","if","then"]

     but: was "{\"id\": \"ord-1001\", \"show_id\": \"sh-101\", \"seats\": 1, \"total_cents\": 8000, \"status\": \"confirmed\"}\n"
	at org.hamcrest.MatcherAssert.assertThat(MatcherAssert.java:20)
	at org.hamcrest.MatcherAssert.assertThat(MatcherAssert.java:6)
	at boxoffice.SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema(SchemaTest.java:46)

[ERROR] Failures: 
[ERROR]   SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema:46 
Expected: not The content to match the given JSON schema.
warning: the following keywords are unknown and will be ignored: [$id, if, then]
    level: "warning"
    schema: {"loadingURI":"#","pointer":""}
    domain: "syntax"
    ignored: ["$id","if","then"]

     but: was "{\"id\": \"ord-1001\", \"show_id\": \"sh-101\", \"seats\": 1, \"total_cents\": 8000, \"status\": \"confirmed\"}\n"
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0
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
ana@laptop:~/boxoffice/restassured$ echo $?
1
```

**The third test failed: REST Assured says the order without a payment matches the schema.** The
first two passed, so nothing looked wrong with live answers, and that is the danger. Its validator
implements draft 4, from 2013, which has no `if` and no `then`. It skips keywords it does not know,
and the warning that says so, `the following keywords are unknown and will be ignored: [$id, if,
then]`, is printed only inside a failure message like this one. The two live checks passed and
printed nothing at all. **A rule in the schema was silently not enforced**, and only a test
aimed at the rule itself showed it.

A tester has three honest answers, and pretending the rule is checked is not one of them. Keep the
`if`/`then` rule in the Node check of section 03, which enforces it, and say so in the Java test;
assert it in Java with an ordinary assertion instead; or replace the module with a validator that
implements 2020-12. This course takes the first, and marks the test so the gap shows on every run
instead of being deleted. Add the import and the annotation:

```java
import org.junit.jupiter.api.Disabled;
```

```java
    @Disabled("REST Assured's validator implements draft 4 and ignores if/then")
```

the import beside the other imports, the annotation on the line above the third test's `@Test`:

```
ana@laptop:~/boxoffice/restassured$ mvn test -Dtest=SchemaTest | grep -E 'Tests run:|BUILD'
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 1
[INFO] BUILD SUCCESS
```

`Skipped: 1`, with the reason written in the source, where the next person to touch the file reads it.

## What the three tools understood

| tool | validator | draft it implements | what it did with this lesson's schemas |
|---|---|---|---|
| `schemas/check.mjs` | Ajv, `Ajv2020` with ajv-formats | 2020-12 | every rule, `if`/`then` included |
| Postman, Newman | the one inside Postman's sandbox | up to draft-07 | refused the 2020-12 `$schema`; works without that line |
| REST Assured | `json-schema-validator` module | draft 4 | ignored `if`, `then` and `$id`, warning only on a failure |

**One schema, three validators, three answers.** Before trusting a schema check in any tool, give it
an answer that must fail, and see that it does.
