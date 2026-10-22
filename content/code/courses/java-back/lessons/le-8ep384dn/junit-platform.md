---
title: JUnit, the Platform, and what mvn test runs
version: 1
---

A **unit test** here is a method that calls one piece of the bookshop with an input you chose, and
fails when the answer is not the one you wrote down. No server starts, no database is reached and
Spring is not involved. `Isbn` is a class of static methods, and `Book` and `Order` are entities
only as far as their annotations go: a test can make one with `new` and ask it a question in a few
microseconds. Lesson 19 adds the other kind, tests that start the application against a real
PostgreSQL; this lesson stays below that line on purpose, because tests this cheap can run on every
build.

## JUnit 5, JUnit 6, and the name on the jar

The framework is **JUnit**, and the version this course uses is 6.0.3. Most books, articles and job
adverts say "JUnit 5", and for what you write they mean the same thing. JUnit 5, released in 2017,
introduced the **Jupiter** programming model: the annotations and assertions in
`org.junit.jupiter.api`. JUnit 6, released in 2025, kept that model, the same packages and the same
annotations, raised its minimum to Java 17, and gave all its parts one version number. A test written
for JUnit 5 is, in everything this lesson shows, a test for JUnit 6. The title of this lesson keeps
the name people search for.

JUnit 4, from 2006, is a different API (`org.junit.Test`, rules, runners) and is not what any of
this is.

## Three layers, not one jar

The common picture is that JUnit is a library that runs tests. It is three things, and Maven talks
to only one of them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 272\" role=\"img\" aria-label=\"mvn test runs maven-surefire-plugin, which finds the test classes, runs them in a JVM of its own and writes the reports. It hands them to the JUnit Platform, which discovers the tests and gives each to an engine: the Jupiter engine runs IsbnTest, BookTest and OrderTest, written with @Test, @ParameterizedTest and @Nested. A Cucumber engine is added in lesson 21; the Vintage engine runs JUnit 3 and 4 tests and is not in this project.\"><rect x=\"10\" y=\"112\" width=\"96\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"58\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">mvn test</text><line x1=\"106\" y1=\"134\" x2=\"131\" y2=\"134\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"138,134 130,130 130,138\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"138\" y=\"92\" width=\"170\" height=\"84\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"223\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">maven-surefire-plugin</text><text x=\"223\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">finds the classes named *Test</text><text x=\"223\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs them in a JVM of its own</text><text x=\"223\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and writes the reports</text><line x1=\"308\" y1=\"134\" x2=\"331\" y2=\"134\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"338,134 330,130 330,138\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"338\" y=\"14\" width=\"352\" height=\"244\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"514\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">JUnit Platform</text><text x=\"514\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">discovers the tests and hands each one to its engine</text><rect x=\"356\" y=\"66\" width=\"316\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Jupiter engine: the tests this lesson writes</text><text x=\"514\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Test  @ParameterizedTest  @Nested</text><text x=\"514\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">IsbnTest  BookTest  OrderTest</text><rect x=\"356\" y=\"140\" width=\"316\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cucumber engine</text><text x=\"514\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lesson 21 adds it, and nothing above it changes</text><rect x=\"356\" y=\"198\" width=\"316\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Vintage engine</text><text x=\"514\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs JUnit 3 and 4 tests, for old code; not in this project</text></svg>", "caption": "Three layers between mvn test and a test method. Maven knows surefire, surefire knows the Platform, and only an engine knows what @Test means."}
```

- **Surefire** is the Maven plugin bound to the `test` phase. It knows which classes are tests by
  their names, and it starts a separate JVM for them.
- **The JUnit Platform** is the launcher: it discovers tests and hands each one to the engine that
  owns it. It knows nothing about `@Test`.
- **An engine** is what gives an annotation its meaning. Jupiter's engine runs the tests in this
  lesson. Other frameworks plug in as engines of their own, which is how lesson 21 runs Cucumber
  scenarios on the same Platform, with no runner of its own.

## What the project had before

At the end of lesson 17 the bookshop had no test, and `mvn test` said so without complaint:

```
(capture no-tests missing)
```

`No tests to run.` and `BUILD SUCCESS` together are worth remembering: an empty test run is a
success as far as Maven is concerned, and the next section meets that again in a worse form.

## The starter

Spring Boot gathers the test libraries into one starter. Replace `pom.xml` with this version, which
adds `spring-boot-starter-test` in the `test` scope:

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
  </properties>

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

No version again: the parent manages it, as it manages the other starters. Ask Maven what the starter
brought, filtered to the libraries that matter here:

```
(capture tree missing)
```

Read from the top:

- `junit-jupiter` is the API you write against (`-api`), parameterised tests (`-params`) and the
  engine (`-engine`), all at 6.0.3, with two pieces of the Platform underneath. Surefire brings the
  Platform's launcher itself, which is why it is not in this list.
- `assertj-core` is a second way of writing assertions, which the bookshop's `OrderTest` uses.
- `mockito-core` and `mockito-junit-jupiter` are lesson 19's.
- `spring-test` and the two `spring-boot-test` jars are what a test needs to start an application
  context. Nothing in this lesson uses them.
- `json-path`, `hamcrest`, `awaitility` and `xmlunit-core` are matchers and helpers for tests that
  check JSON, wait for something asynchronous, or compare XML.

Everything in the list ends in `:test`. As lesson 1 showed, a scope is inherited downwards, so none of
these jars reaches `src/main/java` or the executable jar.

The surefire version is the parent's choice too, and it is the same 3.5.6 lesson 1 pinned by hand:

```
(capture surefire missing)
```
