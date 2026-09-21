---
title: `@contextmanager`, and the `try` that is not optional
version: 1
---

```python
from contextlib import contextmanager

@contextmanager
def timer():
    start = time.perf_counter()
    try:
        yield                       # the body runs here
    finally:
        print(f"{time.perf_counter() - start:.3f}s")
```

One `yield`. Everything before it is `__enter__`, everything after it is `__exit__`, and whatever
it yields is what `as` binds.

## The `try`/`finally` is the whole lesson of this section

```python
@contextmanager
def timer():
    start = time.perf_counter()
    yield
    print(...)              # NOT run when the body raises
```

Without the `try`, an exception in the body propagates out of the `yield` and the lines after it
never run. **The manager then cleans up only in the case that did not need cleaning up**, which
is worse than no manager at all, because the code looks like it handles it.

## Yielding a value

```python
@contextmanager
def working_directory(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield path              # `as` binds this
    finally:
        os.chdir(previous)
```

## Exactly one `yield`

Two of them is a `RuntimeError` — "generator didn't stop" — at the end of the block, which is a
confusing place to hear about it. Zero of them is "generator didn't yield", at the `with`.

## Catching in the manager

```python
    try:
        yield
    except ValueError:
        log.warning("ignored")      # this SWALLOWS it, like returning True
    finally:
        cleanup()
```

An `except` around the `yield` is the generator equivalent of a truthy `__exit__` — and a bare
`raise` at the end of it is how you look and still let it through.

## Class or generator?

The generator is shorter and reads in order. The class is better when the manager has state a
caller asks about afterwards, when it is reusable across several `with` blocks, or when the
setup and teardown are long enough to want names.

**Start with `@contextmanager`.** Move to a class when you find yourself wanting a method.
