---
title: Covered is not checked
version: 1
---

A line counts as covered when it **ran**. Nothing in the measurement asks whether a test looked at
what it did. That gap is easy to state and easy to forget, so here it is made concrete.

This test file was written for this section. It calls every function in `money.py` and asserts
nothing:

```python
from shipquote.money import brl, split


def test_brl_runs():
    brl(123456)
    brl(1205)


def test_split_runs():
    split(10000, 3)
    try:
        split(10000, 0)
    except ValueError:
        pass
```

Measured on its own:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q tests/test_money_runs.py
..                                                                       [100%]
2 passed in 0.18s
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/money.py
Name                 Stmts   Miss Branch BrPart  Cover   Missing
----------------------------------------------------------------
shipquote/money.py       9      0      2      0   100%
----------------------------------------------------------------
TOTAL                    9      0      2      0   100%
ana@laptop:~/shipquote$ python -m pytest -q tests/test_money_runs.py
..                                                                       [100%]
2 passed in 0.13s
```

**100% of `money.py`, branches included**, which is more than the real test suite reached in
section 02, where line 14 was missing. Then `brl` is broken the same way lesson 1 broke it, losing
the zero that pads the cents, and the same two tests run again: still green. A file can be fully
covered by tests that would not notice it returning nonsense.

Nobody writes a test file like that on purpose, but every suite contains parts of one: a test that
checks the status code and not the body, a test whose assertion is `is not None`, a call made in
setup and never checked. **Coverage counts all of them the same as a careful test.**

## So what is coverage for?

For the half of the question it answers exactly. **A line that never ran is a line no test can have
checked.** The report of section 02 named five such places in `shipquote`, among them a whole
class whose only tests were skipped. That list is worth reading after every change, and it is the
part of the report that cannot lie.

The other half, *did the tests check what the covered code did?*, needs a different tool. The next
section uses the most direct one: break the code on purpose and see whether any test notices.
