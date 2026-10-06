---
title: A first test, passing and failing
version: 1
---

A test in pytest is a function whose name starts with `test_`, in a file whose name starts with
`test_`. Inside it you call your code and state what must be true with a plain `assert`. pytest
finds the functions, runs each one, and reports which assertions held.

This is the whole of `tests/test_money.py`, the first test file `shipquote` ever had. It checks
`brl`, which formats cents as a Brazilian price, and `split`, which divides a total into
instalments.

```python
from shipquote.money import brl, split


def test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents():
    assert brl(123456) == "R$ 1.234,56"


def test_brl_keeps_two_digits_of_cents():
    assert brl(1205) == "R$ 12,05"


def test_split_hands_the_odd_cents_to_the_first_instalments():
    assert split(10000, 3) == [3334, 3333, 3333]


def test_split_adds_back_up_to_the_total():
    assert sum(split(19990, 7)) == 19990
```

Each test has the same three moves, often called **arrange, act, assert**: set up the inputs,
call the code, check the result. Here the arrange step is just the literal arguments, so each test
is one line. Notice that **every amount is an integer number of cents**: 123456 is R$ 1.234,56.
The next section shows why a float would make these tests lie.

## Running it

`python -m pytest` runs the tests with the interpreter of the active virtual environment, which is
the one that has pytest installed. `-v` lists every test by name:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 4 items

tests/test_money.py::test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents PASSED [ 25%]
tests/test_money.py::test_brl_keeps_two_digits_of_cents PASSED           [ 50%]
tests/test_money.py::test_split_hands_the_odd_cents_to_the_first_instalments PASSED [ 75%]
tests/test_money.py::test_split_adds_back_up_to_the_total PASSED         [100%]

============================== 4 passed in 0.62s ===============================
```

The header says which Python and pytest ran, where the project root is and which configuration
file was read (`pyproject.toml`). The four lines are the four functions, and the last line is the
verdict: **4 passed in 0.62s**.

## Watching it fail

A test you have never seen fail is a test you cannot trust: it might not be running at all, or it
might be asserting something that is always true. So break the code on purpose. Here `brl` loses
the `:02d` that pads cents to two digits, and the suite runs again without `-v`:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money.py
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collected 4 items

tests/test_money.py .F..                                                 [100%]

=================================== FAILURES ===================================
______________________ test_brl_keeps_two_digits_of_cents ______________________

    def test_brl_keeps_two_digits_of_cents():
>       assert brl(1205) == "R$ 12,05"
E       AssertionError: assert 'R$ 12,5' == 'R$ 12,05'
E         
E         - R$ 12,05
E         ?       -
E         + R$ 12,5

tests/test_money.py:9: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money.py::test_brl_keeps_two_digits_of_cents - AssertionErr...
========================= 1 failed, 3 passed in 0.14s ==========================
```

Read a failure from the bottom up. The summary names the test. Above it, pytest shows the line
that failed, marked with `>`, and the two values it compared: `brl(1205)` returned `'R$ 12,5'`
where the test expected `'R$ 12,05'`. The `- / ? / +` lines are a diff of the two strings, and
the `-` under the expected line points at the missing character. The location,
`tests/test_money.py:9`, is where to look first.

**The test did not find the bug by being clever.** It found it because somebody wrote down that
1205 cents is `R$ 12,05`. Most of the value of a test is in choosing an input where a plausible
mistake shows: 1205 has a single-digit cents part, where 123456 does not. With only the first
test, this bug would have passed.

## The red, green habit

Two runs are worth making a habit:

- write the test, run it, and **see it fail** for the reason you expect;
- then make it pass, and run the whole suite, not only the new test.

The first run proves the test can fail. The second proves the change did not break a neighbour.
Teams that write the test before the code call this rhythm *red, green, refactor*, and in the `qa`
track `qa-fundamentals` lesson 15 covers it as a method. Here it is simply how to check that a
test checks something.
