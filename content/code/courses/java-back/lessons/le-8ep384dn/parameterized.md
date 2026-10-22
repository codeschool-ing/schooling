---
title: One test, many inputs
version: 1
---

The first `IsbnTest` checks one valid ISBN and one wrong one. The rule has more ways to go wrong than
that: twelve digits, fourteen, a hyphen, a letter. Copying a method five times to change one string
is how test classes grow to a thousand lines that nobody reads. A **parameterised test** is one
method that JUnit runs once per argument, and reports once per argument.

Replace `IsbnTest.java` with its final version:

```schooling-example
{
  "language": "java",
  "file": "IsbnTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport static org.junit.jupiter.api.Assertions.assertFalse;\nimport static org.junit.jupiter.api.Assertions.assertTrue;\n\nimport org.junit.jupiter.api.Test;\nimport org.junit.jupiter.params.ParameterizedTest;\nimport org.junit.jupiter.params.provider.CsvSource;\nimport org.junit.jupiter.params.provider.ValueSource;\n",
      "note": "Three new imports from `junit-jupiter-params`: the annotation that makes a method parameterised, and two **sources** that feed it arguments. `@Test` stays for the one case with no input to vary."
    },
    {
      "code": "class IsbnTest {\n\n    @ParameterizedTest\n    @ValueSource(strings = {\"9786500000016\", \"9786500000023\", \"9786500000030\", \"9780306406157\"})\n    void acceptsAValidIsbn13(String isbn) {\n        assertTrue(Isbn.isValid(isbn));\n    }\n",
      "note": "`@ValueSource` gives one argument per invocation, here four strings, so this method runs four times with `isbn` set to each. Frankenstein's `9786500000030` is the only one whose check digit is 0, and the next section shows what that is worth."
    },
    {
      "code": "    @ParameterizedTest(name = \"{1}: {0}\")\n    @CsvSource({\n            \"9786500000017, wrong check digit\",\n            \"978650000001, twelve digits\",\n            \"97865000000160, fourteen digits\",\n            \"978-6500000016, a hyphen\",\n            \"97865000000X6, a letter\"\n    })\n    void refusesAnythingElse(String isbn, String reason) {\n        assertFalse(Isbn.isValid(isbn));\n    }\n",
      "note": "`@CsvSource` gives one row per invocation, split at the commas into the method's parameters: the ISBN, and a few words on what is wrong with it. The assertion never reads `reason`. It is there for the name: `\"{1}: {0}\"` names each invocation by its second argument, then its first."
    },
    {
      "code": "    @Test\n    void refusesNull() {\n        assertFalse(Isbn.isValid(null));\n    }",
      "note": "`null` cannot be written in a `@ValueSource` of strings, so it keeps a plain test of its own. Jupiter also has `@NullSource` for this; a separate method keeps the case visible by its name."
    },
    {
      "code": "}"
    }
  ]
}
```

Run only this class with `-Dtest`, and keep the lines that count:

```
ana@vm:~/bookshop$ mvn test -Dtest=IsbnTest | grep -E "Running|Tests run|BUILD"
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.152 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

**Ten tests from three methods**: four invocations of the first, five of the second and one plain
test. Surefire counts each invocation as a test, and a failure in one of them fails that one only;
the other nine still run and still report.

## The names, and who prints them

Surefire's report names an invocation by its method's signature and its index:

```
ana@vm:~/bookshop$ grep -o "testcase name=\"[^\"]*\"" target/surefire-reports/TEST-com.example.bookshop.catalogue.IsbnTest.xml
testcase name="refusesNull"
testcase name="acceptsAValidIsbn13(String)[1]"
testcase name="acceptsAValidIsbn13(String)[2]"
testcase name="acceptsAValidIsbn13(String)[3]"
testcase name="acceptsAValidIsbn13(String)[4]"
testcase name="refusesAnythingElse(String, String)[1]"
testcase name="refusesAnythingElse(String, String)[2]"
testcase name="refusesAnythingElse(String, String)[3]"
testcase name="refusesAnythingElse(String, String)[4]"
testcase name="refusesAnythingElse(String, String)[5]"
```

That is all Maven will ever print about them, and `[3]` does not say which ISBN was third. The
`name` pattern written on `refusesAnythingElse` is for whatever prints JUnit's own **display
names**. An IDE's test window does: IntelliJ IDEA, Eclipse and VS Code all draw the tree of tests
under those names. In the terminal, JUnit's **console launcher** does, and it takes two commands to
get. The first copies the launcher, a single jar on Maven Central, into `target`; the second writes
the test classpath to a file:

```
ana@vm:~/bookshop$ mvn -q dependency:copy -Dartifact=org.junit.platform:junit-platform-console-standalone:6.0.3 -DoutputDirectory=target
ana@vm:~/bookshop$ mvn -q dependency:build-classpath -Dmdep.outputFile=target/test.cp
```

Then run the class through it. `--details=testfeed` prints a line as each test starts and as it
ends, and `grep -v STARTED` keeps the second of the two:

```
ana@vm:~/bookshop$ java -jar target/junit-platform-console-standalone-6.0.3.jar execute --disable-banner --disable-ansi-colors --details=testfeed --class-path "target/test-classes:target/classes:$(cat target/test.cp)" --select-class com.example.bookshop.catalogue.IsbnTest | grep -v STARTED
JUnit Jupiter > IsbnTest > refusesNull() :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [1] isbn = "9786500000016" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [2] isbn = "9786500000023" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [3] isbn = "9786500000030" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [4] isbn = "9780306406157" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "wrong check digit": "9786500000017" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "twelve digits": "978650000001" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "fourteen digits": "97865000000160" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "a hyphen": "978-6500000016" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "a letter": "97865000000X6" :: SUCCESSFUL

Test run finished after 251 ms
[         6 containers found      ]
[         0 containers skipped    ]
[         6 containers started    ]
[         0 containers aborted    ]
[         6 containers successful ]
[         0 containers failed     ]
[        10 tests found           ]
[         0 tests skipped         ]
[        10 tests started         ]
[         0 tests aborted         ]
[        10 tests successful      ]
[         0 tests failed          ]
```

Two kinds of name are there. `acceptsAValidIsbn13` has no pattern, so each invocation is named by
JUnit's default, `[index] parameter = value`: the ISBN can be read, and so can its position in the
list. `refusesAnythingElse` has `"{1}: {0}"`, so its invocations are named `"wrong check digit":
"9786500000017"` and so on, the reason first. Both are better than `[3]`; the second reads as a list
of the cases the rule refuses, which is what a reviewer wants to check is complete.

The launcher's own summary at the bottom counts **containers** as well as tests. The six
containers are the three engines the launcher jar carries (it brings JUnit Vintage and a suite
engine along with Jupiter, whether the project uses them or not), the class, and the two
parameterised methods. The ten tests are the invocations and the plain test, as surefire counted.

## When to stop adding rows

A parameterised test makes rows cheap, and cheap rows multiply. Each row should be a case the rule
treats differently: a row per way to be invalid, and a valid ISBN per thing the arithmetic does
differently. Five more valid ISBNs that all end in a non-zero check digit add five lines to the
report and nothing to what is known. The next section shows the one row in this class that earns
its place more than any other.
