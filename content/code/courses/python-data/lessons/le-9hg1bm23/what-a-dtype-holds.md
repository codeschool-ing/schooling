---
title: What a dtype holds, and what it silently does not
version: 1
---

**A dtype is a promise about how many bits each number gets, and NumPy keeps the promise even when
the number does not fit.** A Python `int` grows as large as it needs; an `int8` has eight bits and
holds -128 to 127, and arithmetic past the edge wraps round:

```python
small = np.array([120, 125, 127], dtype=np.int8)
small + 5
```

```
array([ 125, -126, -124], dtype=int8)
```

`127 + 5` became `-124`, with no error and no warning. That is not a bug in NumPy: it is what an
8-bit register does, and NumPy exposes it because checking every addition would cost the speed the
array exists for. The defence is to know the range of what you store. `np.iinfo` tells you:

```python
np.iinfo(np.int8), np.iinfo(np.int64).max
```

```
(iinfo(min=-128, max=127, dtype=int8), 9223372036854775807)
```

The default integer, `int64`, reaches nine quintillion, which nothing in this course approaches.
The small types matter when memory does, and lesson 20 uses them on purpose.

## Floats are approximations

`float64` holds about 15 significant decimal digits, and most decimal fractions are not exact in
binary:

```python
x = np.array([0.1, 0.2])
x.sum(), x.sum() == 0.3, np.isclose(x.sum(), 0.3)
```

```
(np.float64(0.30000000000000004), np.False_, np.True_)
```

**Never compare floats with `==`.** `np.isclose` compares within a tolerance, and it is the test
every lesson after this uses. `float32` halves the memory and keeps about 7 digits, which is enough
for a chart and not enough for money; this course counts reais in integer centavos when it needs
them exact.

## Converting, and what is lost

`astype` makes a new array of another type. From float to integer it **truncates towards zero**,
it does not round:

```python
temps = np.array([29.9, 30.5, -0.7])
temps.astype(int), np.round(temps).astype(int)
```

```
(array([29, 30,  0]), array([30, 30, -1]))
```

And `nan` has no integer form at all. A float column with a missing value cannot become an integer
column; NumPy does not refuse, it writes an arbitrary integer in its place and warns:

```python
rain[:5], rain[np.isnan(rain)][:1].astype(int)
```

```
/tmp/ipykernel_11181/698349897.py:1: RuntimeWarning: invalid value encountered in cast
  rain[:5], rain[np.isnan(rain)][:1].astype(int)
(array([ 0. ,  6.8,  7.9, 15.7,  0. ]), array([-9223372036854775808]))
```

This is the reason pandas, in lesson 12, has integer types that can hold a missing value. In plain
NumPy, a column with gaps stays float.
