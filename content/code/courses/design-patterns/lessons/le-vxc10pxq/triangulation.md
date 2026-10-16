---
title: "Triangulation: let the examples force the formula"
version: 1
---

**A constant that passes one test is a claim, made on purpose, that one example is not enough to
know the general rule.** The second example is what proves it. Beck called this triangulation, after
the surveyor's trick of fixing a point from two bearings: one test can be satisfied by an answer
that knows nothing, and two different tests can only be satisfied together by an answer that knows
something.

## The second example

The second line of the list is one day late, 50 cents. Add it to `test_fines.py` and keep the first:

```python
# test_fines.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)


if __name__ == "__main__":
    unittest.main()
```

Run it, this time without `-v`: a dot is a pass and an `F` a failure.

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
F.
======================================================================
FAIL: test_one_day_late_costs_50_cents (test_fines.FineTest.test_one_day_late_costs_50_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 13, in test_one_day_late_costs_50_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)
AssertionError: 150 != 50

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

The constant cannot answer 150 and 50 at once, so the old test passes and the new one fails with
`150 != 50`. Now the general rule is the simplest code that passes both, and it is the one you
would have guessed: the days between the two dates, times 50.

```python
# fines.py
def fine(due, returned):
    return (returned - due).days * 50
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## The example nobody would have written last

The third line of the list is a book returned early. If you had typed the formula straight away,
this is the case you would be least likely to test afterwards, because the formula looks finished.
Add it:

```python
# test_fines.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)

    def test_returned_early_costs_nothing(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
.F.
======================================================================
FAIL: test_returned_early_costs_nothing (test_fines.FineTest.test_returned_early_costs_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 16, in test_returned_early_costs_nothing
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)
AssertionError: -100 != 0

----------------------------------------------------------------------
Ran 3 tests in 0.000s

FAILED (failures=1)
```

`-100 != 0`. **The library would have owed a member 100 cents for bringing a book back early**,
and the formula that looked finished would have shipped it. The fix is one call:

```python
# fines.py
def fine(due, returned):
    return max((returned - due).days, 0) * 50
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

The fourth line, returned on the due date, would pass the moment it was written: zero days times
50 is zero. A test that passes the first time it runs drives no code, so it is not a TDD step. Keep
it anyway if the boundary is worth recording; a reader of the tests learns that the due date itself
is free.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l13-steps\" aria-label=\"Three turns of the cycle for the fine calculator, left to right in time. Turn 1: the test added is three days late costs 150; the red run said No module named fines; the code that passed was return 150. Turn 2: one day late costs 50; the red run said 150 != 50; the code became the days between the dates times 50. Turn 3: two days early costs nothing; the red run said -100 != 0; the code became max of the days and zero, times 50. Each turn adds one test and changes the code only as far as that test demands.\"><defs><marker id=\"l13-steps-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"112.0\" y=\"78.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">test added</text><text x=\"112.0\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">the red run said</text><text x=\"112.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">code that passes</text><text x=\"228.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">turn 1</text><rect x=\"138.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 days late → 150</text><rect x=\"138.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">No module named 'fines'</text><rect x=\"138.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"148.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return 150</text><path d=\"M228.0 93.0 L228.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M228.0 153.0 L228.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"424.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">turn 2</text><rect x=\"334.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 day late → 50</text><rect x=\"334.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">150 != 50</text><rect x=\"334.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"344.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return (returned - due)</text><text x=\"360.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.days * 50</text><path d=\"M424.0 93.0 L424.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M424.0 153.0 L424.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"620.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">turn 3</text><rect x=\"530.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 days early → 0</text><rect x=\"530.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-100 != 0</text><rect x=\"530.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return max((returned - due)</text><text x=\"556.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.days, 0) * 50</text><path d=\"M620.0 93.0 L620.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M620.0 153.0 L620.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M140.0 252.0 L700.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"420.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">time: one test per turn</text></svg>", "caption": "The formula was never designed in one go. Each example removed one thing the previous code got wrong."}
```

## Three ways to get to green

Beck names three strategies, and a practised hand moves between them during the same hour.

| strategy | what you write to pass | when it fits |
|---|---|---|
| fake it | a constant, then replace it bit by bit | you are unsure what the general code is |
| triangulate | a second example that the fake cannot pass | the generalisation is not obvious from one case |
| obvious implementation | the real code, straight away | you know exactly what to type, and are right |

**The obvious implementation is allowed; it is not the default.** When you type the real thing and
the test goes red in a way you did not expect, that surprise is the signal to drop back to smaller
steps. Beck's phrase for the small ones is *baby steps*, and the size is a gear rather than a rule:
long strides on familiar ground, a constant at a time where you keep being surprised.

What the steps protect is the time between two green runs. With one test and three lines between
them, a red run has one possible cause and you can see it. With ten new lines and four new tests,
the same red run is a debugging session.
