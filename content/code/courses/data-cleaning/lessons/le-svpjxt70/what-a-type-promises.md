---
title: What a type promises
version: 1
---

Every file in this course has been read the same way since lesson 2:

```python
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
```

**`dtype=str` turns every column into text, and that was a choice, not a shortcut.** Text holds
anything. A year typed as `1900`, a price written `R$ 94,50`, a consent recorded as `não`: each
arrives exactly as it was written, and nothing is rounded, guessed or dropped on the way in. A
reader that guessed types for you would have made those decisions silently, before you had looked
at a single row.

The cost is that text promises nothing. You cannot add two strings and get a sum, and `"9" > "10"`
is true, because text compares character by character. Sorting birth years as text works only by
luck, while every year happens to have four digits.

A type is a promise about every value in a column:

- **an integer** can be added, averaged and compared by size;
- **a date** can be subtracted from another date and grouped by month;
- **a boolean** is true or false, and nothing else;
- **a blank**, in each of them, means "not known", and is kept apart from every real value.

Converting a column is the moment you make that promise, and the moment you find out which values
break it. **A conversion that fails loudly is telling you something about the data.** A conversion
that succeeds by turning the values it could not read into blanks has hidden the most useful thing
it learnt. The rest of this lesson is about making every conversion the loud kind.
