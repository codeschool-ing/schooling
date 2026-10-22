---
title: A first test, and reading what Maven says
version: 1
---

The first class to test is `Isbn`, from lesson 6: one static method, a string in, a boolean out, and
nothing else in the bookshop involved. Lesson 1's project had a test class of the same shape, which
`mvn package` ran without anybody reading it. This one is read.

Create `src/test/java/com/example/bookshop/catalogue/IsbnTest.java`. This is a first version, and the
next section replaces it:

```java
package com.example.bookshop.catalogue;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class IsbnTest {

    @Test
    void acceptsAValidIsbn13() {
        assertTrue(Isbn.isValid("9786500000016"));
    }

    @Test
    void refusesAWrongCheckDigit() {
        assertFalse(Isbn.isValid("9786500000017"));
    }

    @Test
    void refusesNull() {
        assertFalse(Isbn.isValid(null));
    }
}
```

Five things about its shape, each of which matters:

- **It sits in `src/test/java`, in the same package as `Isbn`.** Maven compiles it separately and
  never puts it in the jar. The same package means a test could reach a package-private method,
  although this one needs only the public one.
- **Neither the class nor its methods are `public`.** Jupiter finds them by reflection and does not
  need it. JUnit 4 did, which is why older code is full of `public void testSomething()`.
- **`@Test` marks a test method**: no parameters, returns `void`, and passes unless something it
  calls throws.
- **An assertion is a method that throws when its condition is false.** `assertTrue` and
  `assertFalse` come from `org.junit.jupiter.api.Assertions`, imported statically so that a test
  reads as a sentence. A failed assertion throws `AssertionFailedError`, and that exception is how
  JUnit knows the test failed.
- **The method name says what is being claimed.** It is what Maven prints when the test fails, so
  `refusesAWrongCheckDigit` tells you what broke before you open a file. `test1` tells you nothing.

## Running it

```
(capture first-run missing)
```

Read it bottom up, the way you will read every run after this one:

- `BUILD SUCCESS` or `BUILD FAILURE` is the verdict, and it is also the exit code: 0 or not. That is
  what a script, or later a CI server, looks at.
- `Results:` adds up every class: `Tests run: 3, Failures: 0, Errors: 0, Skipped: 0`. A **failure**
  is an assertion that did not hold; an **error** is any other exception escaping the test, such as
  a `NullPointerException` in the code under test. Both fail the build, and the difference says where
  to look: after a failure the code answered wrongly, after an error it never got as far as
  answering.
- Above it, one `Running` line and one `Tests run` line per test class, with its time.
- `Using auto detected provider ... JUnitPlatformProvider` is surefire saying it found the JUnit
  Platform on the test classpath, which is the starter's doing.

Surefire also writes a report per class into `target/surefire-reports`, as text and as XML:

```
(capture reports missing)
```

The XML files are the ones a CI server reads to draw its list of tests. `testing-cicd` reads them.

Two ways to run less. `-q` keeps only warnings and errors, so a passing run prints nothing at all and
only the exit code is left to say it passed; `-Dtest` picks a class, or one method with `#`:

```
(capture quiet missing)
```

One more consequence of the lifecycle lesson 1 drew: `package` comes after `test`. From now on
`mvn package` runs these tests first, and a failing one means no jar. `-DskipTests` skips them, and
it is meant for the case where something else just ran them.

## A detour: a test that never runs

Surefire does not run every class in `src/test/java`. It runs the ones whose names match its
**include patterns**, which by default are `Test*`, `*Test`, `*Tests` and `*TestCase`. Rename the
class to something that reads just as well, `IsbnChecks`:

```
(capture badname missing)
```

The class compiled (`Compiling 1 source file`), surefire ran, and the `T E S T S` banner never
appeared. **The build says `BUILD SUCCESS` and three tests checked nothing.** That is the same shape
as lesson 6's constraint that was never applied: nothing fails, so nothing looks wrong. Lesson 19
uses the same patterns on purpose, naming integration tests `*IT` so that surefire leaves them to
another plugin. Rename the class back:

```
(capture badname-back missing)
```
