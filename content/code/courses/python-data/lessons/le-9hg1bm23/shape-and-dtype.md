---
title: Shape, dtype, and the ways to make an array
version: 1
---

**Every array answers the same few questions about itself**, and reading them is the first thing to
do with an array you did not make. Here is a small one with a meaning: the number of docks at each
of five stations, made from a list:

```python
docks = np.array([14, 20, 12, 17, 10])
docks.ndim, docks.shape, docks.size, docks.dtype, docks.itemsize
```

```
(1, (5,), 5, dtype('int64'), 8)
```

| attribute | says |
|---|---|
| `ndim` | how many axes: 1 for a row of numbers, 2 for a table |
| `shape` | how long each axis is, as a tuple: `(5,)` is five numbers in one axis |
| `size` | how many elements in all |
| `dtype` | the type every element shares |
| `itemsize` | how many bytes one element takes |

**`(5,)` with its comma is a tuple of one**, and the difference between `(5,)` and `(5, 1)` is the
subject of lesson 6. NumPy chose `int64` because every value was a whole number; one decimal point
anywhere and the whole array is float:

```python
np.array([14, 20, 12.5]).dtype, np.array([14, "20"]).dtype
```

```
(dtype('float64'), dtype('<U21'))
```

The second one is a warning. A list with one string in it became an array of **strings**, `<U21`:
little-endian Unicode, up to 21 characters each, and no arithmetic will work on it. NumPy does not
refuse a mixed list; it finds a type that holds everything, and for numbers mixed with text that
type is text.

## Making arrays without a list

Most arrays are not typed in. The constructors you will use every day:

```python
np.zeros(3), np.ones((2, 3), dtype=int), np.arange(0, 24, 6), np.linspace(0, 1, 5)
```

```
(array([0., 0., 0.]),
 array([[1, 1, 1],
        [1, 1, 1]]),
 array([ 0,  6, 12, 18]),
 array([0.  , 0.25, 0.5 , 0.75, 1.  ]))
```

- `np.zeros` and `np.ones` take a shape, and make floats unless told otherwise.
- `np.arange` is `range` for arrays: start, stop and step, with the stop left out.
- `np.linspace` takes a start, a stop and **how many points**, and includes the stop. For
  fractional steps it is the safer one, because `arange` with a float step can produce one element
  more or fewer than you expect when the step does not divide the range exactly in binary.

A two-dimensional array is a table, with rows first:

```python
hours = np.arange(24).reshape(4, 6)
hours
```

```
array([[ 0,  1,  2,  3,  4,  5],
       [ 6,  7,  8,  9, 10, 11],
       [12, 13, 14, 15, 16, 17],
       [18, 19, 20, 21, 22, 23]])
```

`reshape(4, 6)` reads the 24 numbers into four rows of six. The numbers are not moved or copied,
which is the subject of the last two sections, and the product of the new shape must equal the old
size:

```python
np.arange(24).reshape(5, 5)
```

```
ValueError: cannot reshape array of size 24 into shape (5,5)
```
