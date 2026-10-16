---
title: Hidden state, and the variable whose cell is gone
version: 1
---

**Deleting a cell does not delete what it did.** The kernel ran it, and whatever it assigned is
still in memory, available to every cell after it, with nothing on the page to show where it came
from. That is hidden state, and it is the second way a notebook works for its author and nobody
else.

Ana is counting trips by plan. She tries a threshold to separate short rides from long ones:

```python
import csv
with open("trips.csv") as f:
    trips = list(csv.DictReader(f))
short_limit = 15 * 60
len(trips)
```

```
33337
```

```python
from datetime import datetime

def minutes(trip):
    if not trip["ended_at"]:
        return None
    start = datetime.fromisoformat(trip["started_at"])
    end = datetime.fromisoformat(trip["ended_at"])
    return (end - start).total_seconds() / 60
```

Later she decides the limit belongs inside a function, writes this, and deletes the first cell's
`short_limit` line as untidy:

```python
def is_short(trip):
    m = minutes(trip)
    return m is not None and m * 60 < short_limit

sum(is_short(t) for t in trips)
```

```
17919
```

It runs, because `short_limit` is still in the kernel from the line she deleted. Ask the kernel
what it holds and the orphan is there, listed with everything else, including `total` from the
first section of this lesson, which is in the same notebook:

```python
%who
```

```
csv	 datetime	 f	 is_short	 minutes	 short_limit	 total	 trips	 
```

`%who` is an IPython **magic**, a command for the kernel itself rather than Python, written with a
`%` in front. It lists every name the notebook has made, and it is the quickest way to find a
variable no cell on the page defines. `%whos` adds each one's type and a short view of its value.

The kernel can be emptied without restarting it, which is the closest a cell gets to a fresh
start:

```python
%reset -f
sum(is_short(t) for t in trips)
```

```
NameError: name 'trips' is not defined
```

After `%reset -f` nothing is defined, not even the functions; `trips` is merely the first missing
name the line meets. Running the page from the top again is the only way back. Had she done that, the cell that uses `short_limit` would fail with
`NameError` on the first run, which is exactly what should happen to a notebook that refers to a
line that no longer exists. **Restart Kernel**, in the Kernel menu, does the same and more: it
ends the Python process and starts a new one, so even imported modules are loaded again.

## Two more ways to leave something behind

**A redefined function, with old outputs above it.** Change `minutes` and run the new version: the
cells above that already ran keep the outputs they got from the old one. The page now shows
results from two different functions with one name.

**A value overwritten further down.** A cell near the end sets `trips = trips[:1000]` to test
something quickly. Every cell run after it, including ones higher up the page that you rerun,
works on a thousand trips while the outputs saved from before still describe 33,337.

None of these raise an error. That is their whole danger, and why the fix is a habit rather than
a rule: the section after next.
