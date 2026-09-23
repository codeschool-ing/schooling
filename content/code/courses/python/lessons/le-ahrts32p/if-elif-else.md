---
title: The indentation is the block
version: 2
---

```python
if score >= 70:
    print("pass")
elif score >= 50:
    print("borderline")
else:
    print("fail")
```

A colon ends each header line, and the indented lines under it are the block. There is no `end`,
no braces, and moving a line four spaces changes which branch it belongs to.

## `elif` rather than a nested `if`

```python
if score >= 70:
    ...
else:
    if score >= 50:      # works, and drifts right forever
        ...
```

`elif` is one keyword for exactly this, and it keeps a chain of five conditions flat.

**The branches are tried in order and the first match wins.** So order them from most specific to
least: a chain starting `if score >= 50` would never reach the 70 case.

## The conditional expression

```python
label = "pass" if score >= 70 else "fail"
```

One value or the other, in an expression. It reads middle-outwards, which takes a moment the
first time. Use it when both sides are short; use an `if` statement when either side is not.

**There is no ternary `?:`** in Python, and this is what replaced it.

## `match`, in one paragraph

Python 3.10 added `match`/`case`, which is worth recognising:

```python
match command:
    case "start":
        ...
    case _:
        ...
```

It is far more than a `switch` — it destructures shapes — and a chain of `elif` is still the
ordinary answer for comparing one value against a few. This course does not use it again.

## Nesting, and the guard clause

```python
def send(user):
    if user is None:
        return
    if not user.verified:
        return
    ...
```

Two early returns rather than two levels of `if`. **The deeper a block is, the harder it is to
know what is true inside it**, and getting the impossible cases out of the way at the top keeps
the body at one level. Lesson 5 has `return`; this shape is worth meeting now, because it is how
most real functions are written.
