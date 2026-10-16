---
title: A Karate project, and the glue it leaves out
version: 1
---

**Karate is a test tool whose tests are written as scenarios, in plain text, and run by a Java
library.** You need the JDK and Maven that lesson 7 installed, and you write almost no Java: one
short file, after which every test is a `.feature` file. This section builds the
project, and says first what makes Karate different from the tool its syntax came from.

## The glue Karate removes

The scenario syntax is **Gherkin**, the language of Cucumber, a tool for describing behaviour in
steps a person can read: `Given`, `When`, `Then`, `And`. In Cucumber, a step such as
`When the customer asks for the list of shows` means nothing on its own. Somebody writes a Java
method with that sentence in an annotation. The method sends the request, keeps the response in a
field, and lets the next step's method check it. Those methods are the **glue code**, and in a
Cucumber suite there is one for every distinct sentence, often more code than the scenarios
themselves.

Karate's steps are not free sentences. `url`, `path`, `method`, `status`, `header` and `match` are
keywords Karate already knows how to perform, so `When method get` sends a request with no method of
yours behind it. The scenario is the test. What you give up is the freedom to write a step in the
words of the business. A Karate scenario reads like HTTP, because that is what it describes.

## The project

The tests live in `~/boxoffice/karate`, beside lesson 7's `restassured`:

```sh
cd ~/boxoffice
mkdir -p karate/src/test/java/boxoffice
```

Save it as `karate/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>boxoffice</groupId>
  <artifactId>boxoffice-karate</artifactId>
  <version>1.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.karatelabs</groupId>
      <artifactId>karate-junit6</artifactId>
      <version>2.1.2</version>
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
    <testResources>
      <testResource>
        <directory>src/test/java</directory>
        <excludes>
          <exclude>**/*.java</exclude>
        </excludes>
      </testResource>
    </testResources>
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

It has the shape of lesson 7's, with three differences:

- the dependencies are Karate and JUnit. `io.karatelabs:karate-junit6` is Karate with its bridge to
  JUnit 6. It declares JUnit as something the project provides rather than something it brings, so
  the `pom.xml` names `junit-jupiter` itself, the same version lesson 7 used. Leave it out and the
  one Java file does not compile, because nothing then brings the `@TestFactory` annotation it uses.
  The group is `io.karatelabs`. Older articles show `com.intuit.karate`, the group Karate was
  published under before it moved, and Karate 2 exists only under the new one.
- `testResources`, which tells Maven to copy everything in `src/test/java` that is not Java onto the
  classpath. Karate's convention is to keep each `.feature` file beside the runner that starts it.
  Without this block, Maven would leave them behind and Karate would find nothing.
- the plugins are pinned for the same reason as in lesson 7, section 07.

| what | version | what it does here |
|---|---|---|
| `io.karatelabs:karate-junit6` | 2.1.2 | Karate itself, and its bridge to JUnit 6 |
| `org.junit.jupiter:junit-jupiter` | 6.1.3 | runs what Karate hands it |
| `maven-compiler-plugin` | 3.15.0 | compiles the one Java file |
| `maven-surefire-plugin` | 3.6.0 | runs it, and so runs the features |

Karate 2 is built for Java 21, which is what lesson 7 installed. 2.1.3 was published in late
September 2026, two weeks before the recording, and was not tried.

## The runner and the configuration

Save it as `karate/src/test/java/boxoffice/BoxofficeTest.java`:

```java
package boxoffice;

import io.karatelabs.junit6.Karate;
import org.junit.jupiter.api.TestFactory;

// The one Java file of the project: it hands every .feature file
// in this directory to Karate, and JUnit reports what Karate ran.
class BoxofficeTest {

    @TestFactory
    Karate features() {
        return Karate.run().relativeTo(getClass());
    }
}
```

That is the whole of the Java. `@TestFactory` marks a method that does not test anything itself but
returns tests for JUnit to run. `Karate.run().relativeTo(getClass())` returns one for every scenario
of every `.feature` file in the same directory as the class. The class name ends in `Test` so that
Surefire finds it, as lesson 7 found out the hard way.

Karate reads one more file before any feature: `karate-config.js`, at the root of the test
classpath, whose function returns the variables every feature can use. Save it as `karate/src/test/java/karate-config.js`:

```js
function fn() {
  return {
    baseUrl: karate.properties['boxoffice.url'] || 'http://localhost:8080'
  };
}
```

It does what lesson 7's `Api.BASE` did: `baseUrl` is `http://localhost:8080` unless the command
line says `-Dboxoffice.url=…`. The file is JavaScript, and Karate runs it with its own engine.
