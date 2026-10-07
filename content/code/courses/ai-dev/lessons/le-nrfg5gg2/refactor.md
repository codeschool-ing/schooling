---
title: Refactoring with an assistant
version: 2
---

A refactoring changes the shape of code without changing what it does. That second half is the
whole definition, and it is the half an assistant cannot check: it can make the code shorter, it
cannot know which of its behaviours somebody depends on. **The tests decide whether a refactoring
was one**, and the lesson of this section is that passing tests are only as good as what they
test.

## Asking for a diff

`Cart.total()` calls `subtotal()` three times, once directly and twice through `discount()` and
`shipping()`. ana asks for it to be computed once, and asks for a diff, which is the right format
for a change she will review:

```
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.73s
ana@dev:~/shop$ python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
ana@dev:~/shop$ cat -n refactor.diff
     1	Here is the unified diff to refactor `Cart` to compute the subtotal once:
     2	
     3	```diff
     4	--- a/cart.py
     5	+++ b/cart.py
     6	@@ -11,7 +11,7 @@ class Cart:
     7	     discount_percent: int = 0
     8	
     9	     def add(self, sku: str, unit_price: int, quantity: int = 1) -> None:
    10	         if quantity < 1:
    11	             raise ValueError("quantity must be at least 1")
    12	-        for line in self.lines:
    13	-            if line.sku == sku:
    14	-                line.quantity += quantity
    15	-                return
    16	+        for line in self.lines:
    17	+            if line.sku == sku:
    18	+                line.quantity += quantity
    19	+                return
    20	         self.lines.append(Line(sku, unit_price, quantity))
    21	
    22	     def subtotal(self) -> int:
    23	         return sum(line.unit_price * line.quantity for line in self.lines)
    24	
    25	     def discount(self) -> int:
    26	-        return self.subtotal() * self.discount_percent // 100
    27	+        return sum(line.unit_price * line.quantity * self.discount_percent // 100 for line in self.lines)
    28	
    29	     def shipping(self) -> int:
    30	         if self.subtotal() - self.discount() >= FREE_SHIPPING_FROM:
    31	             return 0
    32	         return SHIPPING
    33	
    34	     def total(self) -> int:
    35	-        return self.subtotal() - self.discount() + self.shipping()
    36	+        subtotal = self.subtotal()
    37	+        return subtotal - self.discount() + self.shipping()
    38	```
    39	
    40	The changes made were to compute the subtotal once and then apply the discount and shipping as separate operations, rather than recomputing the subtotal for each operation.
ana@dev:~/shop$ git apply --check refactor.diff
error: corrupt patch at line 38
```

**The reply is not a diff git can use.** It opens with a sentence, wraps the diff in a Markdown
fence and closes with another sentence, and `git apply` stops at line 38, the fence's closing
backticks. A unified diff is a format with exact rules, small models break them often, and larger
ones often enough that agents edit files through tools instead (lesson 7).

Read what it would have done anyway, because that is the review. Lines 12 to 19 take out the loop
of `add()` and put the same four lines back, which changes nothing and makes the change longer to
read. Line 27 changes `discount()`: it now rounds each line's discount down on its own and adds
them up, where the old code rounded the cart's discount once. A mug and a lamp at 39.95 each with
10% off: the old rule takes 7.99 off, the new one 7.98. **A cent, a rule `CONVENTIONS.md` says
lives in one place, and a change the explanation at the bottom does not mention.**

## Asking for the code instead

So she asks for the whole file and lets `assist` write it, the way a chat panel's Apply button
would, and reviews the change with git rather than in the reply:

```
ana@dev:~/shop$ python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with the complete new shop/cart.py in one block of code." --open shop/cart.py --write shop/cart.py > /dev/null
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
assist: the reply has no block of code to write
ana@dev:~/shop$ git diff
diff --git a/shop/cart.py b/shop/cart.py
index 230a8bd..0b521e0 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -37,4 +37,5 @@ class Cart:
         return SHIPPING
 
     def total(self) -> int:
-        return self.subtotal() - self.discount() + self.shipping()
+        subtotal = self.subtotal()
+        return subtotal - self.discount() + self.shipping()
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.77s
```

The first reply had no block of code in it, so `assist` wrote nothing, and ana asked again. The
second reply's change is three lines: `total()` keeps the subtotal in a variable. The eight tests
pass, and this time they are right to, because the behaviour did not change. **It is also not what
was asked.** `discount()` still calls `subtotal()` itself, so the subtotal is computed twice where
it was computed three times. The tests cannot tell you whether a change did what you asked; only
reading it against the request can.

## Pinning the behaviour first

The safe order is the other way round: **before a refactoring, write the tests that pin what must
not change**, especially the cases where two rules meet. Here they meet at a cart near the
free-shipping threshold with a coupon on it, which none of the eight tests has. ana writes that
one, `tests/test_threshold.py`:

```python
from shop.cart import Cart
from shop.coupons import apply_coupon


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10")
    assert cart.discount() == 2100
    assert cart.total() == 21000 - 2100 + 1500
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_threshold.py | tail -n 1
ana@dev:~/shop$ git checkout shop/cart.py && python -m pytest -q
```

The pinned test passes on the assistant's code, and on the original, which `git checkout` puts
back; it is now part of the project, nine tests where there were eight. On this run it confirmed
that the change was safe. The same request, asked on the recording machine earlier the same day,
came back with `total()` adding the discount instead of subtracting it, and that reply passed all
eight tests as well: this one is the test that would have failed.

## How to refactor with an assistant

- **Review a change as a diff**, line against line, not as new code. If the model's own diff does
  not apply, let the tool write the file and read `git diff` instead.
- **Name what must not change** in the request: "behaviour must stay the same, including the
  free-shipping threshold after the discount". It makes the mistake less likely and gives the
  review something to check against.
- **Pin first, then refactor.** If the tests around the code are thin, the first commit is new
  tests, on the old code, passing. Lesson 4 is about writing those tests well, and about why tests
  generated from the current code would have pinned nothing useful here.
- **Keep the refactoring and the behaviour change in separate commits.** If the assistant's diff
  does both, split it, or ask again.
