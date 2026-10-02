---
title: Asking for the edges
version: 1
---

Most bugs live at the edges of the input: zero, one, the empty list, the largest value, the
negative number nobody expected. A specification rarely lists them, because the person writing it
was thinking about the normal case. **Listing edge cases is something an assistant does well**, and
it is a safe thing to ask for: a list of inputs is checked by reading it, and the expected outputs
still come from you.

## A table of cases

Lesson 3 section 07 found that `format_price(-5)` returns `'-1.95'`. ana asks for edge cases for the
function, keeps the inputs the list suggests (zero, one cent, just under and at a whole unit, a
large amount, negatives) and writes the expected text for each herself. pytest's `parametrize`
turns the table into one test per row:

```python
import pytest

from shop.money import format_price


@pytest.mark.parametrize("cents, text", [
    (0, "0.00"),
    (5, "0.05"),
    (99, "0.99"),
    (100, "1.00"),
    (1290, "12.90"),
    (100000, "1000.00"),
    (-5, "-0.05"),
    (-1290, "-12.90"),
])
def test_format_price(cents, text):
    assert format_price(cents) == text
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_format_edges.py
......FF                                                                 [100%]
=================================== FAILURES ===================================
_________________________ test_format_price[-5--0.05] __________________________

cents = -5, text = '-0.05'

    @pytest.mark.parametrize("cents, text", [
        (0, "0.00"),
        (5, "0.05"),
        (99, "0.99"),
        (100, "1.00"),
        (1290, "12.90"),
        (100000, "1000.00"),
        (-5, "-0.05"),
        (-1290, "-12.90"),
    ])
    def test_format_price(cents, text):
>       assert format_price(cents) == text
E       AssertionError: assert '-1.95' == '-0.05'
E         
E         - -0.05
E         + -1.95

tests/test_format_edges.py:17: AssertionError
_______________________ test_format_price[-1290--12.90] ________________________

cents = -1290, text = '-12.90'

    @pytest.mark.parametrize("cents, text", [
        (0, "0.00"),
        (5, "0.05"),
        (99, "0.99"),
        (100, "1.00"),
        (1290, "12.90"),
        (100000, "1000.00"),
        (-5, "-0.05"),
        (-1290, "-12.90"),
    ])
    def test_format_price(cents, text):
>       assert format_price(cents) == text
E       AssertionError: assert '-13.10' == '-12.90'
E         
E         - -12.90
E         + -13.10

tests/test_format_edges.py:17: AssertionError
=========================== short test summary info ============================
FAILED tests/test_format_edges.py::test_format_price[-5--0.05] - AssertionErr...
FAILED tests/test_format_edges.py::test_format_price[-1290--12.90] - Assertio...
2 failed, 6 passed in 0.57s
```

Six rows pass and both negative rows fail, each with the exact wrong output: `-5` reads as `-1.95`
and `-1290` as `-13.10`. A table makes the pattern visible at once. **Every negative amount is wrong,
not one**, which tells you the bug is in the arithmetic rather than in a special case.

## Where the list of edges comes from

An assistant's list of edge cases is a list of what is common for that kind of function. For a
string, empty and whitespace and non-ASCII; for a number, zero, negative, very large; for a date,
the end of the month, a leap day, a time zone. It is a checklist, and like a checklist it is good at
the cases everybody misses and blind to the ones particular to your domain. Nothing generic would
have suggested "a coupon on its last valid day". **Add the edges your specification creates**: every
threshold, every limit, every date that appears in it, tested at the value and one step either
side.

A refund is a negative amount, which is why the shop needs `format_price(-5)` to be right. It is
the next section's job to find everything else wrong with negative prices.
