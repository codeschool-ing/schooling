---
title: "Red, green, refactor: the cycle"
version: 1
---

**Test-driven development is often described as "writing tests", and a team with a large test
suite will say it does TDD. Neither is the idea.** TDD is a way of writing the code itself: the
next small piece of behaviour is first written down as a test that fails, and the code exists to
make that test pass. The suite at the end is a by-product. Kent Beck gave the method its name and
its book, *Test-Driven Development: By Example*, in 2002, and the loop he described has three
steps that never change order.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-cycle\" aria-label=\"The red-green-refactor cycle as three boxes joined by arrows in a loop. Red: write one test for the next behaviour and run it; it must fail, for the reason you expect. An arrow labelled &quot;one test fails&quot; leads to green: write the least code that passes; a constant or a copied line is allowed. An arrow labelled &quot;every test passes&quot; leads to refactor: improve names and structure, add no behaviour, run the tests after every move. An arrow labelled &quot;next line of the list&quot; leads back to red. In the middle: one turn takes a minute or two.\"><defs><marker id=\"l13-cycle-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14.0\" y=\"24.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"150.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">red</text><text x=\"150.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write one test for the next behaviour</text><text x=\"150.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run it: it fails, for the reason expected</text><rect x=\"434.0\" y=\"24.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"570.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">green</text><text x=\"570.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write the least code that passes</text><text x=\"570.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a constant or a copied line is allowed</text><rect x=\"224.0\" y=\"216.0\" width=\"272.0\" height=\"92.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">refactor</text><text x=\"360.0\" y=\"266.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">improve names and structure, no new behaviour</text><text x=\"360.0\" y=\"281.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the tests after every move</text><path d=\"M289.0 70.0 L431.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one test fails</text><path d=\"M570.0 118.0 L570.0 262.0 L499.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"578.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">every test passes</text><path d=\"M221.0 262.0 L150.0 262.0 L150.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-cycle-dp-ah-paper-dim)\"></path><text x=\"142.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">next line of the list</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--amber)\">one turn: a minute or two</text></svg>", "caption": "The loop never changes order. Only the green step may be sloppy, and only the refactor step may change structure."}
```

**Red.** Write one test for the next thing the code should do, run it, and watch it fail. The
failure has to be the one you expected. A test that fails because the file has a syntax error has
told you nothing about the behaviour.

**Green.** Write the least code that makes the test pass. The rules relax here on purpose: a
constant, a copy of a line, an `if` that only covers this case are all allowed. The aim is to get
back to a passing suite in seconds, not to write the final version.

**Refactor.** With every test passing, improve the code that is there: remove the duplication the
green step left, give things better names, split a function that grew. You add no behaviour in this
step, and you run the tests after each change. If they go red, you undo the change rather than
debug it.

Then the loop starts again with the next test. One turn is a couple of minutes. A turn that has
taken twenty is a sign the step was too big, which the section on triangulation takes up.

## Why the red run is not a formality

A test you have never seen fail may not be testing anything. It can assert the wrong thing, call
the wrong function, or never run at all, and every one of those looks exactly like a pass. **The
red run is the only evidence that the test can tell working code from broken code.** The next
section shows a test file that asserts a wrong answer and is still reported clean, because a single
missing word kept the test from running.

## The list before the first test

Beck starts by writing down the tests he can think of, as a plain list, and crosses them off. It is
not a specification; it grows as the work shows what was missed. For the library's fine calculator
of this lesson, the list starts with four lines:

- a book returned three days late costs 150 cents;
- one day late costs 50 cents;
- returned early, it costs nothing;
- returned on the due date, it costs nothing.

The order matters more than it looks. The first test is chosen to be easy to pass and to force a
decision about the interface: what the function is called, what it takes, what it returns. The
hard cases come once the shape exists.

## The cycle in your language

The tools differ and the loop does not. Every one of the four languages has a test runner that
prints a failure with the expected and the actual value side by side, which is all the cycle needs.

| language | a test | run with |
|---|---|---|
| Python | `def test_three_days_late(self):` in a `unittest.TestCase`, or a bare function for pytest | `python3 -m unittest -v` |
| Java | a method annotated `@Test`, with JUnit 5's `assertEquals(150, fine(...))` | `mvn test` or `gradle test` |
| Go | `func TestThreeDaysLate(t *testing.T)` in a `_test.go` file | `go test` |
| TypeScript | `test("three days late", () => expect(fine(...)).toBe(150))` with Jest or Vitest | `npx vitest` |

One difference catches people moving between them: JUnit's `assertEquals` takes the expected value
first, while Python's `assertEqual(first, second)` has no opinion and prints `first != second`. This
lesson always puts the value the code returned first, so a failure reads as *got* `!=` *wanted*.
