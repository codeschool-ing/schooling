---
title: What an assertion should compare
version: 1
---

An assertion is a yes-or-no question about one result. **The best assertion compares the whole
result with an exact expected value**, because that is the comparison that fails for the largest
number of wrong answers.

Compare two ways of testing the HTTP answer for a quote:

```python
assert "price" in body                                  # passes for any price
assert body == {"cep": "01310-100", "zone": "SP",       # passes for one answer
                "cents": 2190, "price": "R$ 21,90"}
```

The first passes if the price is wrong, if the zone is missing, or if `cents` came back as a
string. The second fails for all of them. A weak assertion is worse than no test, because it adds
a green line to the report that promises more than it checked.

## Exact values need exact arithmetic

Money is the classic place where "exact" goes wrong:

```
ana@laptop:~/shipquote$ python3 -c 'print(0.1 + 0.2 == 0.3, 0.1 + 0.2)'
False 0.30000000000000004
ana@laptop:~/shipquote$ python3 -c 'print(10 + 20 == 30)'
True
```

`0.1 + 0.2` is not `0.3` in binary floating point; it is `0.30000000000000004`. A test comparing
prices held as floats either fails for no business reason or gets "fixed" with a tolerance, and a
tolerance on money hides real one-cent errors. **That is why `shipquote` holds every amount in
integer cents**, and why its tests can compare with `==`. When a value genuinely is approximate,
such as a measured duration, pytest offers `pytest.approx` with an explicit tolerance; using it is
a statement that the approximation is part of the specification.

## Asserting that something is refused

Refusals are behaviour too. `freight` must refuse a weight of zero, and the test says so with
`pytest.raises`:

```python
def test_a_weight_of_zero_is_refused():
    with pytest.raises(ValueError, match="weight must be positive"):
        freight("01310-100", 0, 5000)
```

The `with` block passes only if the code inside raises a `ValueError` whose message matches the
pattern. If nothing is raised, the test fails. The `match` matters: without it, a `ValueError`
from some unrelated line, a typo in a parse for instance, would also satisfy the test.

## One behaviour per test

A test that asserts ten unrelated things stops at the first failure and hides the other nine. A
test named after one behaviour, with the assertions that behaviour needs, tells you what broke
from its name alone. `test_split_adds_back_up_to_the_total` and
`test_split_hands_the_odd_cents_to_the_first_instalments` are two tests of one function, because
they are two promises: one can break without the other.

**Name the test after the rule, not after the function.** `test_split_1` says nothing when it goes
red at 3 a.m. in a pipeline log. `test_split_adds_back_up_to_the_total` is a sentence a person can
act on without opening the file.
