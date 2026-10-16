---
title: The acceptance test comes first
version: 1
---

**Acceptance test-driven development, ATDD, is TDD one level up: before a story is built, the team agrees on
the tests that will decide whether it is accepted, and the story is done when they pass.** Where TDD's tests
are written by a developer about a function, ATDD's are written by the team about a story, in examples the
product owner agrees with.

The ideas arrived under several names in the late 2000s, and they overlap so much that the names are often
used for the same thing: *acceptance test-driven development*, from Ken Pugh's book of 2011; *specification by
example*, from Gojko Adzic's book of the same year; and BDD, from lesson 16. A useful way to keep them apart is by
what each one stresses.

| name | what it stresses |
|---|---|
| TDD | a developer's test before a developer's code, a unit at a time |
| BDD | a shared language for behaviour, and the conversation that finds the examples |
| ATDD | the acceptance tests for a story agreed by the team before the story is started |
| specification by example | the examples *are* the specification; there is no separate document to drift away from them |

In practice a team doing ATDD usually writes its acceptance tests in Gherkin and runs them with a BDD tool, so the
difference is one of emphasis. What ATDD adds to lesson 16 is a rule about **timing and agreement**: the tests
exist, and the product owner has said yes to them, before anybody starts building.

## Two loops

ATDD and TDD fit together as two loops, one inside the other. The outer loop starts with an acceptance test for
the story, which fails. Inside it, the developer runs as many TDD cycles as it takes to build the parts. The outer
test passes when the story does what was agreed, and only then is it done.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 220\" role=\"img\" data-fig=\"l17-loops\" aria-label=\"Two loops. The outer loop is the story: it starts with an acceptance test that the team agreed and that fails, and ends when the acceptance test passes and the story is done. Inside it, the inner loop is TDD, red, green, refactor, run many times to build the parts.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"10.0\" width=\"640.0\" height=\"200.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"24.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">outer loop: the story</text><rect x=\"24.0\" y=\"80.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">acceptance test</text><text x=\"89.0\" y=\"111.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">agreed, fails</text><rect x=\"506.0\" y=\"80.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"571.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">acceptance test</text><text x=\"571.0\" y=\"111.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">passes: done</text><rect x=\"180.0\" y=\"48.0\" width=\"300.0\" height=\"140.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">inner loop: TDD, many times</text><rect x=\"196.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">red</text><path d=\"M277.0 126.0 L289.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">green</text><path d=\"M371.0 126.0 L383.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"384.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">refactor</text><path d=\"M440 144 C 440 175, 236 175, 236 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M156.0 105.0 L178.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M482.0 105.0 L504.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path></svg>", "caption": "ATDD around TDD. The outer test is agreed with the product owner; the inner ones are the developer’s."}
```

The outer test changes what *done* means. In lesson 12, Cine Aurora's definition of done required that "each
acceptance criterion has a test, and the tests pass". ATDD is how that line is met without a scramble at the end of
the sprint: the tests were written on day one, from the criteria, and the work is the act of turning them green.

## Why it matters to a tester

The acceptance tests are where a tester's questions become binding. In lesson 12 the questions improved the
criteria; in lesson 16 they became scenarios. In ATDD they become **the definition of the story**, agreed before
the code, run every day, and impossible to quietly drop at the end of a sprint because they are red.

It also changes when the tester works. On a team where testing happens after building, the tester's busiest day
is the last one. On an ATDD team, it is the first: the examples are written before the developers start, and the
tester's job during the sprint shifts to exploration, the thing the agreed tests cannot do.
