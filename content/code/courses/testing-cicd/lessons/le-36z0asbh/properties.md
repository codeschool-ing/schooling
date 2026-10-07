---
title: Letting the machine choose the inputs
version: 1
---

Every test so far checks examples somebody chose: 1205 cents, 501 g, 19,900. Choosing well is the
skill lesson 1 section 13 taught, and it has a limit: you only test the cases you thought of.
**Property-based testing** turns it round. You state a rule that must hold for every input, and a
library generates inputs, hundreds of them, looking for one that breaks it.

`split` has two such rules. Whatever the total and however many instalments, the instalments add
back up to the total, and no two differ by more than one cent. In `tests/test_money_properties.py`,
written with the Hypothesis library:

```python
"""Properties of split that hold for every total and every number of parts."""
from hypothesis import given
from hypothesis import strategies as st

from shipquote.money import split

totals = st.integers(min_value=0, max_value=10_000_000)
parts = st.integers(min_value=1, max_value=24)


@given(totals, parts)
def test_the_instalments_add_back_up(cents, n):
    assert sum(split(cents, n)) == cents


@given(totals, parts)
def test_no_instalment_is_more_than_a_cent_from_another(cents, n):
    instalments = split(cents, n)
    assert max(instalments) - min(instalments) <= 1
```

`st.integers(...)` describes the inputs: totals from zero to a hundred thousand reais, from one to
24 instalments. `@given` asks Hypothesis to call the test with values drawn from those ranges.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money_properties.py -v --hypothesis-show-statistics | grep -E "passed|examples|PASSED"
tests/test_money_properties.py::test_the_instalments_add_back_up PASSED  [ 50%]
tests/test_money_properties.py::test_no_instalment_is_more_than_a_cent_from_another PASSED [100%]
  - Stopped because settings.max_examples=100
  - Stopped because settings.max_examples=100
============================== 2 passed in 0.21s ===============================
```

Each test ran a hundred examples, the default, and passed. The current `split` is the `divmod`
version from lesson 1, and it holds both properties.

## A property catching a plausible bug

Here `split` is replaced by a version somebody might write in a hurry: divide, round, and let the
last instalment absorb whatever is left over.

```
ana@laptop:~/shipquote$ git diff shipquote/money.py
diff --git a/shipquote/money.py b/shipquote/money.py
index 4c66e52..463f189 100644
--- a/shipquote/money.py
+++ b/shipquote/money.py
@@ -12,5 +12,5 @@ def split(cents: int, parts: int) -> list[int]:
     """Split a total into instalments that add back up; odd cents go first."""
     if parts < 1:
         raise ValueError(f"parts must be at least 1, got {parts}")
-    base, rest = divmod(cents, parts)
-    return [base + 1 if i < rest else base for i in range(parts)]
+    each = round(cents / parts)
+    return [each] * (parts - 1) + [cents - each * (parts - 1)]
ana@laptop:~/shipquote$ python -m pytest tests/test_money_properties.py -q --hypothesis-seed=0 2>&1 | grep -E "^(Falsifying|test_|    [a-z]|E  |FAILED|[0-9]+ (failed|passed))"
    def test_no_instalment_is_more_than_a_cent_from_another(cents, n):
E       assert (2 - 0) <= 1
E        +  where 2 = max([0, 0, 0, 2])
E        +  and   0 = min([0, 0, 0, 2])
E       Failing test case: test_no_instalment_is_more_than_a_cent_from_another(
E           cents=2,
E           n=4,
E       )
FAILED tests/test_money_properties.py::test_no_instalment_is_more_than_a_cent_from_another
1 failed, 1 passed in 0.24s
```

The first property still passes: the last instalment makes the sum come out right by construction.
The second fails, and Hypothesis reports **the smallest input it could find** that breaks it:
2 cents in 4 instalments. `round(0.5)` is `0` in Python, which rounds halves to the even number, so
the first three instalments are 0 and the last is 2. Hypothesis did not stop at the first failure
it met; it **shrank** the failing input towards the simplest one that still fails, which is why the
example is small enough to work out by hand.

Would a hand-picked example have found it? `split(10000, 3)` from lesson 1 gives 3333, 3333, 3334
under this version, and the existing test, which expects `[3334, 3333, 3333]`, fails on the order.
But a test written for this version would have used the same kind of example and passed. The
property needed no insight about where rounding goes wrong; it needed the rule.

## Reproducing a failure

`--hypothesis-seed=0` fixed the seed for this capture so the run can be repeated. Without it,
Hypothesis still remembers failing examples in a local database, `.hypothesis/`, and tries them
first on the next run, so a failure found once keeps failing until it is fixed.

## Where properties fit

Properties suit code with rules that are easy to state and hard to enumerate: arithmetic like
`split`, parsing and formatting that should round-trip, sorting, anything with an inverse. They do
not replace examples. An example says *this* input gives *that* output, which a property rarely
pins down, and examples are what a reader learns the behaviour from. The two together are
stronger than either: examples for the cases you know, properties for the ones you did not think of.
