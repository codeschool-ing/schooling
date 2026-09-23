---
title: Four containers and four loops you no longer write
version: 2
---

## `Counter`

```python
from collections import Counter

counts = Counter(words)
counts["python"]              # 0 if absent, rather than a KeyError
counts.most_common(3)
```

Counting is the most-written loop there is, and this is it in one line. `most_common` is the sort
you would have written afterwards, and the subtraction and addition of two `Counter`s work the
way you would hope.

## `defaultdict`

```python
from collections import defaultdict

by_city = defaultdict(list)
for person in people:
    by_city[person["city"]].append(person)
```

Grouping, without the `if key not in d` line. The argument is a FUNCTION called to make the
missing value — `list`, `int`, `set` — which is lesson 5's "a function is a value" doing work.

**`dict.setdefault` does the same thing for one lookup**, and a `defaultdict` is clearer the
moment there are two.

## `namedtuple`

```python
from collections import namedtuple
Point = namedtuple("Point", "x y")
p = Point(1, 2)
p.x
```

A tuple whose positions have names. Lesson 6's `@dataclass(frozen=True)` does more and reads
better; `namedtuple` is what you will meet in older code, and it is still the lightest way to
stop writing `row[2]`.

## `deque`

```python
from collections import deque
recent = deque(maxlen=100)
recent.append(item)            # the oldest falls off the end
```

A list is slow to remove from the FRONT — every other item shifts. A `deque` is not, and
`maxlen` gives you a fixed-size window of the last n things for free.

## Four `itertools` that earn their import

```python
from itertools import product, chain, groupby, islice

product(sizes, colours)          # every pair, without the nested loop
chain(a, b, c)                   # iterate three lists as one
islice(rows, 10)                 # the first ten of anything, without a list
groupby(sorted(rows, key=k), k)  # runs of equal keys — SORT FIRST
```

`groupby` is the one that catches people: it groups CONSECUTIVE equal keys, so unsorted input
gives you the same key several times and nobody says anything. Sorting by the same key first is
not optional.

All four return iterators — lesson 11's subject — which is why `islice(rows, 10)` on a
million-row file reads ten rows rather than a million.
