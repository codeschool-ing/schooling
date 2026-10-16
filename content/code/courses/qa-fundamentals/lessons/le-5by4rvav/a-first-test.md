---
title: A first test, and the first red
version: 1
---

**Cine Aurora is starting coupons.** Joana's first sentence about them is short: *the code PIPOCA takes R$ 5,00
off an order.* Rafael builds it with TDD, and Lia sits beside him with the examples. You can follow every step
in your own lab: it needs nothing beyond the Python you installed in lesson 1, because its test runner,
`unittest`, comes with Python.

## The test

The first test is the sentence turned into one example: an order of R$ 36,00 with the code PIPOCA costs
R$ 31,00. Prices are in centavos, as in `tickets.py`. Save this in `~/aurora` as `test_coupons.py`:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)


if __name__ == "__main__":
    unittest.main()
```

Read it from the bottom of the method up. `assertEqual(a, b)` fails if `a` is not `b`. What it compares is the
result of `apply("PIPOCA", 3600)`, a function that does not exist yet, against `3100`. The name of the method
says what the example shows, so a failure report reads like a sentence. `unittest` runs every method whose name
starts with `test`.

## Red

Run every test in the folder with `python -m unittest -v`; `-v` lists each test by name:

```
lia@lab:~/aurora$ python -m unittest -v
test_coupons (unittest.loader._FailedTest.test_coupons) ... ERROR

======================================================================
ERROR: test_coupons (unittest.loader._FailedTest.test_coupons)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_coupons
Traceback (most recent call last):
  File "/usr/lib/python3.12/unittest/loader.py", line 394, in _find_test_path
    module = self._get_module_from_name(name)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/unittest/loader.py", line 337, in _get_module_from_name
    __import__(name)
  File "/home/lia/aurora/test_coupons.py", line 3, in <module>
    from coupons import apply
ModuleNotFoundError: No module named 'coupons'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Red, and for the plainest reason: there is no `coupons.py`. `unittest` reports it as an **ERROR** rather than a
**FAIL**: the test could not even run, as opposed to running and getting the wrong answer. That is still a useful
failure. It shows the runner finds the test and that it fails when the code is missing, which is the first thing a test has
to be able to do.

## Green, by the least code

Now the least code that turns it green. Save this as `coupons.py`:

```python
# coupons.py
def apply(code, total):
    return 3100
```

That looks like cheating, and in a way it is. It is called **faking it**, and it is deliberate: the test asked
for 3100 and got 3100. Run the tests again:

```
lia@lab:~/aurora$ python -m unittest -v
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

Green. The point of the fake is what it exposes. The function ignores both its arguments, and one test cannot
tell. Lia said so at once: *"so every code gives five reais off, and every order costs thirty-one?"* Both are
wrong, and neither is tested. The way out is not to write the real code from imagination; it is to write the
next example that the fake gets wrong.
