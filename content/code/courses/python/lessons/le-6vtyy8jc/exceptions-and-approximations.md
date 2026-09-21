---
title: `raises` with a `match`, and the float that is never equal
version: 1
---

```python
def test_unknown_currency():
    with pytest.raises(KeyError, match="unknown currency"):
        rate("XYZ")
```

**The block asserts that the code raised.** Without `pytest.raises` the exception escapes and the
test errors, which looks like a broken test rather than a proven behaviour.

## `match` is not optional in practice

```python
with pytest.raises(KeyError):        # ANY KeyError passes
    rate("XYZ")
```

A typo in the test itself raises `KeyError` too, and so does a dictionary lookup three frames
down that has nothing to do with the case. `match` takes a regular expression searched against
the message:

```sh
E       AssertionError: Regex pattern did not match.
E         Expected regex: 'no such currency'
E         Actual message: "'unknown currency XYZ'"
```

## Looking at the exception

```python
with pytest.raises(ValueError) as e:
    parse("nonsense")
assert e.value.field == "amount"
```

`e.value` is the exception object, available after the block. The assertions go **outside** the
`with`, because inside it nothing after the raising line runs.

## The float that is never equal

```python
def test_float():
    assert 0.1 + 0.2 == 0.3          # fails
```

Binary floating point cannot hold `0.1`, so the sum is `0.30000000000000004`. This is arithmetic
rather than a bug, and it arrives in every test that adds money, averages a column or converts a
rate.

```python
def test_float_approx():
    assert 0.1 + 0.2 == pytest.approx(0.3)
```

`approx` compares within a tolerance — relative `1e-6` by default, and `abs=` or `rel=` when you
need your own. It also reports better:

```sh
E       assert 0.30000000000000004 == 0.4 ± 4.0e-07
```

The plain assertion printed `assert (0.1 + 0.2) == 0.3` and hid the value that mattered.

## And what `approx` is not for

Money. A price is integer cents and compares exactly; reaching for a tolerance there is agreeing
in advance to be a cent out. `approx` is for measurements, rates and anything that went through a
division.
