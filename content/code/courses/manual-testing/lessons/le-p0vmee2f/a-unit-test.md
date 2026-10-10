---
title: A unit test of the discount
version: 1
---

The function under test is the one release 1.1 changed. In lesson 1 it was a series of `if`
statements; lesson 9 replaced it with one line:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    return max(10 if member else 0, 15 if tickets >= 5 else 0)
```

It takes three facts about an order and returns a percentage. It reads no form, prints no page and
needs no server, which is what makes it a **unit**: something that can be called on its own, with
inputs a test chooses, and whose answer can be checked against the requirement. R5 says students
pay half, members get 10%, five tickets or more get 15%, and the largest discount applies. Five
calls cover that rule, and the test file below makes them.

## The test file

Save it as `test_discount.py`, in `~/boxoffice` beside `boxoffice.py`. The copy button takes the
whole file without the notes:

```schooling-example
{"language": "python", "file": "test_discount.py", "parts": [
 {"code": "import unittest\n\nfrom boxoffice import discount\n\n", "note": "`unittest` comes with Python, so there is nothing to install. The second import takes one function out of `boxoffice.py`, which is why the two files sit in the same directory."},
 {"code": "class DiscountTest(unittest.TestCase):\n", "note": "A class gathers the tests of one thing. Every method in it whose name starts with `test_` is one test, and the runner finds them by that prefix."},
 {"code": "    def test_nobody(self):\n        self.assertEqual(discount(student=False, member=False, tickets=1), 0)\n", "note": "One test is one row of lesson 5's decision table: the conditions go in as arguments, and `assertEqual` compares what came back with what R5 says. Nobody special, one ticket: 0% off."},
 {"code": "    def test_member(self):\n        self.assertEqual(discount(student=False, member=True, tickets=2), 10)\n\n    def test_five_tickets(self):\n        self.assertEqual(discount(student=False, member=False, tickets=5), 15)\n\n    def test_member_and_five(self):\n        self.assertEqual(discount(student=False, member=True, tickets=5), 15)\n", "note": "A member, a group, and a member with a group. The third is the rule that discounts do not add up, and it is the row lesson 5 found broken: version 1.0 returned 25 here."},
 {"code": "    def test_student(self):\n        self.assertEqual(discount(student=True, member=False, tickets=1), 50)", "note": "A student pays half. This is the row release 1.1 broke, and the only one that fails below."}
]}
```

Read it as a table rather than a program. Each `test_` method is one row: the facts on the left,
the expected percentage on the right. **It is lesson 5's decision table for R5, written so that a
machine can run it** every time the code changes, which is what a person cannot afford to do by
hand.

Python's own test runner is `unittest`. Asked to run with no file named, it looks in the current directory for files called `test_*.py`
and runs every test inside them. `-v` prints one line per test instead of one dot. On Windows the
command starts with `py` or `python` instead of `python3`, as in lesson 1.

## Running it on 1.1

```
ana@laptop:~/boxoffice$ python3 -m unittest -v
test_five_tickets (test_discount.DiscountTest.test_five_tickets) ... ok
test_member (test_discount.DiscountTest.test_member) ... ok
test_member_and_five (test_discount.DiscountTest.test_member_and_five) ... ok
test_nobody (test_discount.DiscountTest.test_nobody) ... ok
test_student (test_discount.DiscountTest.test_student) ... FAIL

======================================================================
FAIL: test_student (test_discount.DiscountTest.test_student)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/boxoffice/test_discount.py", line 21, in test_student
    self.assertEqual(discount(student=True, member=False, tickets=1), 50)
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: 0 != 50

----------------------------------------------------------------------
Ran 5 tests in 0.001s

FAILED (failures=1)
```

The first five lines are the verdicts, in alphabetical order of the test names, which is the order
`unittest` uses. Four say `ok`. One says `FAIL`, and the block below it explains:

- which test: `test_student`;
- which line: line 21 of `test_discount.py`, the `assertEqual` for a student with one ticket;
- what came back and what was expected: `AssertionError: 0 != 50`. The left value is what
  `discount` returned, the right one is what the test asked for.

The last two lines are the summary: five tests ran, and the run failed with one failure. The exit
status of the command is not zero either, which is how a build server knows to stop.

## The regression, seen from below

**This is the defect lesson 10 found**, and it is worth comparing the two views. Lesson 10 booked
as a student through the application and saw a total that was not half price: a symptom on a
screen, and a defect report with steps, a total and an expected total. The unit test sees the
cause. `discount` was asked about a student and answered 0, and with the function on the screen
above the reason is plain: the new line never mentions `student`. The argument is accepted and
ignored.

A developer handed both would fix the function, run this file again and see five `ok`s in a
fraction of a second. That is the practical value of a unit test to a tester: **the same defect
costs a minute to confirm at this layer and several minutes at yours**, so once a unit test holds
a rule, the manual run can spend its time elsewhere.

The same file would have failed differently on version 1.0. There, `discount` added a member's
10% to a group's 15% and returned 25, so `test_member_and_five` would have failed with `25 != 15`:
the defect lesson 5 found with the decision table. One file, two releases, two different
rows failing. That is a regression suite at its smallest.

## What it cannot see

Every one of these five tests can pass while a customer pays the wrong price. The test calls
`discount` with `student=True`, but nothing here checks that the booking form sends the student
box, that `book` reads it under the name the form uses, or that the total on the order page is
worked out from the percentage that came back. Those are joins between pieces, and **a unit test
stops at the edge of its unit by design**. Section 04 of this lesson goes one layer up and tests
through them.
