---
title: Properties instead of examples
version: 2
---

An example-based test checks the inputs you thought of. A **property-based test** states something
that must be true for every input, and a library generates hundreds of inputs looking for one where
it is false. In Python that library is **hypothesis**. When it finds a failure, it shrinks it to the
simplest input that still fails, which makes the report readable.

Writing a property means saying what the code is for in general, rather than for one case. That is
the hard part, and it is the part where an assistant can suggest candidates you then judge.

## Two properties of money as text

ana states two things that must hold for every amount between minus and plus a billion cents:

```python
from hypothesis import given
from hypothesis import strategies as st

from shop.money import format_price, parse_price

cents = st.integers(min_value=-10**9, max_value=10**9)


@given(cents)
def test_a_price_survives_a_round_trip_through_text(n):
    assert parse_price(format_price(n)) == n


@given(cents)
def test_a_negative_price_reads_as_minus_the_positive_one(n):
    if n < 0:
        assert format_price(n) == "-" + format_price(-n)
```

- **A round trip**: formatting an amount and parsing the text back gives the same amount.
- **Symmetry**: a negative amount reads as a minus sign followed by the positive amount.

Run against the original `shop/money.py`. `--hypothesis-seed=0` fixes the random inputs, so the run
in this lesson is the one you get:

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py
.F                                                                       [100%]
=================================== FAILURES ===================================
____________ test_a_negative_price_reads_as_minus_the_positive_one _____________

    @given(cents)
>   def test_a_negative_price_reads_as_minus_the_positive_one(n):
                   ^^^

tests/test_money_properties.py:15: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

n = -1

    @given(cents)
    def test_a_negative_price_reads_as_minus_the_positive_one(n):
        if n < 0:
>           assert format_price(n) == "-" + format_price(-n)
E           AssertionError: assert '-1.99' == '-0.01'
E             
E             - -0.01
E             + -1.99
E           Failing test case: test_a_negative_price_reads_as_minus_the_positive_one(
E               n=-1,
E           )
E           Explanation:
E               These lines were always and only run by failing test cases:
E                   /home/ana/shop/tests/test_money_properties.py:17

tests/test_money_properties.py:17: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money_properties.py::test_a_negative_price_reads_as_minus_the_positive_one
1 failed, 1 passed in 0.15s
```

**The round trip passed.** The symmetry property failed at once, shrunk to `n = -1`: minus one cent
reads as `'-1.99'`. So `format_price` is wrong for every negative number, and the round trip did
not notice, because `parse_price` is wrong in the matching way: `'-1.99'` parses back to minus one.
**Two bugs that cancel each other pass a round trip.** That is worth knowing about round-trip
properties in general: they test that two functions agree, not that either is right.

## Fixing one side

ana fixes `format_price` to handle the sign. This is `shop/money.py` now:

```python
"""Money is an integer number of cents. Never a float."""


def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' -> 1290."""
    units, _, cents = text.strip().partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)


def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90', -5 -> '-0.05'."""
    sign = "-" if cents < 0 else ""
    cents = abs(cents)
    return f"{sign}{cents // 100}.{cents % 100:02d}"
```

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py
.F                                                                       [100%]
=================================== FAILURES ===================================
____________ test_a_negative_price_reads_as_minus_the_positive_one _____________

    @given(cents)
>   def test_a_negative_price_reads_as_minus_the_positive_one(n):
                   ^^^

tests/test_money_properties.py:15: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

n = -1

    @given(cents)
    def test_a_negative_price_reads_as_minus_the_positive_one(n):
        if n < 0:
>           assert format_price(n) == "-" + format_price(-n)
E           AssertionError: assert '-1.99' == '-0.01'
E             
E             - -0.01
E             + -1.99
E           Failing test case: test_a_negative_price_reads_as_minus_the_positive_one(
E               n=-1,
E           )
E           Explanation:
E               These lines were always and only run by failing test cases:
E                   /home/ana/shop/tests/test_money_properties.py:17

tests/test_money_properties.py:17: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money_properties.py::test_a_negative_price_reads_as_minus_the_positive_one
1 failed, 1 passed in 0.19s
```

Now the symmetry holds and the round trip fails, on the same simplest input: `'-0.01'` parses as
`1`. The other half of the cancelled pair is exposed, `parse_price` reading `-0` as `0` and adding
the cents on. She fixes that too, so the sign is read first and applied to the whole amount:

```python
"""Money is an integer number of cents. Never a float."""


def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' -> 1290, '-0.05' -> -5."""
    text = text.strip()
    sign = -1 if text.startswith("-") else 1
    units, _, cents = text.lstrip("-").partition(".")
    cents = (cents + "00")[:2]
    return sign * (int(units) * 100 + int(cents))


def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90', -5 -> '-0.05'."""
    sign = "-" if cents < 0 else ""
    cents = abs(cents)
    return f"{sign}{cents // 100}.{cents % 100:02d}"
```

And runs everything:

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0
..........................                                               [100%]
26 passed in 0.17s
```

## Where properties come from

- **Round trips**: encode then decode, save then load, format then parse.
- **Invariants**: a total is never negative, a sorted list has the same items, removing what you
  added leaves the cart as it was.
- **Comparison with a simpler version**: the fast function agrees with the obvious slow one.

An assistant can suggest properties for a function, and the suggestions are claims about what the
code is for, to be read as carefully as expected values. **A wrong property is a test that encodes a
wrong requirement**, which is lesson 4 section 04's problem again.
