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

```schooling-example
{
  "language": "java",
  "file": "ShelfTest.java",
  "parts": [
    {
      "code": "package look;\n\nimport static org.testng.Assert.assertEquals;\n\nimport org.testng.annotations.DataProvider;\nimport org.testng.annotations.Test;\n",
      "note": "`assertEquals` comes from `org.testng.Assert`, and **its arguments are the other way round from JUnit's: actual first, expected second.** A line copied between the two frameworks compiles, and its failure message names the wrong side as the expected one."
    },
    {
      "code": "public class ShelfTest {\n\n    private final Shelf shelf = new Shelf();\n",
      "note": "TestNG builds one `ShelfTest` for the whole class, so this `shelf` is shared by every method that uses it."
    },
    {
      "code": "    @Test\n    public void startsEmpty() {\n        assertEquals(shelf.count(\"Dom Casmurro\"), 0);\n    }\n\n    @Test(dependsOnMethods = \"startsEmpty\")\n    public void addsCopies() {\n        shelf.add(\"Dom Casmurro\", 2);\n        assertEquals(shelf.count(\"Dom Casmurro\"), 2);\n    }\n\n    @Test(dependsOnMethods = \"addsCopies\")\n    public void takesOne() {\n        shelf.take(\"Dom Casmurro\");\n        assertEquals(shelf.count(\"Dom Casmurro\"), 1);\n    }\n",
      "note": "Three tests that are one scenario in steps. **`dependsOnMethods` fixes their order and adds a rule: when the method it names fails, this one is skipped instead of run.** `takesOne` only makes sense on a shelf `addsCopies` has filled."
    },
    {
      "code": "    @DataProvider\n    public Object[][] deliveries() {\n        return new Object[][] {\n                {1, 0, 1},\n                {2, 3, 5},\n                {0, 0, 0}\n        };\n    }\n\n    @Test(dataProvider = \"deliveries\")\n    public void addsUpTwoDeliveries(int first, int second, int expected) {\n        Shelf fresh = new Shelf();\n        fresh.add(\"Iracema\", first);\n        fresh.add(\"Iracema\", second);\n        assertEquals(fresh.count(\"Iracema\"), expected);\n    }\n",
      "note": "A **data provider** is a method that returns rows. The test names it and runs once per row, like `@CsvSource` with the rows built in Java. This test makes its own `Shelf`: sharing the field would make every row depend on the rows before it."
    },
    {
      "code": "    @Test(groups = \"stress\")\n    public void holdsAMillionCopies() {\n        Shelf big = new Shelf();\n        for (int i = 0; i < 1_000_000; i++) {\n            big.add(\"Senhora\", 1);\n        }\n        assertEquals(big.count(\"Senhora\"), 1_000_000);\n    }",
      "note": "A **group** is a label. Nothing in the class decides whether this runs; the suite file below does."
    },
    {
      "code": "}"
    }
  ]
}
```

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

The first run downloads TestNG and surefire's TestNG provider. After that:

```
ana@vm:~/testng-look$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< com.example:testng-look >-----------------------
[INFO] Building testng-look 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ testng-look ---
[INFO] skip non existing resourceDirectory /home/ana/testng-look/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ testng-look ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ testng-look ---
[INFO] skip non existing resourceDirectory /home/ana/testng-look/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ testng-look ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ testng-look ---
[INFO] Using auto detected provider org.apache.maven.surefire.testng.TestNGProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running TestSuite
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.392 s -- in TestSuite
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.161 s
[INFO] Finished at: 2026-10-22T20:21:07-03:00
[INFO] ------------------------------------------------------------------------
```

Three differences from the bookshop's runs, each with a reason:

- `Using auto detected provider ... TestNGProvider`: the same surefire, a different provider, chosen
  by what is on the test classpath.
- `Running TestSuite`: with a suite file, surefire reports the whole suite as one class called
  `TestSuite` rather than one line per test class.
- **The three `SLF4J(W)` lines** come from TestNG, which logs through the SLF4J facade. Lesson 16
  drew the line between a facade and a backend, and this project has the facade with no backend, so
  SLF4J says it will log nothing. They are warnings about TestNG's own logging, not about the tests.

`Tests run: 6`: the three steps of the scenario and the three rows of the data provider.
`holdsAMillionCopies` is not among them, because the suite excludes its group.

## A test that depends on another

Make `addsCopies` expect three copies instead of two, as if the code had a bug that only it can see:

```
ana@vm:~/testng-look$ sed -i 's/assertEquals(shelf.count("Dom Casmurro"), 2);/assertEquals(shelf.count("Dom Casmurro"), 3);/' src/test/java/look/ShelfTest.java
ana@vm:~/testng-look$ mvn test | grep -E "Tests run:|FAILURE!|expected|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[ERROR] Tests run: 6, Failures: 1, Errors: 0, Skipped: 1, Time elapsed: 0.368 s <<< FAILURE! -- in TestSuite
[ERROR] look.ShelfTest.addsCopies -- Time elapsed: 0.005 s <<< FAILURE!
java.lang.AssertionError: expected [3] but found [2]
[ERROR]   ShelfTest.addsCopies:20 expected [3] but found [2]
[ERROR] Tests run: 6, Failures: 1, Errors: 0, Skipped: 1
[INFO] BUILD FAILURE
```

One failure, and **`Skipped: 1`**. The message, `expected [3] but found [2]`, has the two numbers the
right way round only because the call put them in TestNG's order, actual first. TestNG's own result
file says which test was skipped:

```
ana@vm:~/testng-look$ grep -o '<test-method [^>]*status="[A-Z]*"' target/surefire-reports/testng-results.xml | grep -o 'name="[^"]*"\|status="[A-Z]*"' | paste - -
name="startsEmpty"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsUpTwoDeliveries"	status="PASS"
name="addsCopies"	status="FAIL"
name="takesOne"	status="SKIP"
```

`takesOne` never ran: `addsCopies`, which it depends on, failed. That is the point of the feature and
its whole cost in one line. The report is honest, one failure and one test that could not tell you
anything, instead of a second failure that is only an echo of the first. But it also means the test
class is a sequence: `takesOne` cannot be understood, or run, without the two tests before it, and
all three share the one `shelf`. **JUnit makes the opposite choice, a fresh
instance per test, so that no test can depend on another by accident.** Put the expectation back:

```
ana@vm:~/testng-look$ sed -i 's/assertEquals(shelf.count("Dom Casmurro"), 3);/assertEquals(shelf.count("Dom Casmurro"), 2);/' src/test/java/look/ShelfTest.java
```

## Groups

The suite file excludes `stress`. Turn the exclusion into an inclusion and only that group runs; turn
it back and the six run again:

```
ana@vm:~/testng-look$ sed -i 's/<exclude name="stress"\/>/<include name="stress"\/>/' testng.xml && grep -n 'stress' testng.xml
3:  <test name="everything but stress">
6:        <include name="stress"/>
ana@vm:~/testng-look$ mvn test | grep -E "Tests run:|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.354 s -- in TestSuite
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
ana@vm:~/testng-look$ sed -i 's/<include name="stress"\/>/<exclude name="stress"\/>/' testng.xml && mvn test | grep -E "Tests run:|BUILD"
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.355 s -- in TestSuite
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Nothing in the Java changed between the two runs. Which tests make up "the fast suite" or "the
nightly suite" is decided in XML beside the tests, and a team can keep several suite files. JUnit's
equivalent is `@Tag("stress")` on the test and `-Dgroups=stress` or `-DexcludedGroups=stress` on the
Maven command line: the same choice, made by the build instead of by a file of the framework's.

## Why the bookshop uses JUnit

Nothing above is beyond JUnit. Jupiter has `@Tag` for groups, `@ParameterizedTest` for data
providers, and `@TestMethodOrder` with `@Order` for a fixed sequence. What it deliberately lacks is
a test that is skipped because another failed: its tests are meant to be independent, which is why
it builds a new instance for each.

The reason Spring projects use JUnit is not a feature comparison. It is what is already in the pom.
`spring-boot-starter-test` brings JUnit Jupiter and nothing of TestNG. **`@SpringBootTest`, and the
`@DataJpaTest` lesson 19 uses, carry `@ExtendWith(SpringExtension.class)`**, which is a Jupiter
extension: put either on a TestNG class and nothing reads it. Spring still supports
TestNG, through a base class your test extends, `AbstractTestNGSpringContextTests`; what you give up
is the starter's choices and every guide written against them. The older JUnit is the one Spring is
retiring: its JUnit 4 runner, `SpringRunner`, is deprecated since Spring Framework 7.0.

So TestNG is worth reading when you inherit it, and worth choosing for a suite of long ordered
scenarios that would otherwise repeat their set-up in every test. For the bookshop, and for the
next three lessons, it is JUnit.
