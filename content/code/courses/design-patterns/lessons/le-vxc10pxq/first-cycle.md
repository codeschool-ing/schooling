---
title: The first cycle, run for real
version: 1
---

**The first turn of the loop is the strangest one, because it ends with code that is obviously
wrong and a test that passes anyway.** That is the method working as intended. Every turn after it
replaces a little of the wrong with something general, and each replacement is forced by a test
rather than guessed.

Make `~/patterns/tdd` and work there:

```sh
mkdir -p ~/patterns/tdd
cd ~/patterns/tdd
```

## Red: a test for a function that does not exist

The first line of the list is a book returned three days late. Before any code, decide what you
would like to call: a function `fine` that takes the due date and the return date and answers in
cents. Write that call in a test.

```schooling-example
{"language": "python", "file": "test_fines.py", "parts": [
 {"code": "# test_fines.py\nimport unittest\nfrom datetime import date\n\nfrom fines import fine", "note": "The test imports a module that is not there yet. Naming it here is the first design decision: the calculator lives in `fines.py` and its function is `fine`."},
 {"code": "\n\nclass FineTest(unittest.TestCase):", "note": "`unittest` is in the standard library. A test is a method of a class that inherits from `TestCase`."},
 {"code": "    def test_three_days_late_costs_150_cents(self):\n        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)", "note": "The method's name says the behaviour, so a failure report reads as a sentence. It must start with `test`, which matters more than it seems and is shown at the end of this section."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "This lets the file run itself with `python3 test_fines.py`. The section on refactoring uses it."}
]}
```

Run it with `-v`, which names each test as it goes:

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_fines.py
test_fines (unittest.loader._FailedTest.test_fines) ... ERROR

======================================================================
ERROR: test_fines (unittest.loader._FailedTest.test_fines)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_fines
Traceback (most recent call last):
  File "/usr/lib/python3.12/unittest/loader.py", line 137, in loadTestsFromName
    module = __import__(module_name)
             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/tdd/test_fines.py", line 5, in <module>
    from fines import fine
ModuleNotFoundError: No module named 'fines'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Red, and for the reason expected: the last line of the traceback says there is no module called
`fines`. Beck counts this as a failing test. In Java or Go it would be a compile error, and the
point is the same: the test describes something the code cannot do yet.

## Green: the least code that passes

Now write `fines.py`, and write as little of it as you can get away with:

```python
# fines.py
def fine(due, returned):
    return 150
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_fines.py
test_three_days_late_costs_150_cents (test_fines.FineTest.test_three_days_late_costs_150_cents) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

**Yes, a constant.** It looks like a joke and it has done three useful things. The test has been
seen to fail and then pass, so it is known to run. The interface is fixed: the name, the two
keyword arguments, the unit. And the suite is green again within a minute of starting. The time on
the `Ran 1 test` line varies from run to run and from machine to machine; ignore it.

The refactor step has little to do yet. There is one piece of duplication, the 150 written both in
the test and in the code, and the next test on the list is what removes it.

## A test that cannot fail

Here is the missing word the previous section promised. Save this as `test_typo.py`. Its one test
expects a fine of 999 cents, which is wrong, and its name does not start with `test`:

```python
# test_typo.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 999)
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_typo.py

----------------------------------------------------------------------
Ran 0 tests in 0.000s

NO TESTS RAN
```

`unittest` collects only methods whose names begin with `test`, so it found nothing, ran nothing
and printed no failure. Python 3.12 at least says `NO TESTS RAN` and exits with a non-zero code;
older versions printed `OK`. **In a file with twenty tests, one misnamed method disappears without
a word**, and its wrong assertion stays wrong for as long as nobody looks. Seeing every new test go
red once is what catches it, and it costs one run.
