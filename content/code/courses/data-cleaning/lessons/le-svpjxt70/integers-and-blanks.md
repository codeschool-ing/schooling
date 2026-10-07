---
title: Whole numbers with holes in them
version: 1
---

The birth years converted above came out as `1986.0`, with a decimal point that no year has. That
is not a rounding problem. **A plain integer column in pandas cannot hold a blank**, so the moment
one blank appears, the whole column is stored as floating point, where `NaN` lives:

```
ana@lab:~/clean$ python -c "import pandas as pd; s = pd.Series(['1987', None, '2001']); print(pd.to_numeric(s).to_string()); print(pd.to_numeric(s).astype('Int64').to_string())"
0    1987.0
1       NaN
2    2001.0
0    1987
1    <NA>
2    2001
```

The first print is the default: two years written as decimals and a `NaN`. The second is the same
values as `Int64`, with a capital I, which is pandas' nullable integer. The years are whole again,
and the blank is `<NA>`, a marker that means "not known" in every nullable type (`Int64`,
`boolean`, `string`) rather than a special floating-point number.

The difference matters beyond looks:

- **A float year invites arithmetic that makes no sense**, such as an average birth year of
  1983.47 written back into a column of years.
- **Floats lose integers past a certain size.** A customer code or an order number of sixteen
  digits stored as a float may come back with its last digits changed; the nullable integer keeps
  it exact.
- **A float written to a file comes back as `1986.0`.** The next person who reads that file as text,
  as this course does, holds a key that no longer equals `1986`, and a join on it matches nothing
  without raising an error.

So the habit is two steps, in this order: convert with the count from the previous section, then
cast to the nullable type. A column that is an identifier rather than a quantity, such as a CEP or
a product code with leading zeros, is not converted at all; lesson 7 kept those as text, and **a
number is only a number if adding two of them means something**.
