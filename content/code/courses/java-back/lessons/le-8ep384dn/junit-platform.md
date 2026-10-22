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
@@FIG platform@@
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

@@CAP no-tests@@

`No tests to run.` and `BUILD SUCCESS` together are worth remembering: an empty test run is a
success as far as Maven is concerned, and the next section meets that again in a worse form.

## The starter

Spring Boot gathers the test libraries into one starter. Replace `pom.xml` with this version, which
adds `spring-boot-starter-test` in the `test` scope:

```xml
@@POM@@
```

No version again: the parent manages it, as it manages the other starters. Ask Maven what the starter
brought, filtered to the libraries that matter here:

@@CAP tree@@

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

@@CAP surefire@@
