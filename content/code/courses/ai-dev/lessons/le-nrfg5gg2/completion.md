---
title: Accepting a completion
version: 1
---

A completion arrives formatted, indented, plausible and in your style, and it is tempting to read
that as correct. **Read it the way you would read a colleague's code in review**: against what the
code is supposed to do, not against how it looks. The fastest way to do that is to write down what
it is supposed to do as tests, before deciding to keep it.

## The suggestion

This is what `assist` suggested for `remove()` in lesson 3 section 02, placed after the docstring
ana wrote. It was written by the course, with its mistakes on purpose:

```
ana@dev:~/shop$ sed -n 28,39p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """
        for line in self.lines:
            if line.sku == sku:
                line.quantity -= quantity
                return
        raise ValueError(f"{sku} is not in the cart")

```

It reads well. It finds the line, takes the units off, and refuses a sku the cart does not have.
Now read the docstring again: *a line that reaches zero is removed* and *removing more than the
cart holds raises ValueError*. **The suggestion does neither**, and nothing about its formatting
says so.

## Tests from the docstring, not from the code

ana writes one test per sentence of the docstring. She writes them from what she meant, without
looking at the suggestion, because a test written by reading the code under test checks that the
code does what it does:

```python
import pytest

from shop.cart import Cart


def test_removing_some_units_keeps_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990, 3)
    cart.remove("MUG-01", 2)
    assert cart.lines[0].quantity == 1


def test_removing_the_last_unit_removes_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990)
    cart.remove("MUG-01")
    assert cart.lines == []


def test_removing_more_than_the_cart_holds_is_refused():
    cart = Cart()
    cart.add("MUG-01", 3990, 2)
    with pytest.raises(ValueError):
        cart.remove("MUG-01", 3)


def test_removing_a_sku_not_in_the_cart_is_refused():
    with pytest.raises(ValueError):
        Cart().remove("LAMP-02")
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py
.FF.                                                                     [100%]
=================================== FAILURES ===================================
_________________ test_removing_the_last_unit_removes_the_line _________________

    def test_removing_the_last_unit_removes_the_line():
        cart = Cart()
        cart.add("MUG-01", 3990)
        cart.remove("MUG-01")
>       assert cart.lines == []
E       AssertionError: assert [Line(sku='MU..., quantity=0)] == []
E         
E         Left contains one more item: Line(sku='MUG-01', unit_price=3990, quantity=0)
E         Use -v to get more diff

tests/test_remove.py:17: AssertionError
______________ test_removing_more_than_the_cart_holds_is_refused _______________

    def test_removing_more_than_the_cart_holds_is_refused():
        cart = Cart()
        cart.add("MUG-01", 3990, 2)
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

tests/test_remove.py:23: Failed
=========================== short test summary info ============================
FAILED tests/test_remove.py::test_removing_the_last_unit_removes_the_line - A...
FAILED tests/test_remove.py::test_removing_more_than_the_cart_holds_is_refused
2 failed, 2 passed in 0.56s
```

Two of the four fail, and the failures say exactly what is wrong: a line left in the cart with
`quantity=0`, and no error when taking three mugs out of two. The other two pass, because the
suggestion got those parts right. **This is the usual shape of a wrong suggestion**: mostly
right, wrong at the edges, and the edges are where the docstring was specific.

## The fix, by hand

```
ana@dev:~/shop$ sed -n 34,42p shop/cart.py
        for line in self.lines:
            if line.sku == sku:
                if quantity > line.quantity:
                    raise ValueError(f"the cart holds {line.quantity} of {sku}")
                line.quantity -= quantity
                if line.quantity == 0:
                    self.lines.remove(line)
                return
        raise ValueError(f"{sku} is not in the cart")
```

```
ana@dev:~/shop$ git diff --stat
 shop/cart.py | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)
ana@dev:~/shop$ python -m pytest -q
............                                                             [100%]
12 passed in 0.53s
```

All twelve tests pass: the eight the project had and the four new ones. The suggestion saved the
loop and the error message and cost two bugs, which is a fair trade **only because the tests
found them**. Without the tests, the cart would have shipped a line with zero mugs that adds
nothing to the total and still shows on the checkout page.

## The habits

- **Write the intent before you accept.** A docstring, a test, or both. A completion matches
  what it was given, and an empty function body gives it nothing to match except the name.
- **Accept small.** A line or a block you can read at a glance. Accepting forty lines because the
  first five were right is how a bug arrives in code nobody wrote.
- **Run the tests before you move on**, not at the end of the afternoon. The test that failed
  right after the suggestion points at the suggestion; the same failure three changes later points
  at all three.
