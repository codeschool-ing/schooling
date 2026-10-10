---
title: The order of additions, and the last digit of a sum
version: 1
---

**Floating-point addition is not associative: `(a + b) + c` can differ from `a + (b + c)`.** Each
addition rounds its result to the nearest representable float, and which roundings happen depends
on the order. Lesson 3 promised the consequence: the same sum, taken in a different order, can
print a different last digit, and nothing is wrong.

The extreme case fits in three numbers:

```python
np.array([1e16, 1.0, -1e16]).sum(), np.array([1e16, -1e16, 1.0]).sum()
```

```
(np.float64(0.0), np.float64(1.0))
```

In the first order, `1e16 + 1.0` rounds back to `1e16`, because a float that large has no room for
the units digit, and the 1 is lost before the subtraction. In the second, the two large numbers
cancel first and the 1 survives. Same three numbers, answers `0.0` and `1.0`.

## A long sum, three ways

Real data is not that extreme, and the effect is there in the last digits. Ten tenths, added the way
a plain loop adds them, one after another:

```python
import math

tenths = np.full(10, 0.1)
total = 0.0
for x in tenths:
    total += x
total, tenths.sum(), sum(tenths.tolist()), math.fsum(tenths)
```

```
(np.float64(0.9999999999999999), np.float64(1.0), 1.0, 1.0)
```

The loop accumulates a rounding error at every step and ends just short of 1. The other three give
`1.0`, each for its own reason. NumPy's `sum` adds the array in pieces and then adds the pieces'
totals, a method called **pairwise summation** that keeps the error small on long arrays. Python's
built-in `sum` has compensated for lost bits since Python 3.12. `math.fsum` tracks every lost bit
and returns the correctly rounded total, at a cost in speed.

The year's temperatures, repeated a thousand times, added by a loop and by NumPy:

```python
long = np.tile(temp, 1000)
running = 0.0
for x in long.tolist():
    running += x
running, long.sum(), math.fsum(long)
```

```
(10927899.99999855, np.float64(10927900.0), 10927900.0)
```

365,000 additions in a row, and the loop's total has drifted by about a millionth, while the
other two agree.

## Precision runs out faster in `float32`

A `float32` keeps about seven significant digits. A running total kept in `float32`, which is what
`cumsum` does step by step, has nothing left for the decimals of each new day once it reaches the
hundreds of thousands:

```python
long_rain = np.tile(np.nan_to_num(rain), 1000).astype(np.float32)
np.cumsum(long_rain)[-1], long_rain.sum()
```

```
(np.float32(1.712768e+06), np.float32(1.7128e+06))
```

`np.nan_to_num` replaces `nan` with 0, a choice made for this demonstration and not one to make
silently on real data. The step-by-step total has lost about 32 millimetres out of 1.7 million;
the pairwise sum of the same `float32` numbers has not. For totals that matter, keep `float64`.

## What to do about it

- **Compare floats with a tolerance**, `np.isclose`, never with `==`. Two correct computations of
  the same total can differ in the last digit.
- **Round for display, not for calculation.** Round once, at the end, to the precision the number
  deserves: rainfall to a tenth of a millimetre.
- **Money is not a float.** Count centavos in integers, which add exactly in any order.
