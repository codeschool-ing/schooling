---
title: The same shape with braces, and the one that is neither
version: 2
---

## Dictionary

```python
by_id = {p["id"]: p for p in people}
lengths = {word: len(word) for word in words}
```

Key and value separated by a colon, and the rest is identical. **This is the single most useful
comprehension in data work**: it turns a list into an index, once, and every later lookup is a
step rather than a walk — which is lesson 3's argument and lesson 20's measurement.

Inverting one:

```python
by_name = {v: k for k, v in by_id.items()}
```

Which is safe only when the values are unique, because a repeat silently overwrites.

## Set

```python
seen = {p["city"] for p in people}
```

Braces with no colon, and duplicates collapse. The empty case is still `set()`.

## Generator expression

```python
total = sum(price for price in prices if price > 100)
```

Parentheses, and **nothing is built**. It produces one value at a time as `sum` asks for them,
which means no list of a million numbers exists in memory at any moment.

When the call already has brackets, the extra pair is not needed — `sum(x for x in xs)` rather
than `sum((x for x in xs))`.

Lesson 11 is where this becomes the whole subject. Two rules until then:

**Use a generator expression when it feeds straight into something that consumes it** — `sum`,
`max`, `any`, `all`, `"".join`.

**Use a list comprehension when you need the list** — to iterate twice, to index, to keep. A
generator is spent after one pass and the second pass silently gets nothing.

## `any` and `all`

```python
if any(p["city"] == "Porto" for p in people):
if all(score >= 50 for score in scores):
```

Both short-circuit: `any` stops at the first true, `all` at the first false. Together with a
generator expression they replace a loop with a flag, which is a pattern worth recognising the
moment you catch yourself writing `found = False`.
