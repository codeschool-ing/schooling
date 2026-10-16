---
title: Growing the code one example at a time
version: 1
---

**Each new test is an example the current code gets wrong.** Writing it turns the code red; the least change that
makes it green is the next piece of the feature. Two examples that pull in different directions force the code
to stop faking, and that is called **triangulation**.

## The second example: a code that does not exist

Lia's first question was about other codes. Joana's answer: a code the cinema did not issue changes nothing. That
is the second test, added below the first:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)

    def test_an_unknown_code_changes_nothing(self):
        self.assertEqual(apply("XYZ", 3600), 3600)


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... FAIL
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

======================================================================
FAIL: test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 11, in test_an_unknown_code_changes_nothing
    self.assertEqual(apply("XYZ", 3600), 3600)
AssertionError: 3100 != 3600

----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (failures=1)
```

Read the failure, because this is where a test earns its keep. `3100 != 3600` is the actual result first and
the expected one second, and the line above names the test. The fake gives every code five reais off, and now
there is an example that says it should not. The first test still passes. (`unittest` runs the tests in
alphabetical order of their names, which is why the new one is listed first.)

The least code that satisfies both:

```python
# coupons.py
def apply(code, total):
    if code == "PIPOCA":
        return total - 500
    return total
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

The fake is gone. The total is used, the code is checked, and both happen because an example demanded them, not
because Rafael guessed.

## The third example: how people type

Lia's second question came from the box office, not the rule. Célia reads codes off customers' phones, and
customers type in lowercase. Joana's answer: *the code is the code, whatever the case.* Third test:

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


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... FAIL

======================================================================
FAIL: test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 14, in test_the_code_is_read_in_any_case
    self.assertEqual(apply("pipoca", 2800), 2300)
AssertionError: 2800 != 2300

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=1)
```

Notice that this test uses a matinée price, 2800, and not 3600 again. Changing the total as well as the case makes
sure the discount is subtracted from the total it was given, and not from one number the code happens to
remember.

```python
# coupons.py
def apply(code, total):
    if code.upper() == "PIPOCA":
        return total - 500
    return total
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

## Where the examples came from

Look at who wrote what. Rafael wrote every line of code and every line of test. The *examples* in the second and
third tests came from Lia's questions and Joana's answers. TDD gave the questions a place to land: each answer
became a test the moment it was given, and the code changed only to satisfy it.

That is the tester's place on a TDD team. Not writing the tests for the developer, and not testing afterwards what
the tests already prove, but bringing the cases: the boundary, the other value, the way somebody really types.
A developer doing TDD alone tests what they think of. A developer doing TDD next to a tester tests what both of
them think of, and that is a different suite.
