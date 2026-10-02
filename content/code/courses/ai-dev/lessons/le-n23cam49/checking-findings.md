---
title: Checking a finding before acting on it
version: 1
---

A finding from a review is a hypothesis about the code: *if we do this, that happens*. **The way
to check a hypothesis about code is to run it.** Write the smallest test that would fail if the
finding is right, and see.

## One test per finding

Finding 1 says FRIENDS15 is refused on its last day. Finding 3 says a lower-case code is refused.
Finding 2 is about the server's clock, and no unit test reaches it, so it waits. ana writes one
test for each of the other two, named after the finding:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_finding_1_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_finding_3_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_review.py
F.                                                                       [100%]
=================================== FAILURES ===================================
______________ test_finding_1_friends15_is_valid_on_its_last_day _______________

    def test_finding_1_friends15_is_valid_on_its_last_day():
        cart = Cart()
>       apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))

tests/test_review.py:9: 
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
FAILED tests/test_review.py::test_finding_1_friends15_is_valid_on_its_last_day
1 failed, 1 passed in 0.57s
```

**Finding 1 is real.** The test fails with `ExpiredCoupon: FRIENDS15` on 31 October, and the
traceback points at `today >= until`. **Finding 3 is not.** The lower-case code was accepted,
because the second line of `apply_coupon` is `code = code.strip().upper()`. The assistant reported
the lookup as case-sensitive while the line that fixes it was in the diff it was reviewing.

That false finding is the more instructive of the two. It was specific, it named a real line and a
real customer behaviour, and it was confidently wrong. A developer who acted on it without checking
would have added a second `upper()` call, made the code worse and closed the finding as fixed.

## Finding 2, which no test settles

`date.today()` returns the date where the server runs. If the server runs on UTC and the customers
are in São Paulo, three hours behind, then from 21:00 on 31 October local time the server already
believes it is 1 November. That is a real question, and it is a question for a person: which time
zone the coupon terms mean, and where the shop's servers run. The review was right to raise it.
**A finding can be valuable without being a bug**, and it is answered by a decision, written down,
not by a test.

## The triage

| finding | how it was checked | outcome |
|---|---|---|
| 1, last day refused | a failing test | a bug: fix it, keep the test |
| 2, server time zone | a question to the owner of the terms | a decision to make |
| 3, case-sensitive lookup | a passing test | wrong: dismiss it, with the test as the reason |

Keep the tests from the triage, including the one for the false finding. It cost two minutes, it
documents that lower-case codes work, and it fails if somebody removes the `upper()` later.
