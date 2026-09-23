---
title: The comprehension with parentheses
version: 2
---

```python
[x * 2 for x in xs]       # a list, built now
(x * 2 for x in xs)       # a generator, built never
```

Same syntax, different brackets, completely different behaviour. The first walks `xs` and
returns a list. The second returns a generator that has done nothing at all.

## Where it saves something

```python
total = sum(int(row["amount"]) for row in rows)
```

No list of a million numbers exists at any point. When the call already has brackets of its own,
the extra pair is unnecessary — `sum(x for x in xs)` rather than `sum((x for x in xs))`.

## Where it saves nothing

```python
names = [p["name"] for p in people]        # you want the list
```

If you are going to keep it, index it, or walk it twice, build the list. A generator you
immediately call `list()` on is a list comprehension with extra words.

**The test is what happens next.** Straight into `sum`, `max`, `any`, `all`, `"".join`, another
generator, or a `for` loop that runs once — generator. Anything else — list.

## `any` and `all`

```python
if any(r["city"] == "Porto" for r in rows):
```

Both short-circuit, so this stops at the first match rather than checking a million rows. With a
list comprehension inside them, it would build the whole list first and then stop at the first
item — which is the same answer and none of the saving.

## The one that bites

```python
gen = (x for x in rows)
print(len(gen))          # TypeError
```

A generator has no length, because it does not know one. `sum(1 for _ in gen)` counts it — and
spends it, which is the other half of the lesson.
