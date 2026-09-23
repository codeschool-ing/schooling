---
title: Ordered, and it can change
version: 2
---

```python
langs = ["python", "go", "sql"]
```

Square brackets, comma-separated, and anything may go inside — including other lists.

## Reaching in

```python
>>> langs[0]
'python'
>>> langs[-1]
'sql'
>>> len(langs)
3
```

From zero. **`langs[3]` raises `IndexError`**, and that is the message to expect from an
off-by-one.

## Changing it

```python
langs[1] = "rust"          # replace in place
langs.append("c")          # one item on the end
langs.extend(["zig", "r"]) # several on the end
langs.insert(0, "bash")    # at a position; everything after shifts
```

**`append` takes one item, `extend` takes an iterable.** `langs.append(["a", "b"])` puts a *list*
inside the list, which is legal and almost never what you meant.

## Taking things out

```python
>>> langs.pop()        # last, and returns it
'r'
>>> langs.pop(0)       # by position
'bash'
>>> langs.remove("go") # by value, first match, raises if absent
```

`del langs[2]` also works and returns nothing.

## Sorting

```python
langs.sort()             # in place, returns None
best = sorted(langs)     # a new list, leaves the original alone
langs.sort(reverse=True)
langs.sort(key=len)      # by a computed value
```

**`sort` returns `None`**, which is lesson 2's `names = names.sort()` trap. When you want a value
back, `sorted`.

## Asking

```python
>>> "go" in langs
True
>>> langs.index("sql")
2
>>> langs.count("go")
1
```

**`in` on a list walks it**, comparing one by one. That is fine for twenty items and it is the
thing to think about when it is inside a loop over a hundred thousand — the `choosing` section
has the table and lesson 20 has the measurement.
