---
title: Unit tests
version: 1
---

A **unit test** exercises one small piece of behaviour with nothing real around it: no database,
no network, no clock, no other process. The usual mistake is to read "unit" as "one function" or
"one class". It means **one behaviour, isolated from everything that is slow or shared**. A unit
test of a pricing rule may call three functions; what makes it a unit test is that nothing outside
the process is touched.

`freight` in `shipquote/quote.py` is pure arithmetic over its arguments, which makes it the ideal
subject:

```python
"""What it costs to send a parcel, in cents."""

# The first digit of a CEP says which region of Brazil it is in.
ZONES = {"0": "SP", "1": "SP", "2": "SE", "3": "SE", "4": "NE",
         "5": "NE", "6": "N", "7": "CO", "8": "S", "9": "S"}
BASE = {"SP": 1290, "SE": 1590, "S": 1890, "CO": 2190, "NE": 2490, "N": 2990}
EXTRA_PER_500G = 450      # every 500 g started after the first
FREE_FROM = 19900         # an order of R$ 199,00 or more ships free


def normalise_cep(cep: str) -> str:
    digits = cep.replace("-", "")
    if len(digits) != 8 or not digits.isdigit():
        raise ValueError(f"not a CEP: {cep!r}")
    return digits


def zone_of(cep: str) -> str:
    return ZONES[normalise_cep(cep)[0]]


def freight(cep: str, weight_g: int, subtotal_cents: int) -> int:
    if weight_g <= 0:
        raise ValueError(f"weight must be positive, got {weight_g}")
    zone = zone_of(cep)
    if subtotal_cents >= FREE_FROM:
        return 0
    extra = (weight_g - 1) // 500
    return BASE[zone] + extra * EXTRA_PER_500G
```

## Many inputs, one test

The weight rule has edges: the first 500 g are in the base price, and every 500 g **started**
after that costs R$ 4,50 more. Writing five near-identical functions for five weights would bury
the rule in repetition. pytest's `parametrize` runs one test body once per row of a table:

```schooling-example
{
  "language": "python",
  "file": "tests/test_quote.py",
  "parts": [
    {
      "code": "@pytest.mark.parametrize(\"weight_g, cents\", [\n    (1, 1290),\n    (500, 1290),\n    (501, 1740),\n    (1000, 1740),\n    (1001, 2190),\n])",
      "note": "The table: each row is a weight and the price it must produce. The rows are chosen at the edges: 1 g and 500 g are both in the first band, 501 g is the first gram of the second, 1000 g its last, and 1001 g starts the third."
    },
    {
      "code": "def test_every_500_g_started_after_the_first_costs_extra(weight_g, cents):\n    assert freight(\"01310-100\", weight_g, 5000) == cents",
      "note": "One body, run once per row with `weight_g` and `cents` filled in. A failure names the row that broke, so the table is as precise as five separate tests."
    }
  ]
}
```

Run with `-v`, each row becomes its own line, with the parameters in square brackets:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 11 items

tests/test_quote.py::test_a_cep_in_the_city_of_sao_paulo_is_zone_sp PASSED [  9%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1-1290] PASSED [ 18%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[500-1290] PASSED [ 27%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[501-1740] PASSED [ 36%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1000-1740] PASSED [ 45%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1001-2190] PASSED [ 54%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19899-1290] PASSED [ 63%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19900-0] PASSED [ 72%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19901-0] PASSED [ 81%]
tests/test_quote.py::test_a_weight_of_zero_is_refused PASSED             [ 90%]
tests/test_quote.py::test_a_cep_with_a_letter_in_it_is_refused PASSED    [100%]

============================== 11 passed in 0.16s ==============================
```

Eleven tests in 0.16 seconds. **That speed is the point of the layer.** A unit suite runs on every
save without anybody noticing the cost, so it is the place to put every rule that can be tested
without the outside world: rounding, boundaries, formatting, the refusal of a bad CEP.

## What a unit test cannot see

Each test above passes the arguments `freight` expects. None of them asks whether the HTTP layer
passes the weight in grams rather than kilograms, whether the database column holding the price
accepts it, or whether the server starts at all. Those failures live **between** units, and a
suite made only of unit tests is green while every one of them is broken. The next three sections
climb outwards, one boundary at a time, to the tests that can see them.

A useful rule for deciding where a test belongs: **test each rule at the lowest layer that can
observe it.** The free-shipping threshold is arithmetic, so its edges are tested here, three rows,
in milliseconds. Whether a customer actually sees "R$ 0,00" on the page is a different question,
and section 08 asks it once, at the top.
