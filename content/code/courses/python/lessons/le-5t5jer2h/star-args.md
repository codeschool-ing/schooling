---
title: `*args`, `**kwargs`, and unpacking in both directions
version: 1
---

```python
def total(*prices):
    return sum(prices)

total(10, 20, 30)       # prices is the tuple (10, 20, 30)
```

`*args` collects the positional arguments nobody named into a tuple. `**kwargs` collects the
keyword arguments nobody declared into a dictionary:

```python
def log(message, **fields):
    print(message, fields)

log("saved", rows=12, source="csv")     # fields is {'rows': 12, 'source': 'csv'}
```

The names are convention, not syntax — `*a` works. **Use the conventional names**, because a
reader recognises them at a glance.

## The same stars at the call site

```python
args = [10, 20, 30]
total(*args)                    # three arguments, not one list

options = {"port": 6543, "timeout": 30}
connect("db.example.tld", **options)
```

One star unpacks a sequence into positional arguments; two stars unpack a dictionary into keyword
arguments. **The star means "spread this out" in both places**, which is the one idea worth
carrying — a function collects with it, a call scatters with it.

## The bare `*`

```python
def charge(account, cents, *, refundable=False, dry_run=False):
    ...

charge(account, 1200, refundable=True)      # fine
charge(account, 1200, True)                 # TypeError
```

Everything after the bare `*` can only be given by name. It is how you make the unreadable call
site impossible rather than merely discouraged, and it is worth reaching for on any function with
two or more booleans.

## When to use them at all

Rarely, and for two shapes:

- a genuine variable number of the same thing — `sum`, `max`, a `join`
- a wrapper that passes its arguments straight through to something else, which is lesson 12's
  decorator

**`def f(*args, **kwargs)` on a function that then reads `args[0]`** is a signature that has
stopped saying what the function takes. The parameters were the documentation, and they have
been replaced with a shrug.
