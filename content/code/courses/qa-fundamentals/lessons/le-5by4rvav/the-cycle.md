---
title: Red, green, refactor
version: 1
---

**Test-driven development, TDD, is a way of writing code in which the test comes first: write one small test
that fails, write just enough code to make it pass, then tidy the code while the test keeps it honest.** Kent
Beck described it in *Test-Driven Development: By Example* in 2002, growing it out of XP's test-first
programming. The three steps have colours, from what the test runner shows:

1. **red**: write a test for one small thing the code does not do yet, and run it. It must fail. A test that
   passes before the code exists is testing nothing.
2. **green**: write the least code that makes the test pass. Not the elegant code, not the general code: the
   least.
3. **refactor**: improve the code, its names, its shape, the duplication, without changing what it does. Run the
   tests after every change; they say whether behaviour moved.

Then the next test, and round again. A cycle takes minutes. A feature is dozens of cycles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l15-cycle\" aria-label=\"The TDD cycle as three boxes in a loop. Red: write a test that fails. Green: the least code that passes. Refactor: tidy, tests still green. An arrow from refactor goes back to red for the next test. In the middle: one cycle takes minutes.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"225.0\" y=\"12.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"33.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">red</text><text x=\"305.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write a test that fails</text><rect x=\"400.0\" y=\"150.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">green</text><text x=\"480.0\" y=\"184.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the least code that passes</text><rect x=\"50.0\" y=\"150.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"171.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">refactor</text><text x=\"130.0\" y=\"184.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tidy, tests still green</text><path d=\"M385.0 50.0 L470.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M398.0 190.0 L212.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M130.0 148.0 L223.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"245.0\" y=\"100.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"113.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one cycle:</text><text x=\"305.0\" y=\"126.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">minutes</text></svg>", "caption": "Red, green, refactor, and round again. A feature is dozens of these."}
```

## Why the test comes first

Writing the test first sounds like a detail of order, and it changes three things.

- **The test is known to be able to fail.** It was seen red before the code existed. A test written after the
  code has never been seen failing, and a test that cannot fail, because of a typo or a wrong assertion, looks
  exactly like a test that passes.
- **The code is shaped by being used.** Writing the test means writing the call before the function exists, so
  the first person to use the code's interface is its author, before it is too late to change.
- **Every line of code has a reason.** Green means the least code; anything more has no test asking for it. The
  code that ends up existing is the code some example needed.

## What TDD is for, and what it is not

TDD is first a way of **designing** code. The checks that pile up are a valuable side effect: a regression
suite that grew one example at a time, each seen failing once.

That is why TDD does not replace testing, and why a tester on a TDD team still has a job. The tests in a TDD
suite are examples somebody thought of while writing the code. They are as good as the examples, and no better.
A developer who does not think of a student on a Wednesday writes no test for it, and the suite is green.

The rest of this lesson builds a small feature with TDD, in the lab, one cycle at a time. You will not need to
write code yourself in this course; you will need to read a test and a function side by side, and to know what
each colour means. Lessons 16 and 17 take the same cycle up a level, to examples a product owner can read.
