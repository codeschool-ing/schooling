---
title: Accepting a completion
version: 2
---

A completion arrives formatted, indented, plausible and in your style, and it is tempting to read
that as correct. **Read it the way you would read a colleague's code in review**: against what the
code is supposed to do, not against how it looks. The fastest way to do that is to write down what
it is supposed to do as tests, before deciding to keep anything.

## Tests from the docstring, before the code

ana writes one test per sentence of the docstring of `remove()`, in `tests/test_remove.py`. She
writes them from what she meant, before any suggestion exists, because a test written by reading
the code under test checks that the code does what it does:

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

Then she commits the method's signature, its docstring and its tests, so that whatever a tool
does to the file next can be undone with one command. The body is still empty, so all four
tests fail:

```
ana@dev:~/shop$ git add shop/cart.py tests/test_remove.py && git commit -q -m "Cart.remove: what it must do"
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py | tail -n 1
4 failed in 0.71s
```

## Accept, test, undo

Now the loop that the rest of this section is about: accept a suggestion, run the four tests, and
if they fail, put the file back and ask again. `--accept` puts the suggestion where the cursor was,
as pressing Tab would, and `2>/dev/null` hides the report about the context, which section 02
already read:

```
ana@dev:~/shop$ python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py --accept 2>/dev/null
        line = next((line for line in self.lines if line.sku == sku), None)
        if not line:
            raise ValueError(f"cannot remove {sku}: it's not in the cart")
        if line.quantity < quantity:
            raise ValueError(f"cannot remove {sku}: {quantity} exceeds quantity in the cart")
        line.quantity -= quantity
        if line.quantity == 0:
            self.lines.remove(line)
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py | tail -n 1
4 passed in 0.76s
```

The first suggestion passed all four. On the recording machine that took one try, and on yours it
may take two or three: section 02 showed that each request is a new draw. **Notice what the four
tests do not check**, though. The suggestion of section 02 would have passed them too, with its
false `no MUG-01 in cart`, because a test that expects `ValueError` is satisfied by any
`ValueError`. A test checks what it was written to check, and a message is part of the behaviour
only if a test says so.

## Keeping it

```
ana@dev:~/shop$ git diff
diff --git a/shop/cart.py b/shop/cart.py
index 2e3e557..c74e8cd 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -31,7 +31,14 @@ class Cart:
         A line that reaches zero is removed. Removing more than the cart
         holds, or a sku it does not hold, raises ValueError.
         """
-
+        line = next((line for line in self.lines if line.sku == sku), None)
+        if not line:
+            raise ValueError(f"cannot remove {sku}: it's not in the cart")
+        if line.quantity < quantity:
+            raise ValueError(f"cannot remove {sku}: {quantity} exceeds quantity in the cart")
+        line.quantity -= quantity
+        if line.quantity == 0:
+            self.lines.remove(line)
     def subtotal(self) -> int:
         return sum(line.unit_price * line.quantity for line in self.lines)
 
ana@dev:~/shop$ python -m pytest -q
............                                                             [100%]
12 passed in 0.79s
```

Twelve tests pass: the eight the project had and the four new ones. The diff shows one more thing
the tests cannot: **the blank line between `remove()` and `subtotal()` is gone**. The suggestion
took the place of the empty line at the cursor and stopped before writing one of its own, so the
next method starts right under it. A reviewer puts it back. That is the shape of most accepted
completions: right, nearly, with the last detail left for whoever reads the diff.

## The habits

- **Write the intent before you accept.** A docstring, a test, or both. A completion matches
  what it was given, and an empty function body gives it nothing to match except the name.
- **Accept small.** A line or a block you can read at a glance. Accepting forty lines because the
  first five were right is how a bug arrives in code nobody wrote. `assist` stops a suggestion at
  its first blank line for that reason.
- **Commit before a tool edits, and run the tests right after.** The test that fails right after
  the suggestion points at the suggestion; the same failure three changes later points at all
  three. And `git checkout` is a better undo than trying to remember what the file said.
