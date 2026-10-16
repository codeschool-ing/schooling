---
title: A Maven project and its first test
version: 1
---

**A Maven project is a directory with a `pom.xml` at the top and the code underneath, where
Maven expects it.** The tests of this lesson live in `~/boxoffice/restassured`, beside
boxoffice and apart from the collection of lessons 4 to 6, so each tool keeps its own files.
Make the directories the first test needs:

```sh
cd ~/boxoffice
mkdir -p restassured/src/test/java/boxoffice
```

## The `pom.xml`

The POM, the project object model, says what the project is called, what it depends on and how
it is built. Save it as `restassured/pom.xml`:

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

Read it from the top:

- **the coordinates**, `groupId`, `artifactId` and `version`, name this project the same way
  the dependencies below are named. Nothing downloads it; they only have to be there.
- **the properties** say the code is Java 21 and the files are UTF-8, so `São Paulo` in a test
  means the same on every machine.
- **the dependencies** are the two libraries the tests use. REST Assured sends the requests and
  checks the answers; JUnit Jupiter is the test framework, which finds the methods marked as
  tests and runs them. `<scope>test</scope>` says they exist only for the tests, which in this
  project is all there is.
- **the plugins** pin the versions of the two plugins that compile and run the tests. Section 07
  removes them and shows what goes wrong.

| what | version | what it does here |
|---|---|---|
| `io.rest-assured:rest-assured` | 6.0.1 | sends a request, checks the response |
| `org.junit.jupiter:junit-jupiter` | 6.1.3 | finds and runs the test methods |
| `maven-compiler-plugin` | 3.15.0 | compiles the tests as Java 21 |
| `maven-surefire-plugin` | 3.6.0 | runs them, writes the reports |

Every version was resolved from Maven Central when the transcripts were recorded, in October
2026, and they are written out whole on purpose. **A version written out is a build that does
the same thing next year**; a version left to "whatever is newest" is a build that changes when
somebody else publishes. REST Assured 6.1.0 appeared the day before the recording and was not
tried.

## The first test

One test, the smallest that proves the chain works: boxoffice is up and says so. Write it in your
editor and save it as `restassured/src/test/java/boxoffice/HealthTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import org.junit.jupiter.api.Test;

class HealthTest {

    @Test
    void healthAnswersOk() {
        given()
            .baseUri("http://localhost:8080")
        .when()
            .get("/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("ok"));
    }
}
```

**The path follows a convention every Java tool relies on.** The file starts with `package
boxoffice;`, so it sits in a directory called `boxoffice`, under `src/test/java` because it is a
test, and it is named after the class it holds. Surefire then runs the classes whose names end
in `Test`, among a few other patterns. A test class called `HealthCheck` compiles and is never
run, and nothing prints an error about it.

## Reading it as Java

You need very little Java to read a test, and all of it is in that file:

| in the file | what it is |
|---|---|
| `package boxoffice;` | the group this class belongs to, matching its directory |
| `import static io.restassured.RestAssured.given;` | lets the file write `given()` instead of `RestAssured.given()` |
| `class HealthTest { … }` | the class, a container for the tests; braces mark where it starts and ends |
| `@Test` | an annotation: it tells JUnit that the method below is a test |
| `void healthAnswersOk() { … }` | a method that returns nothing; its name is what a report prints, so it says what is checked |
| `"http://localhost:8080"` | a `String`, text in double quotes |
| `.when()`, `.get(…)` on new lines | one long expression, each call working on what the one above returned |
| `;` | the end of the statement, after the last call |

The calls laid out one per line, indented by what they belong to, are the house style of REST
Assured, and the next section reads them. For now, check that the chain runs. boxoffice runs in
its own terminal, as in lesson 1; in your first terminal, from `~/boxoffice`:

```
ana@laptop:~/boxoffice$ find restassured -type f
restassured/src/test/java/boxoffice/HealthTest.java
restassured/pom.xml
```

```
ana@laptop:~/boxoffice$ cd restassured
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
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 21] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.6.0:test (default-test) @ boxoffice-api-tests ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running boxoffice.HealthTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.878 s -- in boxoffice.HealthTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.098 s
[INFO] Finished at: 2026-10-10T16:44:37-03:00
[INFO] ------------------------------------------------------------------------
```

The first `mvn test` on a new machine **downloads REST Assured, JUnit, the two plugins and
everything they depend on**, which fills the screen with `Downloading from central` lines and
takes a while. The transcript was recorded with those already in `~/.m2`, so it shows
what every later run prints. Read it down the middle: the plugins run in the order the phases
need them, resources, then the compiler, then Surefire, and under `T E S T S` one class ran one
test with no failures. `BUILD SUCCESS` is Maven's verdict on the whole run.
