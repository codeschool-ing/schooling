---
title: Do the tests catch anything?
version: 2
---

A test suite can be green and test almost nothing. Lesson 3 section 06 showed it: eight passing
tests, and a change that did not do what was asked went straight through, as would the one that
changed what customers pay, which the same request produced on another run. Coverage, the share
of lines the tests run, would have said 100% for `shipping()`, because every test runs it. **Running
a line is not the same as checking what it does.**

**Mutation testing** asks the direct question. Change the code on purpose, one small change at a
time (a `>=` into a `>`, a `-` into a `+`) and run the tests after each one. A change the tests
notice is *killed*. A change they do not notice has *survived*, and every survivor is a behaviour of
the code that no test pins.

## A mutation tester in forty lines

There are libraries for this, and for a large project you would use one. The idea fits in a short
script, so ana writes it, as `~/shop/scratch/mutate.py`, which also makes every result readable. It swaps one comparison or
arithmetic operator at a time, runs the whole suite and restores the file:

```python
"""Change one operator at a time, run the tests, and report the changes nobody noticed."""
import ast
import pathlib
import subprocess
import sys

SWAP = {ast.Gt: ast.GtE, ast.GtE: ast.Gt, ast.Lt: ast.LtE, ast.LtE: ast.Lt,
        ast.Add: ast.Sub, ast.Sub: ast.Add, ast.FloorDiv: ast.Div}
NAME = {ast.Gt: ">", ast.GtE: ">=", ast.Lt: "<", ast.LtE: "<=", ast.Add: "+", ast.Sub: "-",
        ast.FloorDiv: "//", ast.Div: "/"}

path = pathlib.Path(sys.argv[1])
original = path.read_text()


def operators(tree):
    for node in ast.walk(tree):
        ops = node.ops if isinstance(node, ast.Compare) else [node.op] if isinstance(node, ast.BinOp) else []
        for k, op in enumerate(ops):
            if type(op) in SWAP:
                yield node, k, op


survived = 0
for i in range(len(list(operators(ast.parse(original))))):
    tree = ast.parse(original)
    node, k, op = list(operators(tree))[i]
    new = SWAP[type(op)]()
    if isinstance(node, ast.Compare):
        node.ops[k] = new
    else:
        node.op = new
    path.write_text(ast.unparse(tree))
    run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                         capture_output=True)
    verdict = "killed" if run.returncode else "SURVIVED"
    survived += verdict == "SURVIVED"
    print(f"{path}:{node.lineno}  {NAME[type(op)]:>2} -> {NAME[type(new)]:<2}  {verdict}")
path.write_text(original)
print(f"{survived} survived")
```

Run on the shop's two files, with the tests the project had before this lesson plus the ones it
has gained:

```
ana@dev:~/shop$ python scratch/mutate.py shop/cart.py
shop/cart.py:20   < -> <=  killed
shop/cart.py:32  // -> /   SURVIVED
shop/cart.py:35  >= -> >   killed
shop/cart.py:40   + -> -   killed
shop/cart.py:35   - -> +   SURVIVED
shop/cart.py:40   - -> +   SURVIVED
3 survived
ana@dev:~/shop$ python scratch/mutate.py shop/coupons.py
shop/coupons.py:24   > -> >=  killed
0 survived
```

**Three survivors in `cart.py`, none in `coupons.py`.** The coupon's `>` was killed by the boundary
tests of lesson 4 section 05, which is what they were written for. The three in the cart are three
rules nobody tests:

- **line 32, `//` to `/`**: the discount could become a fraction of a cent and nothing would fail.
  Every test discount happens to divide exactly, so floor division and true division agree.
- **line 35, `-` to `+`**: the free-shipping threshold could add the discount instead of
  subtracting it, the kind of change lesson 3 section 06's assistant made in the arithmetic of
  the cart, still unguarded in this branch.
- **line 40, `-` to `+`**: the total could add the discount instead of subtracting it. No test has
  a discount and checks the total.

## Killing them

Two tests, each written from a rule the shop has, close all three:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_a_discount_rounds_down_to_a_whole_cent():
    cart = Cart()
    cart.add("MUG-01", 3990)
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 2))
    assert cart.discount() == 598  # 15% of 39.90 is 5.985


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10", today=date(2026, 10, 2))
    assert cart.total() == 21000 - 2100 + 1500
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_cart_rules.py && python scratch/mutate.py shop/cart.py
..                                                                       [100%]
2 passed in 0.73s
shop/cart.py:20   < -> <=  killed
shop/cart.py:32  // -> /   killed
shop/cart.py:35  >= -> >   killed
shop/cart.py:40   + -> -   killed
shop/cart.py:35   - -> +   killed
shop/cart.py:40   - -> +   killed
0 survived
```

**0 survived.** The expected values come from the rules, not from running the code: 15% of 39.90 is
5.985, and the shop rounds a discount down to a whole cent, so 598.

## What it is good for

- **Finding the tests to write**, especially after an assistant has generated a suite: a generated
  file of tests that all pass is exactly where mutation testing shows what they never check.
- **Not as a number to maximise.** Some mutants change nothing a customer could notice (two ways of
  writing the same condition) and survive for good reason. Read each survivor and decide; do not
  chase a percentage.
- **It is slow by design**: the whole suite runs once per mutant. Run it on the module you are
  working on, not on every commit of a large project.
