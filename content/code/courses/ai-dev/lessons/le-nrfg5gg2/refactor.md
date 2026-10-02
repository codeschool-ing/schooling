---
title: Refactoring with an assistant
version: 1
---

A refactoring changes the shape of code without changing what it does. That second half is the
whole definition, and it is the half an assistant cannot check: it can make the code shorter, it
cannot know which of its behaviours somebody depends on. **The tests decide whether a refactoring
was one**, and the lesson of this section is that passing tests are only as good as what they
test.

## A request and a diff

`Cart.total()` calls `subtotal()` three times, once directly and twice through `discount()` and
`shipping()`. ana asks `assist` to compute it once, and asks for a diff, which is the right format
for a change she will review (lesson 5 says more about asking for one). The reply was written by the
course:

```
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.55s
ana@dev:~/shop$ assist ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
ana@dev:~/shop$ cat refactor.diff
diff --git a/shop/cart.py b/shop/cart.py
index 230a8bd..38a07b4 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -31,10 +31,14 @@ class Cart:
     def discount(self) -> int:
         return self.subtotal() * self.discount_percent // 100
 
-    def shipping(self) -> int:
-        if self.subtotal() - self.discount() >= FREE_SHIPPING_FROM:
+    def shipping(self, subtotal: int | None = None) -> int:
+        if subtotal is None:
+            subtotal = self.subtotal()
+        if subtotal >= FREE_SHIPPING_FROM:
             return 0
         return SHIPPING
 
     def total(self) -> int:
-        return self.subtotal() - self.discount() + self.shipping()
+        subtotal = self.subtotal()
+        discount = subtotal * self.discount_percent // 100
+        return subtotal - discount + self.shipping(subtotal)

```

## Applying it, and the tests

```
ana@dev:~/shop$ git apply --stat refactor.diff
 shop/cart.py |   10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)
ana@dev:~/shop$ git apply refactor.diff && python -m pytest -q
........                                                                 [100%]
8 passed in 0.57s
```

The eight tests pass, and the diff looks like the refactoring that was asked for. **It is not
one.** Read the old `shipping()` against the new: the old one compared `subtotal - discount` with
the free-shipping threshold, the new one compares `subtotal` alone. A cart of 210.00 with a 10%
coupon used to pay 15.00 for shipping, because 189.00 is under 200.00, and now pays nothing.
Whether that is a better rule is a question for whoever owns the shop's prices. It is not a
refactoring.

None of the eight tests has a coupon and a cart near the threshold at the same time, so none of
them noticed.

## Pinning the behaviour first

The safe order is the other way round: **before a refactoring, write the tests that pin what must
not change**, especially the cases where two rules meet. ana writes the one this diff breaks:

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
ana@dev:~/shop$ python -m pytest -q tests/test_threshold.py
F                                                                        [100%]
=================================== FAILURES ===================================
__________ test_free_shipping_threshold_is_checked_after_the_discount __________

    def test_free_shipping_threshold_is_checked_after_the_discount():
        cart = Cart()
        cart.add("LAMP-02", 21000)
        apply_coupon(cart, "WELCOME10")
        assert cart.discount() == 2100
>       assert cart.total() == 21000 - 2100 + 1500
E       AssertionError: assert 18900 == ((21000 - 2100) + 1500)
E        +  where 18900 = total()
E        +    where total = Cart(lines=[Line(sku='LAMP-02', unit_price=21000, quantity=1)], discount_percent=10).total

tests/test_threshold.py:10: AssertionError
=========================== short test summary info ============================
FAILED tests/test_threshold.py::test_free_shipping_threshold_is_checked_after_the_discount
1 failed in 0.58s
```

`18900` against `20400`: the refactored cart forgot the shipping. On the original code the same
test passes, so it is now part of the project:

```
ana@dev:~/shop$ git checkout shop/cart.py && python -m pytest -q
Updated 1 path from the index
.........                                                                [100%]
9 passed in 0.56s
```

## How to refactor with an assistant

- **Ask for a diff**, and read it as a change, line against line, not as new code.
- **Name what must not change** in the request: "behaviour must stay the same, including the
  free-shipping threshold after the discount". It makes the mistake less likely and gives the
  review something to check against.
- **Pin first, then refactor.** If the tests around the code are thin, the first commit is new
  tests, on the old code, passing. Lesson 4 is about writing those tests well, and about why tests
  generated from the current code would have pinned nothing useful here.
- **Keep the refactoring and the behaviour change in separate commits.** If the assistant's diff
  does both, split it, or ask again.
