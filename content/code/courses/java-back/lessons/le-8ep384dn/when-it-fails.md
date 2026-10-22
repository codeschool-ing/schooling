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
(capture break missing)
```

And run the tests:

```
(capture fail-run missing)
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

So the broken rule refuses a real book, and the reason is arithmetic. Frankenstein's twelve digits
add up to 70. The real rule gives `(10 - 0) % 10`, which is 0, and the ISBN ends in 0. The broken one
gives `10 - 0`, which is 10, and no single digit is ever 10. **Every ISBN whose check digit is 0 is
now refused**, about one in ten of all the books there are, and all the other ISBNs still pass.

## The same bug, and a green build

Now take Frankenstein out of the list, as if it had never been written:

```
(capture no-frankenstein missing)
```

**Nine tests, no failure, `BUILD SUCCESS`, and the rule is still broken.** None of the three ISBNs
left ends in 0, so none of them can see the difference. A passing test says that the cases somebody
wrote down behave as written down, and nothing about the ones nobody did. That is why the row for
Frankenstein is in the final `IsbnTest`: it is the one input that tells the two rules apart. Choosing rows is the actual work of writing a test, and the question to ask of each one is
what mistake it would catch.

Put both files back, the rule and the test, and check that everything passes again:

```
(capture restore missing)
```

