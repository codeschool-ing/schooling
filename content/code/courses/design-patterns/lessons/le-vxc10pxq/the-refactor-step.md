---
title: The refactor step, the one people skip
version: 1
---

**The step most often skipped is the third, and skipping it turns TDD into a way of producing
untidy code quickly.** Red and green are about behaviour. Refactor is where the design gets better,
and it is the only step where the code is changed with the explicit promise that its behaviour does
not. The tests written in the first two steps are what make that promise checkable.

The calculator passes three tests and has two things a reader would trip on. The `50` has no name,
so the next person has to guess whether it is cents, days or a percentage. And the counting of days
late is folded into the money, so a screen that wanted to say "3 days late" would have to repeat the
arithmetic. Neither is a bug. Both are what the refactor step is for.

## One move, then run

Name the number and pull the day count into a function of its own. It is a single move, and the
tests run straight after it. This time the file runs itself, through the `unittest.main()` at the
bottom, which prints the same report without the `-m unittest`:

```python
# fines.py
from datetime import date

DAILY_FINE = 50  # cents


def days_late(due: date, returned: date) -> int:
    return max((returned - due).days, 0)


def fine(due: date, returned: date) -> int:
    return days_late(due, returned) * DAILY_FINE
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Same three tests, same answers, a better file. The type hints arrived in the same move, and that is
acceptable because they change nothing that runs.

## The net catching a slip

Now suppose that while extracting `days_late` you had typed the subtraction the other way round,
which is the commonest slip in date arithmetic:

```python
    return max((due - returned).days, 0)
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
FFF
======================================================================
FAIL: test_one_day_late_costs_50_cents (__main__.FineTest.test_one_day_late_costs_50_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 13, in test_one_day_late_costs_50_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)
AssertionError: 0 != 50

======================================================================
FAIL: test_returned_early_costs_nothing (__main__.FineTest.test_returned_early_costs_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 16, in test_returned_early_costs_nothing
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)
AssertionError: 100 != 0

======================================================================
FAIL: test_three_days_late_costs_150_cents (__main__.FineTest.test_three_days_late_costs_150_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 10, in test_three_days_late_costs_150_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)
AssertionError: 0 != 150

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=3)
```

All three tests fail within a second of the change, and each failure names the case that broke.
**This is the moment the refactor step depends on**: the slip is found while it is one line old and
the cause is the only thing that changed. The right response is to undo the edit and redo it, not to
start reasoning about which sign is right. If you had made five moves before running, the same
output would be a puzzle.

## The tests are code too

The test file has its own duplication: the due date is written three times, and each return date
makes the reader count days on a calendar to see what is being tested. Refactor it under the same
rule, with the production code left alone, so that a red run can only mean the test broke:

```python
# test_fines.py
import unittest
from datetime import date, timedelta

from fines import fine

DUE = date(2026, 3, 16)


def returned(days_after_due: int) -> date:
    return DUE + timedelta(days=days_after_due)


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(DUE, returned(3)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(DUE, returned(1)), 50)

    def test_returned_early_costs_nothing(self):
        self.assertEqual(fine(DUE, returned(-2)), 0)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/tdd$ python3 test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

`returned(3)` says three days late without a calendar. A test is read far more often than it is
written, usually by somebody trying to find out what the code is supposed to do, and the refactor
step is where it becomes readable.

## The rules of the step

- Refactor only on green. A change made while a test is red mixes two questions, and you cannot
  tell which one a later failure answers.
- Change structure, never behaviour. A new case is a new test and a new red, on the next turn.
- One move at a time, then run. The tests take a fraction of a second; there is no saving in
  batching moves.
- Change either the code or its tests in one move, not both. If both changed and the run is green,
  nothing checked the change.

Each move here has a name in Martin Fowler's catalogue of refactorings: *extract function*,
*replace magic literal*. Lesson 14 takes the catalogue up properly, along with the smells that tell
you which move a piece of code needs.
