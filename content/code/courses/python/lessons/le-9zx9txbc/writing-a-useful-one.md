---
title: Three worth writing
version: 2
---

## A timer

```python
@contextmanager
def timed(label):
    start = time.perf_counter()
    try:
        yield
    finally:
        log.info("%s took %.3fs", label, time.perf_counter() - start)
```

The `finally` means a call that raised is still timed, which is the one you most want to know
about.

## A working directory

```python
@contextmanager
def in_directory(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)
```

**The restore has to be in a `finally`** — the whole point is the process's directory is global,
and leaving it moved affects every later line in the program, not just this block.

## A temporary setting

```python
@contextmanager
def setting(obj, name, value):
    previous = getattr(obj, name)
    setattr(obj, name, value)
    try:
        yield
    finally:
        setattr(obj, name, previous)
```

Remember the old value, set the new one, put it back. This is the shape behind most of what a
test framework calls a "patch", and lesson 16 uses `unittest.mock.patch`, which is this with more
features.

## What the three have in common

They save something, change it, and restore it — and the restore is in a `finally`. **If you can
describe a piece of code as "and then put it back", it is a context manager.**

## And one that is not worth writing

```python
@contextmanager
def logged(name):
    log.info("start %s", name)
    yield
    log.info("end %s", name)
```

Nothing is being undone — the second line is not a teardown, it is another log call. That is a
decorator, or two lines, and a `with` block here only hides that the "end" line never runs on a
failure.
