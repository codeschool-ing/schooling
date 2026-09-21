---
title: `int` has no ceiling; `float` cannot hold a third
version: 1
---

Two numeric types carry almost everything.

## `int`

Whole numbers, positive or negative, **with no upper limit**:

```python
>>> 2 ** 100
1267650600228229401496703205376
```

That is not a trick. Python grows the integer as needed, which means no overflow and no `long`
type to remember. The cost is speed, and it is not a cost you will meet in this course.

## `float`

Decimals, stored the way every language stores them — in binary, with 53 bits of precision. Which
leads to the one thing everybody has to be told once:

```python
>>> 0.1 + 0.2
0.30000000000000004
```

**This is not a Python defect.** One tenth cannot be written exactly in binary, the same way one
third cannot be written exactly in decimal. The value stored is very slightly off, and adding two
slightly-off values shows the error.

Two consequences:

**Never compare floats with `==`.** `0.1 + 0.2 == 0.3` is `False`. Compare with a tolerance, or
use `math.isclose`, which lesson 7 covers.

**Never hold money in a float.** `Decimal` from the standard library is exact for this, and the
platform you are reading this on holds every price as an integer number of cents for the same
reason.

## The operators

| | | |
|---|---|---|
| `+` `-` `*` | as you expect | |
| `/` | true division, **always a float** | `4 / 2` is `2.0` |
| `//` | floor division, the whole part | `7 // 2` is `3` |
| `%` | remainder | `7 % 2` is `1` |
| `**` | power | `2 ** 10` is `1024` |

**`//` and `%` round towards minus infinity**, which is worth knowing before it surprises you:

```python
>>> -7 // 2
-4
>>> -7 % 2
1
```

Not `-3` and `-1`. The rule Python keeps is that `a == (a // b) * b + a % b`, and the remainder
takes the sign of the divisor. For a positive divisor the remainder is never negative, which is
exactly what you want when you are cycling through a list.

## Mixing them

Any arithmetic touching a float produces a float. `2 + 2.0` is `4.0`, and `4 / 2` is `2.0` even
though both sides were whole. If you want an integer back, `//` or `int()` — and `int()`
truncates towards zero rather than rounding, which is what `round()` is for.
