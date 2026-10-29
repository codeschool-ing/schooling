---
title: The pyramid, and what it is for
version: 1
---

**A test pyramid is an argument about money: where to spend the effort of testing so that a mistake
is found quickly and cheaply.** The expensive tests are kept for what only they can find. It is
not a rule about how many tests of each kind to write, and the people who drew it never said it was.

Mike Cohn drew the first one in 2009, in *Succeeding with Agile*. At the bottom is a wide base of
**unit tests**, which check one function or class on its own and run in milliseconds. Above them is
a narrower band of **integration tests**, which check that pieces work together. At the top is a
small tip of tests that drive the whole application through its user interface, which he called UI
tests and most people now call **end-to-end tests**. The shape says what to have the most of.

## Why the bottom is wide

A test is worth what it catches minus what it costs, and the cost has three parts. **Writing it.**
**Running it**: a unit test of `weekTotal` runs in a fraction of a millisecond, and a test that starts
a browser, opens a page and clicks takes about a second. **Believing it**: when a unit test fails it
points at one function, and when an end-to-end test fails the fault can be anywhere between the
data file and the CSS, or in the test's own timing. A failure that takes an hour to locate costs more
than the test that found it.

So the further down a test sits, the more of them you can afford, and the closer each one is to the
line that broke. The further up, the more of the real system it uses, and the more confident a pass
makes you that a person could actually do the thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-shapes\" aria-label=\"Two shapes side by side. On the left, the testing pyramid: a wide base of unit tests, a narrower band of integration tests above it, and a small tip of end-to-end tests. On the right, the testing trophy: a thin base of static checks, a small band of unit tests, a wide band of integration tests, and a small top of end-to-end tests. An arrow beside them says that towards the top a test is slower, costs more to keep and gives more confidence that the whole works; towards the bottom it is faster, cheaper and closer to the line that broke.\"><defs><marker id=\"l01-shapes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><polygon points=\"150.0,40 150.0,40 192.0,100 108.0,100\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">end-to-end</text><polygon points=\"108.0,100 192.0,100 236.0,160 64.0,160\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">integration</text><polygon points=\"64.0,160 236.0,160 280.0,220 20.0,220\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polygon><text x=\"150\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unit</text><text x=\"150\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the pyramid</text><rect x=\"405.0\" y=\"40\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">end-to-end</text><rect x=\"365.0\" y=\"86\" width=\"210\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">integration</text><rect x=\"415.0\" y=\"174\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unit</text><rect x=\"380.0\" y=\"214\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">static</text><text x=\"470\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the trophy</text><path d=\"M640 230 L640 50\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-shapes-ah-amber)\" marker-start=\"url(#l01-shapes-ah-amber)\"></path><text x=\"634\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">slower, dearer to keep,</text><text x=\"634\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">more confidence in the whole</text><text x=\"634\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">faster, cheaper,</text><text x=\"634\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">closer to the broken line</text></svg>", "caption": "Cohn's pyramid (2009) and Dodds's trophy (2018) agree on the axis and disagree on where most tests should sit. For a front-end, the trophy's wide middle is where the bugs the user sees are."}
```

## The front-end bends the shape

Kent C. Dodds drew the **testing trophy** in 2018 for applications like this one. It adds a base the
pyramid did not have, **static** checks, which find mistakes without running anything: the type
checker reading every file, a linter. And it makes the integration band the widest, for a reason
specific to the front-end. Most of what goes wrong in a browser app is not in a function that adds
numbers. It is between the pieces: a form that reads the wrong field, a button wired to nothing, a
total that does not redraw. A unit test of each piece passes while the screen is broken, and a test
of the pieces together, still fast and still without a real browser, is the one that sees it.

The two shapes disagree about proportions and agree about everything else: **test each thing at the
lowest level that can see it fail**, and climb only when the lower level cannot.

## What "integration" means here

The word means different things to different people, and this course pins it down. A **component
test** renders part of the user interface into a simulated page and works it the way a person would:
types into a field, presses a button, reads what appears. It needs no server and no browser, and runs
in tens of milliseconds. That is the trophy's wide middle for a front-end, and lessons 2 and 3 are
about it. An integration test in the sense a back-end developer means, the app talking to a real
database or service, is a back-end subject and not this course's.
