---
title: An assistant as a reviewer
version: 2
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

She saves the diff and asks for a review of it. A review is a list of claims, so she asks for a
short list, and keeps the reply in a file so she can number its lines:

```
ana@dev:~/shop$ git diff main > review.diff
ana@dev:~/shop$ python scratch/assist.py ask "Review this diff. List the three most serious real problems, one short paragraph each." --open review.diff > review.txt
ana@dev:~/shop$ cat -n review.txt
```

Three findings, numbered, confident and specific. Now read each against the diff. The first wants
`today` to be required; the default it objects to is what lets the shop call `apply_coupon`
without passing a date, so it is a preference about the design rather than a problem. The second
wants the expiry date in the exception, which is an improvement nobody needs before shipping this.
The third asks for a "more specific type hint" for `cart: Cart`, which names the class the file
imports and is as specific as a hint gets, and suggests `Cart = object`, which would make it less
so. **None of the three is a bug, and the bug is not there**: FRIENDS15 is refused on its last
valid day, 31 October, because the code says `today >= until`. The next section finds it.

What matters here is the shape:

- **A review is a list of claims**, each about a line and a behaviour. That makes each one
  checkable, which a vague "looks good, consider adding tests" is not. Ask for that shape: real
  problems only, most serious first, each with the line and the case that breaks it.
- **The assistant saw only the diff.** Not the tests, not the coupon terms the marketing team
  published, not the time zone the shop runs in. A diff with no context gets a review with no
  context, and lesson 3 section 02's rule applies: the files that define the expectation belong in
  the request.
- **It reads the code, not the intent.** It cannot know that "until 31 October" means the 31st is
  included unless something says so, and here the comment in the code happens to. A larger model
  reads that comment more often than a small one does. Neither is a substitute for a test that says
  what the 31st should do.
