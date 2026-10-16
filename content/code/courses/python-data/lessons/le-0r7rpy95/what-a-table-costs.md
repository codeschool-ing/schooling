---
title: What a table costs
version: 1
---

**A DataFrame lives in memory, and how much memory depends on its types far more than on its
values.** A column of numbers costs eight bytes a row; a column of text costs the text, plus Python's
bookkeeping for every string. Before a table is too big to load, it is already worth knowing which
of its columns are expensive, and why.

The trips as `read_csv` gives them, with no types chosen:

```python
import os
import time
import numpy as np
import pandas as pd

trips = pd.read_csv("trips.csv")
trips.dtypes
```

```
trip_id          int64
started_at         str
ended_at           str
start_station      str
end_station        str
plan               str
bike               str
dtype: object
```

One integer column and six of text: the times are text too, because nothing told `read_csv` they
were dates. What each costs, in bytes:

```python
trips.memory_usage(deep=True)
```

```
Index               132
trip_id          266696
started_at       900099
ended_at         901493
start_station    366707
end_station      370437
plan             437021
bike             511710
dtype: int64
```

`deep=True` measures the strings themselves; without it pandas reports only the size of the
references to them, which looks cheap and is not the memory the table uses. `trip_id` costs 8 bytes
a row, 266,696 for 33,337 rows. Each time column costs over three times that, and `bike`, which holds
only one of two words, costs nearly twice what `trip_id` does, because every row keeps its own copy
of `classic` or `electric`.

The table against the file it came from:

```python
trips.memory_usage(deep=True).sum(), os.path.getsize("trips.csv")
```

```
(np.int64(3754295), 2267957)
```

**The table takes more memory than the file takes disk**, 3.75 MB against 2.27 MB here. That ratio
is the number to remember when someone hands you a file: a CSV of a few gigabytes needs more than
that in memory once pandas has read it as text, 1.6 times here and more where the text is short and
repeated, and a laptop's memory is where the work stops.
The next section brings the table under the size of the file, by changing only its types.
