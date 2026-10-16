---
title: Testing in a loop, and the test that keeps growing
version: 1
---

**When a system is built in turns, every turn changes something that already worked.** The new part has to
be tested, and so does everything it might have disturbed. That second kind of testing has a name,
**regression testing**: checking that what worked before still works after a change. In a single pass
through a waterfall it happens once. In an iterative project it happens every turn, and it grows.

## Why it grows

At Cine Aurora, built in turns, the tests accumulate like this:

| turn | what is new | what has to be checked |
|---|---|---|
| 1 | the price rule | the price rule |
| 2 | orders | orders, and the price rule again, since orders call it |
| 3 | the seat map | the seat map, orders, the price rule |
| 4 | Joana's fifth sentence: half is the most | the change, and every price case, since the change touches all of them |

By the fourth turn, the testing for a small change includes everything built in the three turns before it.
The checks for turn 1 run four times; the checks for turn 4 run once. Done by hand, regression testing
grows until it is most of the testing time, which is the strongest argument there is for automating it.
`cases.py` from lesson 7 is a small instance of exactly that: the six price cases, run by a program,
again whenever anybody wants, in a second.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 280\" role=\"img\" data-fig=\"l10-regression\" aria-label=\"Four columns, one per turn. Each column stacks the checks run in that turn: turn 1, prices; turn 2, prices again and orders new; turn 3, prices and orders again and the seat map new; turn 4, prices, orders and seat map again and the rule half is the most new. The stack of checks run again grows by one block each turn.\"><rect x=\"40.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">prices</text><text x=\"95.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">turn 1</text><rect x=\"170.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prices</text><rect x=\"170.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">orders</text><text x=\"225.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">turn 2</text><rect x=\"300.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prices</text><rect x=\"300.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"300.0\" y=\"98.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">seat map</text><text x=\"355.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">turn 3</text><rect x=\"430.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prices</text><rect x=\"430.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"430.0\" y=\"98.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seat map</text><rect x=\"430.0\" y=\"54.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">half is the most</text><text x=\"485.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">turn 4</text><rect x=\"40.0\" y=\"258.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new checks</text><rect x=\"220.0\" y=\"258.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks run again</text></svg>", "caption": "The checks for the first turn run in every turn after it. Regression testing grows with the system, which is why it is the first testing teams automate."}
```

## A fix is also a change

The fix for the sixty-year-old's defect is one character: `>` becomes `>=`. It is still a change, and a
regression test is how anybody knows it changed only what it should. After the fix, sixty must pay half,
and so must sixty-one, and so must a seventy-year-old; fifty-nine must still pay full price, and the
student and the child must be untouched. A fix that makes sixty right and accidentally makes fifty-nine
wrong is a new defect, and without the old checks it would ship looking like a repair.

That is why **every defect found should leave a test behind**: the case that exposed it, kept and run
again with every later change. Over time those tests become the record of everything the system has ever
got wrong, which is exactly the list of places most likely to break again.

## Choosing what to re-run

Not every turn can afford to re-run everything, especially by hand. The choice of what to re-run is
prioritisation again, and the questions are the ones this lesson keeps coming back to: what did this
change touch, what depends on what it touched, and what has broken before? Lesson 20 gives that a method,
and `manual-testing` lesson 10 treats regression testing as a practice in its own right.

What this lesson adds is the rhythm. In the waterfall, testing was a phase that came once. From here on, in
every model the course describes, testing is a **loop**: new checks for what is new, old checks for what
might have moved, every time.
