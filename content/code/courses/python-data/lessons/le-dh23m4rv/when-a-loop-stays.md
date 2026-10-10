---
title: When a loop stays a loop
version: 1
---

**Not everything vectorises, and some things that can be vectorised should not be.** The rule of
thumb is not "never write a loop"; it is "never loop over the elements of a large array when an
operation on the whole array exists". Three cases where the loop, or something like it, stays.

## `np.vectorize` is a loop with better manners

`np.vectorize` wraps an ordinary Python function so that it accepts arrays. It looks like the
answer to "how do I vectorise my function", and it is not: the documentation says it is a loop, and
the clock agrees.

```python
def describe(mm):
    if mm == 0:
        return "dry"
    return "light" if mm < 10 else "heavy"

describe_all = np.vectorize(describe)
describe_all(rain[:5])
```

```
array(['dry', 'light', 'light', 'heavy', 'dry'], dtype='<U5')
```

The rain repeated a thousand times, as in the first section, with the unread days as zero:

```python
big_rain = np.tile(np.nan_to_num(rain), 1000)
big_rain.shape
```

```
(365000,)
```

```python
slow = %timeit -o -q describe_all(big_rain)
fast = %timeit -o -q np.select([big_rain == 0, big_rain < 10], ["dry", "light"], "heavy")
round(slow.average * 1000, 1), round(fast.average * 1000, 1)
```

```
(123.7, 6.8)
```

`np.select` is `np.where`
for more than two choices: a list of conditions, a list of values, and a default, checked in order,
in compiled code. The vectorised version wins by a wide margin. `np.vectorize` is a convenience for
applying a function to arrays of any shape; it does not make the function fast.

## When each value depends on the one before

The longest run of dry days in the year. Each day's run length is the previous day's plus one, or
zero after rain: **each value depends on the one before it**, and that is the case NumPy has no
single operation for. A loop says it plainly:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "longest = current = 0\n",
      "note": "Two counters: the best run so far, and the run that ends today."
    },
    {
      "code": "for mm in np.nan_to_num(rain):\n",
      "note": "One day at a time. An unread day counts as dry here, which is a choice to state."
    },
    {
      "code": "    current = current + 1 if mm == 0 else 0\n",
      "note": "A dry day extends today's run; any rain resets it to zero. This line needs yesterday's value, which is what no single array operation gives."
    },
    {
      "code": "    longest = max(longest, current)\n",
      "note": "Keep the best run seen."
    },
    {
      "code": "longest\n",
      "note": "Fourteen days in a row without rain."
    }
  ],
  "output": "14\n"
}
```

There are vectorised tricks for runs, built from `diff` and `cumsum`, and they are hard to read and
easy to get wrong. On 365 values the loop takes no measurable time. **Clarity wins until size
makes it lose**, and lesson 17 meets the same trade-off in pandas, where `apply` is the loop.

## When the temporaries do not fit

`big * 9 / 5 + 32` creates a whole new array for `big * 9`, another for the division, and a third
for the sum. For 365,000 floats that is three 2.9 MB arrays and nobody notices. For an array that
fills half your memory, the temporaries do not fit. In-place operators reuse the same block:

```python
f = big.copy()
f *= 9
f /= 5
f += 32
np.isclose(f, big * 9 / 5 + 32).all()
```

```
np.True_
```

`*=` writes the result into `f` itself. It is uglier and only worth it when memory is the problem;
lesson 20 is about the day it is.
