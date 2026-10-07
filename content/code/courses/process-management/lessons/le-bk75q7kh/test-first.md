---
title: Writing the test first
version: 1
---

Test-first programming, usually called **test-driven development** or TDD, reverses the usual order. Before writing the code for a behaviour, you write a test for it and watch the test fail. Then you write the least code that makes it pass. Then you improve the code, with the test protecting you while you do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l04-tdd\" aria-label=\"Three steps in a loop: red, write a test that fails; green, write just enough code to pass it; refactor, improve the code while the tests still pass; then back to red.\"><defs><marker id=\"pm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"110.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"110.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">red</text><text x=\"110.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">write a test that fails</text><circle cx=\"310.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></circle><text x=\"310.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">green</text><text x=\"310.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">write just enough code to pass</text><circle cx=\"510.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.2\"></circle><text x=\"510.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">refactor</text><text x=\"510.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">improve the code, tests still passing</text><path d=\"M148.0 90.0 L272.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path><path d=\"M348.0 90.0 L472.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path><path d=\"M510 158 C510 212 110 212 110 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path></svg>", "caption": "The test-first loop. Each turn takes minutes, and the code is never more than one small step away from a state where every test passes."}
```

Beck's own phrase for the three steps is **red, green, refactor**, after the colours a test runner shows. Each turn takes minutes. The point is less the tests themselves than the rhythm: the code is never more than a few minutes from a state in which everything works.

## One turn, run for real

The example below builds the PERT formula that lesson 9 uses for estimates — the weighted average of an optimistic, a most likely and a pessimistic figure — in Python. You do not need Python for this course; if you have Python 3, you can follow along in an empty folder. The transcripts are reproduced by the lesson's `captures.sh`.

First the test, in `test_estimate.py`, before any code exists:

```python
import unittest

from estimate import pert


class PertTest(unittest.TestCase):
    def test_weights_the_most_likely_four_times(self):
        self.assertEqual(pert(3, 5, 13), 6.0)


if __name__ == "__main__":
    unittest.main()
```

Running it fails, and it should. The failure says exactly what is missing:

```
$ python3 -m unittest test_estimate
E
======================================================================
ERROR: test_estimate (unittest.loader._FailedTest.test_estimate)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_estimate
Traceback (most recent call last):
  File "/usr/lib/python3.13/unittest/loader.py", line 141, in loadTestsFromName
    module = __import__(module_name)
  File "/tmp/estimate/test_estimate.py", line 3, in <module>
    from estimate import pert
ModuleNotFoundError: No module named 'estimate'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Then just enough code, in `estimate.py`:

```python
def pert(optimistic, likely, pessimistic):
    return (optimistic + 4 * likely + pessimistic) / 6
```

```
$ python3 -m unittest test_estimate
.
----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

## The second test is where design happens

Nothing stops somebody calling `pert(13, 5, 3)` with the figures in the wrong order, and the function would return a number anyway. Writing the test for that case first forces a decision about what the function should do with nonsense, before any caller depends on the answer:

```python
    def test_refuses_an_optimistic_above_the_pessimistic(self):
        with self.assertRaises(ValueError):
            pert(13, 5, 3)
```

```
$ python3 -m unittest test_estimate
F.
======================================================================
FAIL: test_refuses_an_optimistic_above_the_pessimistic (test_estimate.PertTest.test_refuses_an_optimistic_above_the_pessimistic)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/tmp/estimate/test_estimate.py", line 11, in test_refuses_an_optimistic_above_the_pessimistic
    with self.assertRaises(ValueError):
         ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^
AssertionError: ValueError not raised

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

The code that makes both pass:

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "def pert(optimistic, likely, pessimistic):", "note": "The names say which figure is which, so a caller reading the signature knows the order."}, {"code": "    if not optimistic <= likely <= pessimistic:\n        raise ValueError(\"expected optimistic <= likely <= pessimistic\")", "note": "The second test asked for this. Figures in the wrong order are refused with a message, instead of producing a number that looks like an estimate."}, {"code": "    return (optimistic + 4 * likely + pessimistic) / 6", "note": "The first test asked for this: the most likely figure counts four times, and the six weights divide it back to an average."}]}
```

```
$ python3 -m unittest -v test_estimate
test_refuses_an_optimistic_above_the_pessimistic (test_estimate.PertTest.test_refuses_an_optimistic_above_the_pessimistic) ... ok
test_weights_the_most_likely_four_times (test_estimate.PertTest.test_weights_the_most_likely_four_times) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## What it buys, and what it costs

A team that works this way ends every few minutes with a suite of tests that describe what the code does, and that suite is what makes the late change the manifesto promised cheap: change something, run the tests, know in seconds what broke. The cost is real too. Writing the test first is slower on the first day, it needs a codebase that can be tested in small pieces, and tests written badly — tied to how the code works rather than what it does — make change more expensive instead of less. That last failure is the one to watch for in a review.
