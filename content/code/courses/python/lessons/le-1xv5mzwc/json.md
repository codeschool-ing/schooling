---
title: Four functions, and the types on each side
version: 1
---

```python
import json

data = json.loads(text)          # string  → Python
data = json.load(f)              # file    → Python
text = json.dumps(data)          # Python  → string
json.dump(data, f)               # Python  → file
```

**The `s` means string.** That is the whole of the naming, and it is the thing people look up
every time until they notice it.

## The types

| JSON | Python |
| --- | --- |
| object | `dict` |
| array | `list` |
| string | `str` |
| number | `int` or `float` |
| `true` / `false` | `True` / `False` |
| `null` | `None` |

There is no tuple, no set, no date. A tuple written out comes back a list, a `datetime` raises
`TypeError: Object of type datetime is not JSON serializable` — and the usual answer is
`.isoformat()` on the way out and `fromisoformat` on the way back, which lesson 7 has.

## Writing it for a person

```python
json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)
```

`indent=2` makes it readable and makes a diff useful. `ensure_ascii=False` keeps `ção` as `ção`
rather than `ção`. `sort_keys=True` makes two dumps of the same data identical, which
is what stops a file from appearing changed when it is not.

## Reading it

```python
with open(path, encoding="utf-8") as f:
    data = json.load(f)
```

`json.load` takes the FILE, not the text — passing `f.read()` to it works and reads the file
twice as much as it needed to.

## What it will not do

**Trailing commas, comments and single quotes are not JSON.** Every one of them raises
`json.JSONDecodeError`, which names the line and column — and that error is a subclass of
`ValueError`, so `except ValueError` catches it.

A file with comments in it is probably JSON5, YAML or TOML. `tomllib` is in the standard library
since 3.11 and is the right answer for configuration.
