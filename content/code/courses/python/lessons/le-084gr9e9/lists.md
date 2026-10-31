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

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "langs[1] = \"rust\"",
      "note": "Assigning to a position replaces the item there, in place."
    },
    {
      "code": "langs.append(\"c\")",
      "note": "`append` puts one item on the end."
    },
    {
      "code": "langs.extend([\"zig\", \"r\"])",
      "note": "`extend` puts several on the end."
    },
    {
      "code": "langs.insert(0, \"bash\")",
      "note": "`insert` puts one at a position, and everything after it shifts along."
    }
  ]
}
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

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "langs.sort()",
      "note": "`sort` works in place and returns `None`."
    },
    {
      "code": "best = sorted(langs)",
      "note": "`sorted` makes a new list and leaves the original alone."
    },
    {
      "code": "langs.sort(reverse=True)"
    },
    {
      "code": "langs.sort(key=len)",
      "note": "`key` sorts by a computed value."
    }
  ]
}
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
