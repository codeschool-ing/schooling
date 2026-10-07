---
title: The project the course works on
version: 1
---

The lessons need code to work on, and it is the same code all the way through: **`~/shop`, the
cart, the prices and the coupons of a small online shop**, in Python, with its tests, in git. Money
is integer cents everywhere. It is small on purpose, about a hundred lines, so that a model can be
shown all of it and you can check every answer it gives. The lessons add to it: an assistant's
suggestions in lessons 3 to 5, a support handbook to search in lesson 6, tools for a model to call
in lessons 7 and 8.

You build it with the script below. Save it as `~/make-shop.sh`, in an editor or by pasting it
between `cat > ~/make-shop.sh <<'SCRIPT'` and a line with `SCRIPT` on its own. It makes the
directory you name, writes each file, and commits them in five steps with the dates and the author
fixed, so your history is the one the lessons show, hash for hash:

```sh
# make-shop.sh DIR: the shop project as the course starts it
# Five commits with fixed dates and a fixed author, so every hash in the
# lessons comes out the same on your machine.
set -euo pipefail
D=$1
mkdir -p "$D" && cd "$D"
git init -q -b main
git config user.name "Ana Lima"
git config user.email "ana@example.com"

commit() {  # commit DATE MESSAGE
  git add -A
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"
}

mkdir -p shop tests
cat > pyproject.toml <<'EOF'
[project]
name = "shop"
version = "0.4.0"
requires-python = ">=3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
cat > shop/__init__.py <<'EOF'
EOF
cat > shop/money.py <<'EOF'
"""Money is an integer number of cents. Never a float."""


def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' -> 1290."""
    units, _, cents = text.strip().partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)


def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90'."""
    return f"{cents // 100}.{cents % 100:02d}"
EOF
cat > tests/test_money.py <<'EOF'
from shop.money import format_price, parse_price


def test_parse_price():
    assert parse_price("12.90") == 1290
    assert parse_price("7") == 700
    assert parse_price("0.5") == 50


def test_format_price():
    assert format_price(1290) == "12.90"
    assert format_price(5) == "0.05"
EOF
commit "2026-09-21T10:12:00-03:00" "Prices are integer cents"

cat > shop/cart.py <<'EOF'
from dataclasses import dataclass, field

FREE_SHIPPING_FROM = 20000  # cents
SHIPPING = 1500  # cents


@dataclass
class Line:
    sku: str
    unit_price: int  # cents
    quantity: int


@dataclass
class Cart:
    lines: list[Line] = field(default_factory=list)
    discount_percent: int = 0

    def add(self, sku: str, unit_price: int, quantity: int = 1) -> None:
        if quantity < 1:
            raise ValueError("quantity must be at least 1")
        for line in self.lines:
            if line.sku == sku:
                line.quantity += quantity
                return
        self.lines.append(Line(sku, unit_price, quantity))

    def subtotal(self) -> int:
        return sum(line.unit_price * line.quantity for line in self.lines)

    def discount(self) -> int:
        return self.subtotal() * self.discount_percent // 100

    def shipping(self) -> int:
        if self.subtotal() - self.discount() >= FREE_SHIPPING_FROM:
            return 0
        return SHIPPING

    def total(self) -> int:
        return self.subtotal() - self.discount() + self.shipping()
EOF
cat > tests/test_cart.py <<'EOF'
import pytest

from shop.cart import Cart


def test_empty_cart_pays_shipping_only():
    assert Cart().total() == 1500


def test_adding_the_same_sku_twice_adds_quantity():
    cart = Cart()
    cart.add("MUG-01", 3990)
    cart.add("MUG-01", 3990, 2)
    assert len(cart.lines) == 1
    assert cart.lines[0].quantity == 3


def test_free_shipping_from_200():
    cart = Cart()
    cart.add("LAMP-02", 20000)
    assert cart.shipping() == 0
    assert cart.total() == 20000


def test_quantity_must_be_positive():
    with pytest.raises(ValueError):
        Cart().add("MUG-01", 3990, 0)
EOF
commit "2026-09-22T15:40:00-03:00" "A cart with lines, a discount and shipping"

cat > shop/coupons.py <<'EOF'
from shop.cart import Cart

COUPONS = {"WELCOME10": 10, "FRIENDS15": 15}


class UnknownCoupon(Exception):
    pass


def apply_coupon(cart: Cart, code: str) -> None:
    """Set the cart's discount from a coupon code. Codes are case-sensitive."""
    if code not in COUPONS:
        raise UnknownCoupon(code)
    cart.discount_percent = COUPONS[code]
EOF
cat > tests/test_coupons.py <<'EOF'
import pytest

from shop.cart import Cart
from shop.coupons import UnknownCoupon, apply_coupon


def test_welcome_coupon_takes_ten_percent():
    cart = Cart()
    cart.add("MUG-01", 10000)
    apply_coupon(cart, "WELCOME10")
    assert cart.discount() == 1000


def test_unknown_coupon_is_refused():
    with pytest.raises(UnknownCoupon):
        apply_coupon(Cart(), "FREE100")
EOF
commit "2026-09-23T09:05:00-03:00" "Coupons"

cat > README.md <<'EOF'
# shop

The cart, the prices and the coupons of a small online shop. Money is integer
cents everywhere; `shop.money` is the only place that turns it into text.

    python -m pytest
EOF
commit "2026-09-24T11:30:00-03:00" "README"

cat > CONVENTIONS.md <<'EOF'
# How this project is written

These are the rules a change to `shop` is reviewed against. They are short on
purpose: each one is here because breaking it once cost somebody an afternoon.

## Money

- Every amount is an integer number of cents, in a variable or field whose
  name or comment says so. A float never holds money, not even briefly.
- Rounding happens in one place per calculation, and the code says which way.
  A discount rounds down, in the customer's disfavour by less than a cent,
  because `//` does; if that ever changes, it changes in `Cart.discount()`.
- Text is produced by `shop.money.format_price` and parsed by
  `shop.money.parse_price`. Nothing else turns cents into text.

## Code

- Python 3.11, standard library only. A dependency needs a reason in the pull
  request that adds it.
- Type hints on every public function. `-> None` is written, not implied.
- Errors are exceptions with a name (`UnknownCoupon`), never a returned `None`
  or `False` that the caller has to remember to check.
- No function longer than about forty lines. If it is, it is two functions.

## Tests

- Every change to behaviour comes with a test that fails without it.
- Tests are written from what the code is for, not from what it currently
  does. A test that only records today's output protects today's bugs.
- Test names say the rule: `test_free_shipping_from_200`, not `test_shipping_2`.
- `python -m pytest` is green before a commit, every commit.

## Commits

- One change per commit, with a subject line in the imperative that says what
  the change does, under sixty characters.
EOF
commit "2026-09-25T16:20:00-03:00" "Conventions"
```

Run it, and look at what it made:

```
ana@dev:~$ bash make-shop.sh ~/shop
ana@dev:~/shop$ git log --oneline
19265e0 Conventions
b88cbb3 README
c2b5d79 Coupons
fe437dd A cart with lines, a discount and shipping
33fefcf Prices are integer cents
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.72s
```

Eight tests pass, and the five hashes are the ones above. If yours differ, the script was changed
on the way in, often by an editor that turned its quotes into typographic ones; save it again.

**Every program you write in this course goes into `~/shop/scratch/`**, which the lessons create as
they need it. They are experiments about the model rather than part of the shop, and keeping them
in one directory keeps the project's own history clean. Run them from `~/shop`, with the
environment active, as the transcripts do.
