---
title: Three things a `with` block does not do
version: 2
---

## It is not a scope

```python
with open(path) as f:
    rows = f.readlines()
print(rows)          # fine — and so is `f`
print(f.closed)      # True: the object is here, and it is closed
```

Python has no block scope, as lesson 5 said. A name bound inside a `with` is still bound after
it, including the one `as` created — **and using it after the block is the mistake**: the file
object exists and is closed, so reading from it raises `ValueError: I/O operation on closed
file`.

## It is not a transaction by itself

A `with` guarantees that `__exit__` runs. Whether that commits, rolls back, deletes or does
nothing is entirely up to the manager.

`with conn:` in `sqlite3` is a transaction and does NOT close the connection. `with open(...)`
closes and has no transaction at all. **"It is a `with`" tells you there is an undoing and not
which one** — the documentation, or `__exit__`, is where that is written.

## It does not handle the exception

```python
with timed("load"):
    load()          # raises
# nothing here runs; the exception is still on its way up
```

The manager is told about the exception so it can tidy up, and then the exception continues.
Unless `__exit__` returns something truthy — and then it is gone, which is the sharp edge from
the protocol section and almost never what you want.

**A `with` is not a `try`/`except`.** If you need to handle the failure, the `try` is still
yours to write, and it goes around the `with`.

## And a fourth, briefly

It does not make the body atomic, or thread-safe, or retryable. It runs two things around your
code. Everything else is whatever the manager was written to do.
