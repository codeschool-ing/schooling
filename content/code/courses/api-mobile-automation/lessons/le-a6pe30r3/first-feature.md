---
title: A first feature
version: 1
---

**A feature file is a list of scenarios, and a scenario is a list of steps, each one a keyword
and its argument.** Karate runs the steps from the top, and the first one that fails ends the
scenario. Save it as `karate/src/test/java/boxoffice/shows.feature`:

```
Feature: The shows boxoffice lists

  Background:
    * url baseUrl

  Scenario: the list has three shows
    Given path 'v1', 'shows'
    When method get
    Then status 200
    And match header cache-control == 'max-age=60'
    And match response.shows == '#[3]'
    And match response.shows[*].id contains ['sh-101', 'sh-103']

  Scenario: one show by its id
    Given path 'v1', 'shows', 'sh-103'
    When method get
    Then status 200
    And match response.title == 'O Pagador de Promessas'
    And match response.price_cents == 6500

  Scenario: an unknown show is 404
    Given path 'v1', 'shows', 'sh-999'
    When method get
    Then status 404
    And match response.detail == 'there is no show sh-999'
```

Read the first scenario line by line:

| step | what Karate does |
|---|---|
| `Feature: …` | names the file's subject; the report prints it |
| `Background:` | its steps run again before every scenario of the file |
| `* url baseUrl` | sets the address, from the variable `karate-config.js` returned |
| `Scenario: …` | starts one test; its name is what a failure names |
| `Given path 'v1', 'shows'` | adds `/v1/shows` to the address, one segment per argument |
| `When method get` | sends the request; nothing goes out before this line |
| `Then status 200` | fails the scenario unless the status is `200` |
| `And match header cache-control == …` | compares one header of the response |
| `And match response.shows == '#[3]'` | `response` is the body, already parsed; `#[3]` means an array of three |
| `And match … contains [ … ]` | the ids include these two, in any order |

**`Given`, `When`, `Then` and `And` do nothing.** Karate treats each of them exactly as it treats
`*`, the bullet the `Background` step uses. They are there for whoever reads the scenario, so use
them where they help a person follow it and `*` where a step is plumbing, like setting the
address. The segments of `path` are written apart because Karate encodes each one, so an id with
a space or a slash in it cannot break the address.

## Running it

At this point the project holds four files, and boxoffice runs in its own terminal as in lesson 1:

```
ana@laptop:~/boxoffice$ find karate -type f | sort
karate/pom.xml
karate/src/test/java/boxoffice/BoxofficeTest.java
karate/src/test/java/boxoffice/shows.feature
karate/src/test/java/karate-config.js
```

```
ana@laptop:~/boxoffice$ cd karate
ana@laptop:~/boxoffice/karate$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< boxoffice:boxoffice-karate >---------------------
[INFO] Building boxoffice-karate 1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ boxoffice-karate ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/karate/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ boxoffice-karate ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ boxoffice-karate ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 2 resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ boxoffice-karate ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 21] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.6.0:test (default-test) @ boxoffice-karate ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running boxoffice.BoxofficeTest
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.465 s -- in boxoffice.BoxofficeTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.287 s
[INFO] Finished at: 2026-10-10T22:48:42-03:00
[INFO] ------------------------------------------------------------------------
```

Maven's part is lesson 7's: resources, the compiler, Surefire. Two lines are new. `Copying 2
resources` is the `testResources` block at work, putting the feature and the configuration, the two
files that are not Java, on the classpath; without it, Karate would find no feature and run nothing.
And the three `SLF4J(W)` lines are a warning from the logging library Karate writes through: no
logging back end is installed, so Karate's own log goes nowhere. It changes nothing about the
results, and the report of section 07 records every request anyway.

**One JUnit class, three tests.** Surefire counts each scenario as a test of `BoxofficeTest`,
because the `@TestFactory` method handed JUnit one test per scenario. A feature with ten scenarios
adds ten to that number, and a feature Karate never found adds nothing, which is the zero lesson 7
warned about.
