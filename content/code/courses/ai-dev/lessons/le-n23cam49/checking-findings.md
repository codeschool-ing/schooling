---
title: Checking a finding before acting on it
version: 2
---

A finding from a review is a hypothesis about the code: *if we do this, that happens*. **The way
to check a hypothesis about code is to run it**, or to read the line it is about. And a review that
finds nothing about a part of the change is a hypothesis too: that the part is fine. That one is
checked the same way.

## The claims, one by one

Each of the review's three claims can be settled by reading the line it names. `today` defaults to
the current date on purpose, so the first is a choice to keep or change, not a defect. The second
asks for more information in an exception, which is a wish. The third is about `cart: Cart`, and
`Cart` is the class imported at the top of the file: there is nothing to fix, and its suggested fix
would make the code worse. **None of them needs a test.** Acting on the third without reading the
line would have cost an afternoon and lowered the quality of the code, and closed a finding as
fixed.

That is what a small model's review mostly is: claims that have the shape of a review and the
substance of nothing. A larger model's review has fewer of them and some real findings among them,
and the way to tell one kind from the other is the same: the line, and, when the line does not
settle it, a test.

## What the change promised

The change promised two things: FRIENDS15 is valid until 31 October, and a code may be typed in
any case. ana writes one test for each, in `tests/test_review.py`, because whatever the review
said, those are the two behaviours this branch is for:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_review.py
F.                                                                       [100%]
=================================== FAILURES ===================================
___________________ test_friends15_is_valid_on_its_last_day ____________________

    def test_friends15_is_valid_on_its_last_day():
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
FAILED tests/test_review.py::test_friends15_is_valid_on_its_last_day - shop.c...
1 failed, 1 passed in 0.67s
```

**The last day is refused.** The test fails with `ExpiredCoupon: FRIENDS15` on 31 October, and the
traceback points at `today >= until`: the comparison should be `>`, since `until` is the last valid
day. The lower-case code is accepted, because the second line of `apply_coupon` is
`code = code.strip().upper()`.

**The bug the review did not mention is the one the test found.** A reviewer that misses something
says nothing about it, and the silence reads like approval. That is the more dangerous of a
reviewer's two mistakes, and it is why the change's own promises get a test whatever a review
says.

## A question no test settles

`date.today()` returns the date where the server runs. If the server runs on UTC and the customers
are in São Paulo, three hours behind, then from 21:00 on 31 October local time the server already
believes it is 1 November. That is a real question, and it is a question for a person: which time
zone the coupon terms mean, and where the shop's servers run. **A finding can be valuable without
being a bug**, and it is answered by a decision, written down, not by a test. Nothing in this review raised it; a reviewer who knew where the shop runs would.

Keep the tests from the check, including the one that passed. It cost two minutes, it documents
that lower-case codes work, and it fails if somebody removes the `upper()` later.
