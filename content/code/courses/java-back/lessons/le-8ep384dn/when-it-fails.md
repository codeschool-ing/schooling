---
title: A failing test, read
version: 1
---

A test earns its keep on the day it fails, and that day is no time to be learning to read the
output. So break the rule on purpose. The check digit is the distance from the sum up to the next
multiple of ten, and lesson 6 explained the outer `% 10` in `(10 - sum % 10) % 10`: it is there for a
sum that already ends in 0. It is also exactly the kind of thing somebody tidies away as redundant.
Do that:

```
ana@vm:~/bookshop$ sed -i 's/int check = (10 - sum % 10) % 10;/int check = 10 - sum % 10;/' src/main/java/com/example/bookshop/catalogue/Isbn.java && grep -n 'int check' src/main/java/com/example/bookshop/catalogue/Isbn.java
18:        int check = 10 - sum % 10;
```

And run the tests:

```
ana@vm:~/bookshop$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] Copying 4 resources from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 33 source files with javac [debug parameters release 25] to target/classes
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed dependency.
[INFO] Compiling 1 source file with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[ERROR] Tests run: 10, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.237 s <<< FAILURE! -- in com.example.bookshop.catalogue.IsbnTest
[ERROR] com.example.bookshop.catalogue.IsbnTest.acceptsAValidIsbn13(String)[3] -- Time elapsed: 0.009 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <true> but was: <false>
	at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:158)
	at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:139)
	at org.junit.jupiter.api.AssertTrue.failNotTrue(AssertTrue.java:69)
	at org.junit.jupiter.api.AssertTrue.assertTrue(AssertTrue.java:41)
	at org.junit.jupiter.api.AssertTrue.assertTrue(AssertTrue.java:35)
	at org.junit.jupiter.api.Assertions.assertTrue(Assertions.java:195)
	at com.example.bookshop.catalogue.IsbnTest.acceptsAValidIsbn13(IsbnTest.java:16)

[INFO] 
[INFO] Results:
[INFO] 
[ERROR] Failures: 
[ERROR]   IsbnTest.acceptsAValidIsbn13:16 expected: <true> but was: <false>
[INFO] 
[ERROR] Tests run: 10, Failures: 1, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.494 s
[INFO] Finished at: 2026-10-22T20:20:36-03:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test (default-test) on project bookshop: There are test failures.
[ERROR] 
[ERROR] See /home/ana/bookshop/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

## Reading it

Start from the bottom again, and then go to the one place that says what happened.

- **`BUILD FAILURE`**, and Maven exits with a non-zero code. `mvn package` would have stopped here
  too, and no jar would have been built.
- **`Tests run: 10, Failures: 1`**: one of the ten invocations failed, the other nine passed.
- **The summary line** under `Failures:` is the short form: class, method, the line of the test that
  failed (`:16`) and the message.
- **The block in the middle is the long form.** Its first line names the test,
  `IsbnTest.acceptsAValidIsbn13(String)[3]`. Its second is the exception and its message. Then the
  stack trace, which is mostly JUnit's own frames; the one that matters is the last, the line of
  your test, `IsbnTest.java:16`, which is the `assertTrue` call.

The message is the weak part: `expected: <true> but was: <false>`. It is true and it says nothing
about books. **`assertTrue` only ever sees a boolean**, so that is all it can report. What does say
something is the index: `[3]`, the third value of the `@ValueSource`, which is `9786500000030`,
Frankenstein. The display names of the previous section would have printed it outright.

So the broken rule refuses a real book, and the reason is arithmetic. The weighted products of
Frankenstein's first twelve digits add up to 70. The real rule gives `(10 - 0) % 10`, which is 0, and the ISBN ends in 0. The broken one
gives `10 - 0`, which is 10, and no single digit is ever 10. **Every ISBN whose check digit is 0 is
now refused**, roughly one book in ten, and every other ISBN still passes.

## The same bug, and a green build

Now take Frankenstein out of the list, as if it had never been written:

```
ana@vm:~/bookshop$ sed -i 's/"9786500000023", "9786500000030", /"9786500000023", /' src/test/java/com/example/bookshop/catalogue/IsbnTest.java && grep -n '@ValueSource' src/test/java/com/example/bookshop/catalogue/IsbnTest.java
14:    @ValueSource(strings = {"9786500000016", "9786500000023", "9780306406157"})
ana@vm:~/bookshop$ mvn test | grep -E "Tests run:|BUILD"
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.178 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

**Nine tests, no failure, `BUILD SUCCESS`, and the rule is still broken.** None of the three ISBNs
left ends in 0, so none of them can see the difference. A passing test says that the cases somebody
wrote down behave as written down, and nothing about the ones nobody did. That is why the row for
Frankenstein is in the final `IsbnTest`: it is the one input that tells the two rules apart.
Choosing rows is the actual work of writing a test, and the question to ask of each one is what
mistake it would catch.

Put both files back, the rule and the test, and check that everything passes again:

```
ana@vm:~/bookshop$ sed -i 's/int check = 10 - sum % 10;/int check = (10 - sum % 10) % 10;/' src/main/java/com/example/bookshop/catalogue/Isbn.java
ana@vm:~/bookshop$ sed -i 's/"9786500000023", /"9786500000023", "9786500000030", /' src/test/java/com/example/bookshop/catalogue/IsbnTest.java && grep -n '@ValueSource' src/test/java/com/example/bookshop/catalogue/IsbnTest.java
14:    @ValueSource(strings = {"9786500000016", "9786500000023", "9786500000030", "9780306406157"})
ana@vm:~/bookshop$ mvn -q test; echo "exit $?"
exit 0
```

