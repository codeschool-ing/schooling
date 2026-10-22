---
title: TestNG, and why Spring chose JUnit
version: 1
---

**TestNG** is the other test framework of the Java world. It appeared in 2004, when JUnit was at
version 3, and it brought ideas JUnit took years to adopt: annotations instead of method names
starting with `test`, parameterised tests, and groups of tests selected by a file rather than by
the build. You meet it in older enterprise code, in Selenium suites written in the 2010s, and in
projects whose tests are long scenarios rather than small checks.

Most of what it does, Jupiter now does too. What is still different is one decision, and it is the
reverse of the one the previous section drew: **TestNG makes ONE instance of a test class and runs
every method on it**, and it lets a test say which other tests have to pass first.

This section builds a tiny project outside the bookshop, so that the two frameworks never share a
classpath. Create `~/testng-look` with four files.

## The project

`pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>testng-look</artifactId>
  <version>1.0.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.testng</groupId>
      <artifactId>testng</artifactId>
      <version>7.12.0</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-resources-plugin</artifactId>
        <version>3.5.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.5.6</version>
        <configuration>
          <suiteXmlFiles>
            <suiteXmlFile>testng.xml</suiteXmlFile>
          </suiteXmlFiles>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

There is no Spring parent here, so nothing chooses plugin versions for you, and Maven 3.8.7's own
choices are old (lesson 1 showed what they cost). The three plugins pinned are the three that
`mvn test` runs. Surefire is the same plugin that runs the bookshop's JUnit tests: it looks at the
test classpath, finds TestNG instead of the JUnit Platform, and uses its TestNG provider. The one
line of configuration hands it a suite file.

`src/main/java/look/Shelf.java`, the class under test, counts copies by title:

```java
package look;

import java.util.HashMap;
import java.util.Map;

public class Shelf {

    private final Map<String, Integer> copies = new HashMap<>();

    public void add(String title, int count) {
        copies.merge(title, count, Integer::sum);
    }

    public void take(String title) {
        int left = count(title);
        if (left == 0) {
            throw new IllegalStateException("No copies of " + title);
        }
        copies.put(title, left - 1);
    }

    public int count(String title) {
        return copies.getOrDefault(title, 0);
    }
}
```

`src/test/java/look/ShelfTest.java`:

@@EXAMPLE shelftest@@

`testng.xml`, in the project's root, beside the pom:

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="shelf">
  <test name="everything but stress">
    <groups>
      <run>
        <exclude name="stress"/>
      </run>
    </groups>
    <classes>
      <class name="look.ShelfTest"/>
    </classes>
  </test>
</suite>
```

A **suite** file is TestNG's own way of saying what to run: which classes, which groups in or out,
in what order, in parallel or not. JUnit leaves that choice to the build tool; TestNG puts it in a
file the team versions beside the tests.

## Running it

@@CAP run@@

## A test that depends on another

Break `add` so that it replaces the count instead of adding to it, and run again:

@@CAP broken@@

## Groups

@@CAP groups@@

## Why the bookshop uses JUnit

Nothing above is beyond JUnit. Jupiter has `@Tag` for groups, `@ParameterizedTest` for data
providers, and `@TestMethodOrder` with `@Order` for a fixed sequence. What it deliberately lacks is
a test that is skipped because another failed: its tests are meant to be independent, which is why
it builds a new instance for each.

The reason Spring projects use JUnit is not a feature comparison. It is what is already in the pom.
`spring-boot-starter-test` brings JUnit Jupiter and nothing of TestNG. **`@SpringBootTest`, and the
`@DataJpaTest` lesson 19 uses, carry `@ExtendWith(SpringExtension.class)`**, which is a Jupiter
extension: put either on a TestNG class and nothing reads it. Spring still supports
TestNG, through a base class your test extends, `AbstractTestNGSpringContextTests`, and you lose the
starter's choices and every guide written for it. Spring Framework 7 went the other way with the
older JUnit: its JUnit 4 runner, `SpringRunner`, is deprecated since 7.0.

So TestNG is worth reading when you inherit it, and worth choosing for a suite of long ordered
scenarios that would otherwise repeat their set-up in every test. For the bookshop, and for the
next three lessons, it is JUnit.
