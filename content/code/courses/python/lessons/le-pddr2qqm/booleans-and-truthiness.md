---
title: What counts as false, and the `and` that returns a string
version: 2
---

`True` and `False` are the two booleans, and they are **integers underneath**: `True + True` is
`2`, and `sum([True, False, True])` is `2`, which is a genuinely useful way to count how many
things in a list satisfy something.

## Truthiness

Every value can be used where a condition is expected. These are the falsy ones, and the list is
short enough to learn:

| | |
|---|---|
| `False` | |
| `None` | |
| `0`, `0.0` | any zero |
| `""` | the empty string |
| `[]`, `()`, `{}`, `set()` | any empty container |

**Everything else is truthy** — including `"False"`, `"0"` and `[0]`, each of which is a non-empty
thing.

So this is the idiom:

```python
if items:
    ...
```

rather than `if len(items) > 0`. It reads better and it is the convention.

**And it is a trap exactly once**, when zero is a real value:

```python
if count:          # skips the case where count is 0
if count is not None:   # what you meant
```

## `and` and `or` do not return booleans

```python
>>> "ada" or "nobody"
'ada'
>>> "" or "nobody"
'nobody'
>>> "ada" and "lovelace"
'lovelace'
```

`or` returns the first truthy operand, or the last one. `and` returns the first falsy operand, or
the last one. They **short-circuit**: the right-hand side is not evaluated if the left already
decided.

That is what makes this safe:

```python
if user is not None and user.name == "Ada":
```

The `user.name` is never reached when `user` is `None`.

And it is where the old default idiom comes from:

```python
name = supplied or "anonymous"
```

Which is neat, and quietly wrong when `""` or `0` is a value you wanted to keep. `if supplied is
None` says what you meant.

## `not`

`not` returns a real boolean, always: `not ""` is `True`, `not [1]` is `False`.
