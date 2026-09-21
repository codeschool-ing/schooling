---
title: `try`/`finally`, with a name
version: 1
---

```python
with open(path, encoding="utf-8") as f:
    process(f)
```

Three things happen, in order: the SETUP (the file is opened), the BODY, and the TEARDOWN (the
file is closed). The third happens however the second ends.

## The same thing, written out

```python
f = open(path, encoding="utf-8")
try:
    process(f)
finally:
    f.close()
```

That is what `with` does, and lesson 8 wrote it. What the `with` adds is that the teardown lives
beside the setup, in the thing being used, rather than at the bottom of whoever remembered.

## "However the body ends"

- it reaches the end
- it `return`s
- it `break`s or `continue`s out of a loop
- it raises

**In all five the teardown runs.** The exception then carries on upwards, unchanged — the manager
tidied up and did not interfere.

## What that buys, in one sentence

The person USING it cannot forget. `open` without `with` is a `close` somebody has to remember
on every path out of every function, forever; `with` is one line and the problem does not exist.

## Where you have already seen it

```python
with open(path) as f: ...            # lesson 9
with lock: ...                       # a threading lock
with conn: ...                       # a database transaction
with tempfile.TemporaryDirectory() as d: ...
```

Each is the same shape with a different undoing: close, release, commit or roll back, delete.

## And the sentence to carry

**If something has to be undone, the undoing belongs in the thing that did it** — not in a
comment, not in the caller, and not in a `finally` somebody will forget.
