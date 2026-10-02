---
title: An assistant as a reviewer
version: 1
---

Asking an assistant to review a change is the opposite of asking it to write one, and in some ways
the safer half. **A review produces claims, and a claim can be checked** before anything changes.
The risk moves: from code that is wrong to findings that are wrong, in both directions. A real
problem it does not mention, and a problem it invents.

## The change

ana has a branch that lets customers type coupon codes in any case, and gives coupons an end date.
FRIENDS15 runs until 31 October 2026:

```python
from datetime import date

from shop.cart import Cart

# code: (percent off, last day it is valid, or None for no end)
COUPONS = {"WELCOME10": (10, None), "FRIENDS15": (15, date(2026, 10, 31))}


class UnknownCoupon(Exception):
    pass


class ExpiredCoupon(Exception):
    pass


def apply_coupon(cart: Cart, code: str, today: date | None = None) -> None:
    """Set the cart's discount from a coupon code, typed in any case."""
    today = today or date.today()
    code = code.strip().upper()
    if code not in COUPONS:
        raise UnknownCoupon(code)
    percent, until = COUPONS[code]
    if until is not None and today >= until:
        raise ExpiredCoupon(code)
    cart.discount_percent = percent
```

```
ana@dev:~/shop$ git switch -c coupon-expiry
Switched to a new branch 'coupon-expiry'
ana@dev:~/shop$ git commit -qam "Coupons in any case, with an end date" && python -m pytest -q
........                                                                 [100%]
8 passed in 0.55s
ana@dev:~/shop$ git diff main --stat
 shop/coupons.py | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)
```

The eight tests pass, because none of them knows about end dates yet.

## The review

She saves the diff and asks for a review of it. The reply was written by the course, the way an
assistant's review typically reads: numbered, confident, and specific:

```
ana@dev:~/shop$ git diff main > review.diff
ana@dev:~/shop$ assist ask "Review this diff. List real problems only, most serious first." --open review.diff
context sent (328 of 3000 tokens):
    328  review.diff
---
Three things in this diff:

1. Expiry is off by one day. `today >= until` refuses a coupon on its last valid day: FRIENDS15 says it runs until 2026-10-31, and on 2026-10-31 it is refused. If `until` is the last day it is valid, the test should be `today > until`.

2. `date.today()` is the server's local date. If the shop runs in UTC and its customers are in Brazil, a coupon expires three hours early for them, every evening. Consider passing the date from the request, in the shop's time zone.

3. The lookup is still case-sensitive: `COUPONS` has upper-case keys, so a customer who types `welcome10` will get UnknownCoupon. Normalise the code before looking it up.
```

**Three findings, and they are three different kinds of thing.** One is a bug. One is a real
question about the design that no test would catch. One is wrong. Lesson 4 section 03 sorts them.
What matters here is the shape:

- **The review is a list of claims**, each about a line and a behaviour. That makes each one
  checkable, which a vague "looks good, consider adding tests" is not. Ask for that shape: real
  problems only, most serious first, each with the line and the case that breaks it.
- **The assistant saw only the diff.** Not the tests, not the coupon terms the marketing team
  published, not the time zone the shop runs in. A diff with no context gets a review with no
  context, and lesson 3 section 02's rule applies: the files that define the expectation belong in
  the request.
- **It reads the code, not the intent.** It cannot know that "until 31 October" means the
  31st is included unless something says so, and here the comment in the code happens to. Where
  nothing says so, an assistant guesses, and so does a human reviewer.
