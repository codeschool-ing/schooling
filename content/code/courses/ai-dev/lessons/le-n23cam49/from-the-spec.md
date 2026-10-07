---
title: Tests from what the code is for
version: 2
---

The fix for tests that pin bugs is to change where the expected values come from. **The expected
value in a test should come from the specification**: the coupon terms, the ticket, the docstring
written before the code, a conversation with the person who asked for the feature. The code under
test is the one place it must not come from.

## The terms as tests

The shop publishes its coupon terms. ana copies them into the test file's docstring, so the reason
for every expected value is in the file, and writes one test per sentence:

```python
"""The coupon terms, as the shop publishes them:

    FRIENDS15  15% off, valid until 31 October 2026, inclusive.
    WELCOME10  10% off, no end date.
    Codes may be typed in any case.
"""
from datetime import date

import pytest

from shop.cart import Cart
from shop.coupons import ExpiredCoupon, apply_coupon


def test_friends15_is_valid_on_31_october():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_friends15_is_refused_on_1_november():
    with pytest.raises(ExpiredCoupon):
        apply_coupon(Cart(), "FRIENDS15", today=date(2026, 11, 1))


def test_welcome10_never_expires():
    cart = Cart()
    apply_coupon(cart, "WELCOME10", today=date(2099, 1, 1))
    assert cart.discount_percent == 10


@pytest.mark.parametrize("typed", ["friends15", "Friends15", " FRIENDS15 "])
def test_codes_may_be_typed_in_any_case(typed):
    cart = Cart()
    apply_coupon(cart, typed, today=date(2026, 10, 2))
    assert cart.discount_percent == 15
```

The boundary is tested from both sides: the last valid day, and the first invalid one. That pair is
what a specification about dates always needs, because the bug is always at the boundary. Run on the
code from lesson 4 section 02:

```
ana@dev:~/shop$ python -m pytest -q tests/test_coupon_terms.py
F.....                                                                   [100%]
=================================== FAILURES ===================================
____________________ test_friends15_is_valid_on_31_october _____________________

    def test_friends15_is_valid_on_31_october():
        cart = Cart()
>       apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))

tests/test_coupon_terms.py:17: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

cart = Cart(lines=[], discount_percent=0), code = 'FRIENDS15'
today = datetime.date(2026, 10, 31)

    def apply_coupon(cart: Cart, code: str, today: date | None = None) -> None:
        """Set the cart's discount from a coupon code, typed in any case."""
        today = today or date.today()
        code = code.strip().upper()
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_coupon_terms.py::test_friends15_is_valid_on_31_october - sh...
1 failed, 5 passed in 0.56s
```

One failure, and it is the bug of lesson 4 section 03 again, found this time from the terms alone:
they say the 31st is included, and the code refuses it.

## The fix, and what it breaks

```
ana@dev:~/shop$ sed -i "s/today >= until/today > until/" shop/coupons.py && git diff --stat
ana@dev:~/shop$ python -m pytest -q tests/test_coupon_terms.py tests/test_review.py
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py | tail -n 15
```

One character in `shop/coupons.py`, and every test written from the terms or from what the change
promised passes. The generated file goes from five failures to three: the two tests that
expected 31 October to work now pass. The third that used that date,
`test_apply_coupon_code_with_end_date_expired`, still stops at `NameError: name 'shop' is not
defined`, and the traceback shows the line it never reached: `pytest.raises(...ExpiredCoupon)` on
31 October. **It was asserting the bug**, and with its import repaired it would now fail for that
reason. The right response is to delete it, not to edit the code back, and the rest of the file
goes with it, since its expected values came from nowhere anybody can point to:

```
ana@dev:~/shop$ rm tests/test_generated.py && python -m pytest -q
```

## Using an assistant here at all

Part of what went wrong in lesson 4 section 04 was the model's own, the imports, and part was what
it was given: the code, and nothing that said what the code is for. Give it the specification and
ask for tests of the specification, and it is useful again:

- **Put the terms, the ticket or the docstring in the request**, and say that the expected values
  must come from it, not from the code.
- **Ask for the boundaries by name**: the last valid day and the first invalid one, zero, one, the
  maximum, an empty input.
- **Read every expected value** before keeping a test, the way you would check the arithmetic in a
  colleague's test. A wrong expected value in a test is a bug that turns the build green.
