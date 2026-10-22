---
title: Running the features with JUnit and Spring
version: 1
---

Cucumber reads the feature files and calls the glue, but something has to start it, and in this
project that is Maven's test plugins, which already know how to run JUnit. So Cucumber runs as a
**JUnit Platform engine**: the platform that runs lesson 18's Jupiter tests, with a second engine
plugged in beside Jupiter. Three files connect the two: the pom, a suite class, and a Spring
configuration for the glue.

## The dependencies

Replace `pom.xml` with this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
    <springdoc.version>3.1.1</springdoc.version>
    <rest-assured.version>6.1.0</rest-assured.version>
    <cucumber.version>8.0.4</cucumber.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-bom</artifactId>
        <version>${cucumber.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>${springdoc.version}</version>
    </dependency>

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-testcontainers</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-junit-jupiter</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-postgresql</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.rest-assured</groupId>
      <artifactId>rest-assured</artifactId>
      <version>${rest-assured.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-java</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-spring</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-junit-platform-engine</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.platform</groupId>
      <artifactId>junit-platform-suite</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
        <executions>
          <execution>
            <goals>
              <goal>integration-test</goal>
              <goal>verify</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

Spring Boot's parent manages the versions of hundreds of libraries, and Cucumber is not among them.
A **BOM**, a bill of materials, is a pom that holds nothing but versions. Importing `cucumber-bom`
in `<dependencyManagement>` gives every Cucumber module the version in `cucumber.version`, so the
modules, which are released together, always agree with each other, and the entries below carry
no version at all. The four new test dependencies:

| dependency | what it brings |
|---|---|
| `cucumber-java` | the annotations: `@Given`, `@When`, `@Then`, the hooks |
| `cucumber-spring` | the glue created as Spring beans, inside a Spring test context |
| `cucumber-junit-platform-engine` | the engine that finds `.feature` files and runs each scenario as a test |
| `junit-platform-suite` | `@Suite`, the class that tells the platform what to run; its version comes from Spring Boot |

```
ana@vm:~/bookshop$ PENDING
```

## The suite

Create `src/test/java/com/example/bookshop/acceptance/CucumberIT.java`:

```java
package com.example.bookshop.acceptance;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectPackages;
import org.junit.platform.suite.api.Suite;

@Suite
@IncludeEngines("cucumber")
@SelectPackages("features")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.example.bookshop.acceptance")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty")
class CucumberIT {
}
```

A **suite** is a class with no test methods that only says what to run, and each annotation answers
one question. `@IncludeEngines("cucumber")` says which engine, so Jupiter does not go looking in
here too. `@SelectPackages("features")` says where the features are: a package on the test
classpath, which is where `src/test/resources/features/` ends up after the build. The first
`@ConfigurationParameter` is the glue, `cucumber.glue`, naming the package of the step definitions.
The second is `cucumber.plugin`, the report to print, and `pretty` is the one you are about to see.

The name ends in `IT` on purpose. Lesson 19 split the tests in two: Surefire runs `*Test` classes in
`mvn test`, and Failsafe runs `*IT` classes in `mvn verify`, because they start the whole
application and a database. These scenarios do both, so they belong with the second kind.

## Spring for the glue

Create `src/test/java/com/example/bookshop/acceptance/CucumberSpringConfiguration.java`:

```java
package com.example.bookshop.acceptance;

import io.cucumber.spring.CucumberContextConfiguration;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

import com.example.bookshop.TestcontainersConfiguration;

@CucumberContextConfiguration
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
public class CucumberSpringConfiguration {
}
```

**`@CucumberContextConfiguration`** marks the one class whose annotations cucumber-spring reads to
build the Spring test context. There must be exactly one in the glue. The other three are the
annotations of lesson 20's `BooksApiIT`, for the same reasons: the whole application on a random
port, the `test` profile, and PostgreSQL from Testcontainers. The class has an empty body because it
is only a place to hang annotations; the steps live elsewhere and receive their beans through
their constructors.

## A run

`-Dit.test=CucumberIT` tells Failsafe to run that one class; the unit tests still run before it,
because `verify` comes after `test`. The pretty report shares the terminal with Spring's log, so the
`grep` keeps the lines that carry Cucumber's source comments, the line with the count, and the
verdict:

```
ana@vm:~/bookshop$ PENDING
```

Every scenario is printed with the file and line it came from, and every step with a tick and the
method that ran it, which is the first thing to read when a sentence goes to the wrong method. The
outline appears twice, once per row of its table, with the values put in: lines 22 and 23 of the
file are the two rows of `Examples`. JUnit sees three tests, one per scenario. A step is not a test
of its own: it is a line inside one.

## What lives how long

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" aria-label=\"One bar across the top: the Spring context, the bookshop on a random port with PostgreSQL in a container, started once and cached. Under it, in order, BooksApiIT and then three scenarios: scenario 1, and the outline's two rows. Each scenario gets a new OrderingSteps, then runs the @Before hook, the background and its steps. One bar across the bottom: the database, shared by all of them, with what each left in it: BooksApiIT ordered The Time Machine, leaving 4; scenario 1 set The War of the Worlds to 5 and left 3; the first row set Persuasion to 5 and left 5; the second set it to 0 and left 0.\"><rect x=\"20\" y=\"14\" width=\"660\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Spring context: the bookshop on a random port, PostgreSQL in a container</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">started once, then taken from the cache by every class with the same configuration</text><rect x=\"20\" y=\"70\" width=\"130\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"85.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BooksApiIT</text><text x=\"85.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 tests</text><text x=\"85.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Cucumber is not</text><text x=\"85.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">involved here</text><rect x=\"166\" y=\"70\" width=\"160\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"246.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scenario 1</text><rect x=\"176\" y=\"100\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"246.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"246.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"246.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"246.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"342\" y=\"70\" width=\"160\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"422.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outline, row 1</text><rect x=\"352\" y=\"100\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"422.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"422.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"422.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"422.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"518\" y=\"70\" width=\"162\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outline, row 2</text><rect x=\"528\" y=\"100\" width=\"142\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"599.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"599.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"599.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"20\" y=\"226\" width=\"660\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the database: one, shared, never rolled back between them</text><text x=\"85.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ordered 1 Time Machine</text><text x=\"85.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">4 left</text><text x=\"246.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">set War of the Worlds to 5</text><text x=\"246.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3 left</text><text x=\"422.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">set Persuasion to 5</text><text x=\"422.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">5 left, refused</text><text x=\"599.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">set Persuasion to 0</text><text x=\"599.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">0 left, refused</text></svg>", "caption": "One context and one database for the whole run, and a new set of glue for every scenario. The stock each scenario finds is whatever the one before it left, unless its Given says otherwise."}
```

The three things the steps rely on live for three different lengths of time. The **Spring
context** is started once, with Tomcat on its random port and PostgreSQL in its container, and Spring
keeps it in a cache for any later test class that asks for the same configuration. The **glue** is
created again for every scenario, so `token` and `lastOrder` start empty each time and nothing one
scenario left in a field can leak into the next. The **database** is neither: it lives as long as
the context, and nothing rolls it back between scenarios, because every write went through HTTP and
was committed by the application.

The cache reaches further than Cucumber. Run the whole of `verify` and count the containers:

```
ana@vm:~/bookshop$ PENDING
```

Three integration test classes start a PostgreSQL container and a context of their own.
`CucumberIT` starts neither: its configuration is the same as `BooksApiIT`'s, so Spring handed it
the context `BooksApiIT` had left behind, database and all, including the copy of *The Time
Machine* one of its tests had just ordered. In this run `BooksApiIT` happened to go first, and
Maven promises no order. **That is the reason the `Given` steps write the stock instead of
assuming it**: a scenario that depends on the state somebody else left passes or fails depending
on who ran before it.
