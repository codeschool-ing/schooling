---
title: Four places, in a fixed order
version: 1
---

A name is resolved by looking in four places, always in this order:

**L**ocal → **E**nclosing → **G**lobal → **B**uilt-in.

```python
total = 0                 # global (module level)

def outer():
    count = 1             # enclosing, from inner's point of view
    def inner():
        n = 2             # local
        print(n, count, total, len)     # one from each
    inner()
```

The first place that has the name wins, and Python never asks which one you meant.

## Assignment is what makes a name local

```python
total = 0

def bump():
    total = total + 1     # UnboundLocalError
```

The error is on the read, and the read looks correct. **Python decides that `total` is local by
scanning the function body for an assignment — before running a line of it.** There is one, so
`total` is local everywhere in that body, including on the right of the line that assigns it. The
module's `total` is not consulted.

Reading a global without assigning to it works fine, which is what makes this confusing: the
function was correct until a line was added at the bottom.

## Shadowing a built-in

```python
list = [1, 2, 3]      # now `list(...)` is broken in this scope
```

No error, and nothing says anything. `list`, `dict`, `id`, `type`, `sum`, `input` and `str` are
the ones people take by accident. Add an underscore — `list_` — or pick a better name, which is
usually what the collision was telling you.

## The loop variable is not a scope

```python
for row in rows:
    ...
print(row)        # still here
```

Lesson 4's last mistake, seen from here: a `for`, an `if` and a `while` do not make a scope in
Python. Only a function does — and a module, and a class.
