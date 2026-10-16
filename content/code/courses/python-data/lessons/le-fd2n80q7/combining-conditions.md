---
title: Combining conditions, and the error everybody meets
version: 1
---

**Masks combine with `&`, `|` and `~`, not with `and`, `or` and `not`, and each comparison needs its
own parentheses.** Both rules come from Python itself rather than from NumPy, and both produce an
error the first time.

Heavy rain on a hot day, written the way English says it:

```python
(rain > 20) and (temp > 31)
```

```
ValueError: The truth value of an array with more than one element is ambiguous. Use a.any() or a.all()
```

`and` asks Python whether the left side is true **as a whole**, and for an array of 365 booleans
there is no single answer: some are `True` and some are not. NumPy refuses to guess, and the message
names the two ways to collapse an array into one truth value, `any()` and `all()`, in case that is
what you meant. It is not what you meant here. The elementwise operators are `&` for and, `|` for
or, and `~` for not:

```python
both = (rain > 20) & (temp > 31)
both.sum(), dates[both]
```

```
(np.int64(2), array(['2025-08-02', '2025-08-14'], dtype='<U10'))
```

## Why the parentheses

Leave them out and the expression still parses, into something else:

```python
rain > 20 & temp > 31
```

```
TypeError: ufunc 'bitwise_and' not supported for the input types, and the inputs could not be safely coerced to any supported types according to the casting rule ''safe''
```

`&` binds more tightly than `>`, so Python reads `rain > (20 & temp) > 31`, a bitwise and of the
integer 20 with an array of floats, which NumPy refuses with a different error. **Put every
comparison in its own parentheses**, every time, and neither error happens.

## Building a mask in steps

A long condition reads better as named masks, each one a line, combined at the end:

```python
wet = rain > 10
warm = temp > 30.5
weekend = np.isin(np.arange(365) % 7, [3, 4])
(wet & warm & weekend).sum(), (wet & ~weekend).sum()
```

```
(np.int64(5), np.int64(41))
```

`np.isin` asks whether each element is in a list. `np.arange(365) % 7` is each day's position in
its week, and 2025 began on a Wednesday, so positions 3 and 4 are Saturday and Sunday. Each mask has
a name that says what it means, and the line that combines them reads like the question.
