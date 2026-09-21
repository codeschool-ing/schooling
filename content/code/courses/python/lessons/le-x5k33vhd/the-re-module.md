---
title: Five functions, and what each hands back
version: 1
---

| function | finds | gives back |
| --- | --- | --- |
| `search` | the first match, anywhere | a `Match`, or `None` |
| `match` | a match at the START | a `Match`, or `None` |
| `fullmatch` | a match covering the WHOLE string | a `Match`, or `None` |
| `findall` | every match | a list of strings or tuples |
| `finditer` | every match | an iterator of `Match` objects |

## The `None` that is not checked

```python
m = re.search(pattern, line)
value = m.group(1)          # AttributeError when it did not match
```

Three of the five return `None`, and `None.group` is lesson 8's `'NoneType' object has no
attribute` in its most common disguise. **Check it every time**, and while you are there, count
the lines that did not match — a parser that silently drops a tenth of its input is worse than
one that stops.

## `findall` changes shape

```python
re.findall(r"\d+", text)                 # ['2026', '09']
re.findall(r"(\d+)-(\d+)", text)         # [('2026', '09')]
```

**No group: a list of whole matches. One group: a list of that group. Two or more: a list of
tuples.** That is three different return types from one function, decided by the pattern — which
is why `finditer` is the one to reach for when the pattern is not trivial.

## `finditer`, which keeps the `Match`

```python
for m in re.finditer(r"(?P<key>\w+)=(?P<value>\S+)", text):
    print(m["key"], m["value"], m.start())
```

Named groups, positions, and nothing built in memory. It is also the only one of the five that
scales to a large file.

## `split` and the capturing group

```python
re.split(r"\s*,\s*", "a , b,c")          # ['a', 'b', 'c']
re.split(r"(\d)", "a1b")                 # ['a', '1', 'b'] — the group is KEPT
```

A capturing group in the pattern puts the separators into the result, which is occasionally
exactly what you want and is otherwise a surprise.

## The module-level functions cache

`re.search(pattern, s)` compiles the pattern and caches it, so calling it in a loop is not the
disaster it looks like. `re.compile` is still clearer for a pattern used more than once, and it
is the next section.
