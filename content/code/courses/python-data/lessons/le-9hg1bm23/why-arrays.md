---
title: Why an array, when Python has lists
version: 1
---

**A Python list holds references to objects scattered around memory; a NumPy array holds the
numbers themselves, side by side, all of one type.** Everything NumPy is good at follows from that
one difference: speed, compact storage, and arithmetic on a whole column at once. Everything it is
strict about follows from it too.

Start a notebook for this lesson in `pydata` and read the year's weather, two numeric columns,
straight into an array:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
weather[:3]
```

```
array([[ 0. , 29.9],
       [ 6.8, 30. ],
       [ 7.9, 30.7]])
```

`genfromtxt` reads a text file of numbers into an array. `usecols=(1, 2)` takes the rain and the
temperature and leaves the date, which is not a number; `skip_header=1` skips the line of names.
What comes back is a table of numbers with no column names at all: pandas, from lesson 9, is what
adds them.

```python
weather.shape, weather.dtype
```

```
((365, 2), dtype('float64'))
```

Three hundred and sixty-five rows, two columns, every value a 64-bit float. The six days with no
rain reading did not stop the file loading. Each empty field became `nan`, **not a number**, a
special float value that NumPy can store because the column is a float column:

```python
rain = weather[:, 0]
np.isnan(rain).sum()
```

```
np.int64(6)
```

`weather[:, 0]` is the first column, every row; lesson 7 is about that notation. `np.isnan` asks
the question of every value at once and answers with an array of `True` and `False`, and `.sum()`
counts the `True`s. **No loop was written**, and that is the habit this part of the course is
about.

## What the list costs

The same 365 rain readings, as a Python list and as an array:

```python
import sys

as_list = rain.tolist()
list_bytes = sys.getsizeof(as_list) + sum(sys.getsizeof(x) for x in as_list)
list_bytes, rain.nbytes
```

```
(11736, 2920)
```

The list needs a pointer per element plus a whole Python `float` object for each reading, with
its type and its reference count; the array needs eight bytes per reading and nothing else.
**Roughly four times smaller**, and the gap is the same at a million rows. The second benefit is
larger and is lesson 5's subject: arithmetic on an array runs as one loop in compiled code instead
of 365 trips through the interpreter.

The price is strictness. Every element of an array has the same type, decided when the array is
made, and the array does not grow in place: there is no `append` that adds to it cheaply. A list
is a container; an array is a block of numbers with a shape.
