---
title: Iterate the thing, not the index
version: 2
---

```python
for lang in langs:
    print(lang)
```

No counter, no length, no index. The loop asks the collection for its items and the collection
hands them over.

**This is not a style preference.** Counting means an index, an index means an off-by-one, and an
off-by-one in a loop is the most common bug there is. Iterating the thing removes the opportunity.

## When you need the position

```python
for i, lang in enumerate(langs):
    print(i, lang)
```

`enumerate` gives you both, and takes a `start=1` when you are numbering for a person.

**Almost every `for i in range(len(xs))` is this in disguise.** If you find yourself writing one,
the question is whether you want `enumerate` or whether you wanted the items all along.

## Two collections together

```python
for name, score in zip(names, scores):
```

`zip` stops at the shorter one, silently. That is fine when you know they match and it is a hole
when you do not — `zip(a, b, strict=True)` raises instead, and it is worth the extra word.

## What can be iterated

Lists, tuples, sets, strings, dictionaries, files, and anything lesson 11 calls an iterator.

```python
for ch in "ada":          # characters
for key in person:        # a dictionary's KEYS
for k, v in person.items():
for line in open("f.txt"):  # one line at a time
```

**A dictionary iterates its keys**, which catches people who expected pairs.

## `range`

```python
range(5)          # 0 1 2 3 4
range(1, 6)       # 1 2 3 4 5
range(0, 10, 2)   # 0 2 4 6 8
```

The stop is exclusive, like a slice, for the same reason: `range(n)` has `n` items.

**`range` is for when you genuinely want numbers** — a fixed number of attempts, a grid — and not
as a way to index a list.

## `break`, `continue`, and the `else` nobody expects

```python
for item in items:
    if matches(item):
        break
else:
    print("nothing matched")
```

`break` leaves the loop; `continue` skips to the next item. **The `else` runs when the loop ended
without a `break`** — it is genuinely useful for search, it is read wrongly by almost everyone,
and a comment beside it is worth the two words.
