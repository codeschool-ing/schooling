---
title: Unit tests, and the code they made Ana change
version: 1
---

The first thing a test asks of code is that it can be called. Lesson 16's validator could not: its
work was done at the top level of the file, reading `sys.argv` the moment it was imported, so a test
that imported it to call `check` would have run the whole program. Ana moves that work into a
`main` function, called only when the file is run as a script:

```
ana@vm:~/etl$ diff /tmp/validate_prices.before.py validate_prices.py | head -n 12; echo …; diff /tmp/validate_prices.before.py validate_prices.py | tail -n 6
49,58c49,58
< src, good_path, bad_path = sys.argv[1:4]
< fixed, rejected, good, bad = Counter(), Counter(), [], []
< for line in open(src, encoding="utf-8"):
<     rec = json.loads(line)
<     reason = check(rec, fixed)
<     if reason:
<         rejected[reason] += 1
<         bad.append({"reason": reason, "record": json.loads(line)})
<     else:
<         good.append(rec)
---
…
>         out.writelines(json.dumps(g, ensure_ascii=False) + "\n" for g in good)
>     return 0
> 
> 
> if __name__ == "__main__":
>     sys.exit(main(*sys.argv[1:4]))
```

The program does exactly what it did. What changed is that `check` and `isbn13_ok` can now be
imported and called on one record at a time. **Code that is easy to test is usually code that keeps
its decisions apart from its input and output**, and the change was worth making for that alone.

Then the tests: one rule each, with a record the validator accepts and one field changed.

```
"""Unit tests for the price validator: one record in, one decision out."""
from collections import Counter

from validate_prices import check, isbn13_ok


def price(**changes):
    """A record the validator accepts as it is, with some fields changed."""
    rec = {"isbn": "9786574218454", "publisher": "Borda", "list_price_cents": 10490,
           "currency": "BRL", "updated_at": "2026-01-01T05:01:00-03:00"}
    rec.update(changes)
    return rec


def test_a_real_isbn_passes_its_check_digit():
    assert isbn13_ok("9786574218454")


def test_one_wrong_digit_fails_it():
    assert not isbn13_ok("9786574218455")


def test_hyphens_are_removed_and_counted():
    rec, fixed = price(isbn="978-65-7421-845-4"), Counter()
    assert check(rec, fixed) is None
    assert rec["isbn"] == "9786574218454"
    assert fixed == {"isbn written with hyphens": 1}


def test_a_missing_price_is_rejected():
    assert check(price(list_price_cents=None), Counter()) == "price missing"


def test_a_price_with_a_decimal_comma_is_rejected():
    assert check(price(list_price_cents="104,90"), Counter()) == "price '104,90' is not a number"


def test_another_currency_is_rejected_not_converted():
    assert check(price(currency="USD"), Counter()) == "currency 'USD'"


def test_a_price_in_reais_is_not_taken_for_cents():
    assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
```

```
ana@vm:~/etl$ python -m pytest -q tests/test_validate.py 2>&1 | tail -n 15
......F                                                                  [100%]
=================================== FAILURES ===================================
_________________ test_a_price_in_reais_is_not_taken_for_cents _________________

    def test_a_price_in_reais_is_not_taken_for_cents():
>       assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
E       AssertionError: assert None == 'price 104.9 is not a whole number of cents'
E        +  where None = check({'isbn': '9786574218454', 'publisher': 'Borda', 'list_price_cents': 104.9, 'currency': 'BRL', ...}, Counter())
E        +    where {'isbn': '9786574218454', 'publisher': 'Borda', 'list_price_cents': 104.9, 'currency': 'BRL', ...} = price(list_price_cents=104.9)
E        +    and   Counter() = Counter()

tests/test_validate.py:43: AssertionError
=========================== short test summary info ============================
FAILED tests/test_validate.py::test_a_price_in_reais_is_not_taken_for_cents
1 failed, 6 passed in 0.02s
```

Six passed. The seventh is the one Ana wrote by asking *what could a publisher send that I have not
seen yet?* — a price in reais with a decimal point, `104.9`, as a number rather than text. The
validator **accepted it**: it is not `None`, not a string, and it is between 100 and 100,000, so it
went through as a price of 104.9 cents, a hundredth of what the book costs. No publisher has sent
one yet. The first one would have been loaded without a word.

The fix is a check that the price is a whole number:

```
ana@vm:~/etl$ diff /tmp/validate_prices.before.py validate_prices.py | sed -n "/whole number/,+0p;/isinstance(rec/,+0p"
>     if not isinstance(rec["list_price_cents"], int):
>         return f"price {rec['list_price_cents']} is not a whole number of cents"
ana@vm:~/etl$ python -m pytest -q tests/test_validate.py
.......                                                                  [100%]
7 passed in 0.02s
```

Seven passed. This is the case for unit tests in a pipeline: **they let you ask about the input you
have not received yet**, which no test on the data ever can.
