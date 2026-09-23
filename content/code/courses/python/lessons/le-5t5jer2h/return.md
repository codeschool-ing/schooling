---
title: One value, several values, and the difference from printing
version: 2
---

```python
def parse(line):
    name, _, city = line.partition(",")
    return name, city          # a tuple, and the parentheses are optional
```

`return` ends the function immediately and hands a value back. Several values are one tuple, and
the caller unpacks it the way lesson 3 unpacked any other:

```python
name, city = parse(line)
```

**Beyond three, name them.** A function returning five things in a tuple is a function whose
caller has to remember an order, which is exactly what lesson 3 said about a list of fields.

## Early return

```python
def price_for(plan):
    if plan == "free":
        return 0
    if plan not in PRICES:
        raise ValueError(f"unknown plan: {plan}")
    return PRICES[plan]
```

Several `return` statements are ordinary Python, not a thing to feel guilty about. The guard
shape from lesson 4 is built on it: get the settled cases out at the top and leave the body at
one level.

## Returning against printing

```python
def total(rows):
    print(sum(r["amount"] for r in rows))     # can be read; cannot be used

def total(rows):
    return sum(r["amount"] for r in rows)     # can be used; the caller prints
```

**A function that prints its answer has given it to a person and not to the program.** Nothing
can add it up, test it, or write it to a file. Compute and return; print at the edge, where the
program talks to somebody.

This is the single most common shape in beginner code, and it is the reason the same function
cannot be reused from the next script.

## `return` with nothing

```python
    if not rows:
        return
```

Returns `None`, and reads as "there is nothing to do here". Fine on its own; **do not mix it
with returning a value in the same function** unless `None` genuinely means something to the
caller, because then every call site needs a check that nobody will write.
