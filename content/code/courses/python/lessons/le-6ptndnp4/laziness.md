---
title: Nothing happens until something asks
version: 1
---

```python
def naturals():
    n = 0
    while True:
        yield n
        n += 1
```

That loop never ends, and the function is perfectly safe — because nothing runs until somebody
calls `next`. An infinite generator is a legal, ordinary thing.

```python
from itertools import islice
list(islice(naturals(), 5))       # [0, 1, 2, 3, 4]
```

## What laziness buys

- **Memory**: one value at a time, however many there are.
- **Time**: the work for value six hundred never happens if you stop at five.
- **Composition**: a chain of generators is still one value at a time, which is the next section.
- **The impossible**: a stream with no end — a log being written, a sequence, a poll.

## Where it ends

```python
sorted(gen)       # needs everything
len(list(gen))    # needs everything
max(gen)          # needs everything, but only one at a time
```

**Laziness survives exactly as far as the first thing that needs the whole collection.** `sorted`
and `list` build it; `max`, `sum` and `any` do not. Knowing which is which is knowing where the
memory in your program arrives.

## The debugging consequence

```python
rows = (parse(line) for line in f)
# ... fifty lines later, in another function
for row in rows:        # the parse errors appear HERE
```

The traceback points at the loop, and the bug is in `parse`, fifty lines and one function away.
That is the price of the laziness, and it is why a generator with real work in it deserves a name
that says where it came from.

## And the file that was closed

```python
def rows(path):
    with open(path) as f:
        for line in f:
            yield line      # the file stays open while this is iterated
```

The `with` closes when the generator is exhausted — or when it is garbage collected, which is
later than you think. A generator that is abandoned half-way holds the file open until then.
