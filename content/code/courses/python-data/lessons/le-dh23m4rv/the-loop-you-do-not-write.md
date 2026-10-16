---
title: The loop you no longer write
version: 1
---

**In NumPy you write the operation once, for the whole array, and the loop happens in compiled code
underneath.** That is what "vectorised" means, and it is the single habit that separates code that
uses NumPy from code that merely imports it.

Start this lesson's notebook with the weather again:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
rain, temp = weather[:, 0], weather[:, 1]
```

A colleague in Lisbon wants the temperatures in Fahrenheit. The loop a Python programmer writes
first:

```python
fahrenheit = []
for t in temp:
    fahrenheit.append(t * 9 / 5 + 32)
fahrenheit[:3]
```

```
[np.float64(85.82), np.float64(86.0), np.float64(87.26)]
```

And the same thing, vectorised:

```python
(temp * 9 / 5 + 32)[:3]
```

```
array([85.82, 86.  , 87.26])
```

Same numbers. The difference is in what the second one does not do: it does not fetch each value,
wrap it in a Python object, call `*` through the interpreter and append it to a list, 365 times.
`temp * 9` is **one** call into compiled code that walks the block of floats once. The loop
version also returns numbers wrapped as `np.float64`, one Python object each, which is a hint of
the work it does.

## How much faster

With 365 values both are instant. The difference is visible at the size real data has. Here is a
year of readings repeated a thousand times, 365,000 values, and IPython's `%timeit`, which runs a
line many times and reports the typical time:

```python
big = np.tile(temp, 1000)
loop = %timeit -o -q [t * 9 / 5 + 32 for t in big]
vec = %timeit -o -q big * 9 / 5 + 32
round(loop.average * 1000, 1), round(vec.average * 1000, 2), round(loop.average / vec.average)
```

```
(97.9, 0.69, 142)
```

`np.tile` repeats an array end to end. The list comprehension, already the fastest way to write a
loop in Python, takes around a tenth of a second; the vectorised line takes under a millisecond,
**more than a hundred times faster** on the machine this was recorded on. Your times will differ.
The gap comes from where the loop runs, in the interpreter or in compiled code, and that is the
same on every machine.

Speed is the argument people quote. The better argument is that the vectorised line **says what it
computes**: a conversion, applied to a column. There is no index, no accumulator and no `append`
to get wrong.
