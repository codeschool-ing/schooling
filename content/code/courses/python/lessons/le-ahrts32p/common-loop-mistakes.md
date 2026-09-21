---
title: The three that do not raise
version: 1
---

Every one of these produces a wrong answer rather than an error, which is what makes them worth a
section.

## Changing a list while iterating it

```python
>>> xs = [1, 2, 3, 4]
>>> for x in xs:
...     if x % 2 == 0:
...         xs.remove(x)
>>> xs
[1, 3, 4]
```

The `4` survived. The loop keeps its own position; removing `2` slid `3` into position 1, and the
loop had already moved on to position 2.

**Iterate a copy, or build a new list:**

```python
xs = [x for x in xs if x % 2 != 0]      # the usual answer
for x in xs[:]:                          # or iterate a copy
```

The same applies to a dictionary — changing its size during iteration raises `RuntimeError`,
which is at least loud.

## The off-by-one

```python
for i in range(1, len(items)):    # skips items[0]
for i in range(len(items) + 1):   # IndexError on the last pass
```

Both come from computing an index. **`for item in items` cannot be off by one**, and `enumerate`
cannot either.

## The variable that outlives the loop

```python
for item in items:
    ...
print(item)        # the last one — or NameError if items was empty
```

Python has no block scope: the loop variable stays after the loop, holding whatever it had last.
Reading it deliberately is legitimate and rare; reading it by accident is a bug that works on
every non-empty input and raises on the empty one.

## And one that does raise, eventually

```python
total = 0
for row in rows:
    total += row["amount"]
```

Correct — until a row has no `amount`. `row.get("amount", 0)` is the decision to treat it as zero,
said out loud. Lesson 8 is the other answer: catch it and say which row.
