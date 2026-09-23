---
title: Two methods, and the return value that swallows
version: 2
---

```python
class Timer:
    def __enter__(self):
        self.start = time.perf_counter()
        return self                      # this is what `as` binds

    def __exit__(self, exc_type, exc, tb):
        self.elapsed = time.perf_counter() - self.start
```

```python
with Timer() as t:
    work()
print(t.elapsed)
```

## `__enter__`

Runs before the body. **Whatever it returns is what `as` binds** — and that is often `self`, and
sometimes something else entirely: `open` returns a file object, and a lock returns `True`.

If there is no `as`, the return value is thrown away, which is fine for a manager whose whole job
is the teardown.

## `__exit__` and its three arguments

```python
def __exit__(self, exc_type, exc, tb):
```

On the way out with no exception, all three are `None`. With one, they are the class, the
instance and the traceback — the same three `sys.exc_info()` gives.

**That is how a manager can behave differently on failure**: a transaction commits when
`exc_type is None` and rolls back otherwise.

## The return value

```python
    def __exit__(self, exc_type, exc, tb):
        return True          # the exception is GONE
```

A truthy return means "I handled it". The exception stops there: not logged, not re-raised, and
the code after the `with` runs as though the body had finished.

**Return nothing unless suppressing is the entire point of the manager.** A `return` you did not
mean — the end of an `if` that happens to give `True` — silently eats every failure inside every
block that uses it.

`contextlib.suppress(FileNotFoundError)` is the written version for when you do want that, and
it names which exception, which a bare `True` does not.

## Neither method may be skipped

A class with `__enter__` and no `__exit__` raises `TypeError` at the `with`, naming the missing
method. That is the good failure: it happens at the first use rather than at the first exception.
