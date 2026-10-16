---
title: Running the suite, and the build that ran nothing
version: 1
---

**`mvn test` runs every test class the project has, and a failure is the part of the output worth
reading.** This section adds the test that fails, reads what it prints, finds the reports a
pipeline reads, and then removes two blocks from the `pom.xml` to show the most dangerous result a
test run can give: a success that tested nothing.

## The test that fails on purpose

Lesson 1 found that boxoffice answers `HEAD` with `405`, where the standard says a server must
answer it like `GET`. As a test, save it as `restassured/src/test/java/boxoffice/HeadTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import org.junit.jupiter.api.Test;

// RFC 9110, §9.1: a general-purpose server must answer HEAD like GET.
// boxoffice does not, so this test fails until the server is fixed.
class HeadTest {

    @Test
    void headAnswersLikeGet() {
        given()
            .spec(Api.ANYONE)
        .when()
            .head("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .header("content-type", equalTo("application/json"));
    }
}
```

The comment at the top says why the test exists and why it fails, so the next person to see it red
does not "fix" it by expecting `405`. Now run everything, then ask for the exit code:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test
Request method:	HEAD
Request URI:	http://localhost:8080/v1/shows/sh-103
Proxy:			<none>
Request params:	<none>
Query params:	<none>
Form params:	<none>
Path params:	<none>
Headers:		Accept=*/*
Cookies:		<none>
Multiparts:		<none>
Body:			<none>

HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 19:45:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
[ERROR] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.730 s <<< FAILURE! -- in boxoffice.HeadTest
[ERROR] boxoffice.HeadTest.headAnswersLikeGet -- Time elapsed: 1.694 s <<< FAILURE!
java.lang.AssertionError: 
1 expectation failed.
Expected status code <200> but was <405>.

	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl$HamcrestAssertionClosure.validate(ResponseSpecificationImpl.groovy:516)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.validateResponseIfRequired(ResponseSpecificationImpl.groovy:714)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.statusCode(ResponseSpecificationImpl.groovy:139)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.statusCode(ResponseSpecificationImpl.groovy:147)
	at io.restassured.internal.ValidatableResponseOptionsImpl.statusCode(ValidatableResponseOptionsImpl.java:89)
	at boxoffice.HeadTest.headAnswersLikeGet(HeadTest.java:19)

[ERROR] Failures: 
[ERROR]   HeadTest.headAnswersLikeGet:19 1 expectation failed.
Expected status code <200> but was <405>.

[ERROR] Tests run: 11, Failures: 1, Errors: 0, Skipped: 0
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

Read it in four blocks, from the top:

1. **The request and the response**, printed because `HeadTest` uses `Api.ANYONE` and a check
   failed. `Request method: HEAD` and the URI are what was sent; `HTTP/1.1 405 Method Not
   Allowed` with `allow: GET` is what came back. That is the evidence a defect report needs,
   produced by the failing run itself.
2. **The failure**: `Expected status code <200> but was <405>`, and under it the stack trace. Look
   for the one line that names your own file, `HeadTest.java:19`, and skip the rest.
3. **The summary**: `Tests run: 11, Failures: 1`. Eleven is one in `HealthTest`, five in
   `ShowsTest`, four in `OrdersTest` and this one.
4. **The exit code**, `1`. A pipeline reads that number and nothing else, which is how one red
   test stops a merge, as lesson 6 did with Newman.

A **failure** is a check that did not hold. Maven also counts **errors**, a test that could not
finish at all, such as one whose server was not running: the request throws before any check is
made. Both turn the build red, and they point at different places: a failure at the server's
answer, an error usually at the lab.

## The reports

Surefire writes two files per class under `target/surefire-reports`:

```
ana@laptop:~/boxoffice/restassured$ ls target/surefire-reports
TEST-boxoffice.HeadTest.xml    boxoffice.HeadTest.txt
TEST-boxoffice.HealthTest.xml  boxoffice.HealthTest.txt
TEST-boxoffice.OrdersTest.xml  boxoffice.OrdersTest.txt
TEST-boxoffice.ShowsTest.xml   boxoffice.ShowsTest.txt
ana@laptop:~/boxoffice/restassured$ grep '<testcase' target/surefire-reports/TEST-boxoffice.OrdersTest.xml
  <testcase name="theAuditorMayReadButNotBuy" classname="boxoffice.OrdersTest" time="0.067"/>
  <testcase name="noTokenIs401AndSaysWhy" classname="boxoffice.OrdersTest" time="0.039"/>
  <testcase name="sevenSeatsAreRefused" classname="boxoffice.OrdersTest" time="0.061"/>
  <testcase name="anOrderCanBeReadBack" classname="boxoffice.OrdersTest" time="0.118"/>
```

The `.txt` files are the summary you read above. The `TEST-….xml` files are in the JUnit XML
format, the same one lesson 6 asked Newman for, and it is what a CI server reads to draw its list
of tests: one `<testcase>` per method, with a `<failure>` inside the ones that failed. Their order
here is the order the tests ran, which is again not the order of the file.

To run less than everything, `-Dtest` takes a class, or a class and a method after `#`:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest='OrdersTest#sevenSeatsAreRefused'
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

## A green build that ran nothing

The two `<plugin>` blocks of the `pom.xml` look like boilerplate, and the obvious tidy-up is to
delete them. This is what Ubuntu's Maven does with this project when the Surefire block is gone:

```
ana@laptop:~/boxoffice/restassured$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] -------------------< boxoffice:boxoffice-api-tests >--------------------
[INFO] Building boxoffice-api-tests 1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ boxoffice-api-tests ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/restassured/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ boxoffice-api-tests ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ boxoffice-api-tests ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/restassured/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ boxoffice-api-tests ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ boxoffice-api-tests ---
[INFO] Surefire report directory: /home/ana/boxoffice/restassured/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------

Results :

Tests run: 0, Failures: 0, Errors: 0, Skipped: 0

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.083 s
[INFO] Finished at: 2026-10-10T16:45:16-03:00
[INFO] ------------------------------------------------------------------------
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

**`Tests run: 0`, and the exit code is `0`.** `HeadTest` is still in the project and should fail,
and nothing failed, because nothing ran. With no version named, Maven 3.8.7 runs the old Surefire
it was built with, which predates JUnit Jupiter and finds none of these tests. It does not
complain about that; it reports, correctly, that zero tests failed.

Remove the compiler block as well, the whole `<build>`, and run it again:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test

-------------------------------------------------------
 T E S T S
-------------------------------------------------------

Results :

Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
```

The same zero, and this time it hides a second problem. The classes compiled in earlier runs are
still in `target`, so the old compiler plugin decides there is nothing to do. `clean` deletes
`target` first, which is what a fresh checkout on a pipeline machine starts from anyway:

```
ana@laptop:~/boxoffice/restassured$ mvn -q clean test
[ERROR] COMPILATION ERROR : 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.1:testCompile (default-testCompile) on project boxoffice-api-tests: Compilation failure: Compilation failure: 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
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

Now it fails loudly: the old compiler plugin asks Java to compile for Java 5, which Java 21 no
longer accepts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 228\" role=\"img\" aria-label=\"With no Surefire version in the pom.xml, Maven 3.8.7 runs Surefire 2.12.4, which finds no JUnit Jupiter test and reports Tests run: 0 with exit code 0. With version 3.6.0 pinned, Surefire runs the eleven tests and reports Tests run: 11 with exit code 1, because HeadTest fails.\"><defs><marker id=\"f07plugins-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the same eleven tests, the same Maven 3.8.7</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pom.xml names no version</text><rect x=\"250\" y=\"40\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">surefire 2.12.4</text><text x=\"340\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">finds no JUnit Jupiter test</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tests run: 0</text><text x=\"590\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">exit code 0: green</text><line x1=\"180\" y1=\"67\" x2=\"248\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><line x1=\"430\" y1=\"67\" x2=\"498\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><rect x=\"20\" y=\"130\" width=\"160\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pom.xml pins 3.6.0</text><rect x=\"250\" y=\"130\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">surefire 3.6.0</text><text x=\"340\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">runs JUnit Jupiter</text><rect x=\"500\" y=\"130\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tests run: 11</text><text x=\"590\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">exit code 1: red</text><line x1=\"180\" y1=\"157\" x2=\"248\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><line x1=\"430\" y1=\"157\" x2=\"498\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><text x=\"350\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only the second result is true: HeadTest should fail</text></svg>", "caption": "Without a pinned Surefire, the build is green because nothing ran."}
```

A newer Maven ships newer default plugins, and those find the tests. That does not make the pins
unnecessary; it means the result of the same project depends on which Maven is installed, on your
laptop, on a colleague's and on the pipeline's machine. **Read the count of tests, never only the
colour of the build.** A suite of eleven tests that reports zero is a broken suite, and the habit
of checking that number is what catches it on the day somebody tidies a `pom.xml`.
