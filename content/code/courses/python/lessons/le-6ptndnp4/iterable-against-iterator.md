---
title: The one you can walk twice, and the one you cannot
version: 1
---

**An ITERABLE can produce an iterator.** A list, a tuple, a string, a dictionary, a set.

**An ITERATOR produces values, once.** What `iter()` gives you, what a generator is, what `zip`
and `map` return in Python 3.

```python
xs = [1, 2, 3]
sum(xs)      # 6
sum(xs)      # 6 — a fresh iterator each time

g = (x for x in [1, 2, 3])
sum(g)       # 6
sum(g)       # 0 — and nothing says why
```

## That zero is the trap

It is not an error. `sum` asked for values, got none, and returned its starting value. The same
thing with `max` raises `ValueError`, and with `"".join` gives an empty string, and with a `for`
loop simply does not run the body.

**A result that is zero, empty or missing, from code that worked last week, is this** — and the
line to look at is wherever the generator was first consumed.

## An iterator is also an iterable

```python
iter(it) is it       # True
```

Which is why you can put a generator in a `for` loop directly. It also means a function taking
"an iterable" cannot tell whether it can walk it twice — and a function that walks its argument
twice is a function that silently breaks on a generator.

## If you need it twice

```python
rows = list(rows)        # deliberately, and now it fits in memory or it does not
```

There is no way to rewind an iterator. `itertools.tee` exists and buys nothing when both copies
are consumed fully — it keeps what one has seen and the other has not, which is a list with more
steps.

The other answer is to go back to the source: open the file again, run the query again. For
something big that is the correct answer rather than the lazy one.
