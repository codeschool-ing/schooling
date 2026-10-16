---
title: Refactoring under green, and one more red
version: 1
---

**Refactoring is changing the shape of code without changing what it does, and the tests are what make it
safe.** With three green tests, Rafael can rewrite `apply` any way he likes; if the rewrite changes behaviour that
an example covers, a test turns red at once.

## The refactor

Joana has already said a second coupon is coming. An `if` per code would grow into a list nobody can read, so
Rafael moves the codes into a table and leaves the function to look them up:

```python
# coupons.py
COUPONS = {"PIPOCA": 500}


def apply(code, total):
    off = COUPONS.get(code.upper(), 0)
    return total - off
```

`COUPONS.get(key, 0)` gives the discount for a known code and 0 for any other, which covers the unknown code
without an `if`. Nothing new is promised, so no new test is written. The old ones are run:

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Still green, three of three. That line is the whole safety of a refactor, and it is only as wide as the examples.
If no test covered lowercase codes, this rewrite could have dropped `.upper()` and every test would still pass.

## One more red: what Célia pasted

A week of use at the box office produced the fourth example. Célia copies codes out of the cinema's messages and
pastes them, and the paste sometimes brings a space with it. `" PIPOCA "` with spaces is not in the table, so the
customer paid full price. Lia wrote it up as a defect, and Rafael's first move, before touching the code, was to
turn the report into a test:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)

    def test_an_unknown_code_changes_nothing(self):
        self.assertEqual(apply("XYZ", 3600), 3600)

    def test_the_code_is_read_in_any_case(self):
        self.assertEqual(apply("pipoca", 2800), 2300)

    def test_spaces_around_the_code_are_ignored(self):
        self.assertEqual(apply(" PIPOCA ", 3600), 3100)


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored) ... FAIL
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

======================================================================
FAIL: test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 17, in test_spaces_around_the_code_are_ignored
    self.assertEqual(apply(" PIPOCA ", 3600), 3100)
AssertionError: 3600 != 3100

----------------------------------------------------------------------
Ran 4 tests in 0.000s

FAILED (failures=1)
```

This is the habit worth taking from TDD even into teams that do not practise it: **a defect is reproduced as a
failing test before it is fixed.** The red run proves the test catches the defect; the green run after the fix
proves the fix works; and the test stays, so the defect cannot come back unnoticed. It is lesson 4's
reproduction steps, written so a machine can repeat them every day.

```python
# coupons.py
COUPONS = {"PIPOCA": 500}


def apply(code, total):
    off = COUPONS.get(code.strip().upper(), 0)
    return total - off
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 4 tests in 0.000s

OK
```

## What the four tests do not say

Four green tests, and Lia still has questions none of them answers. May two coupons be used on one order? Does
PIPOCA combine with the Wednesday discount, the question from lesson 12's planning? Can a total go below zero?
Is the R$ 5,00 off each ticket or off the order? The suite cannot raise these, because a test only exists once
somebody has asked. **A green TDD suite is a record of the questions that were asked, not a proof that the right
ones were.** Asking the rest is still a person's job, and the next two lessons are about asking them early, in a
form everybody can read.
