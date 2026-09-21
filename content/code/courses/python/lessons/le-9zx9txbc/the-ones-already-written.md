---
title: Six you will use before you write one
version: 1
---

## `open`

The one from lesson 9, and the reason most people meet the syntax at all.

## A lock

```python
with lock:
    shared += 1
```

`threading.Lock` acquires on the way in and releases on the way out — including when the body
raises, which is the case where a forgotten release deadlocks the whole program with no error
message anywhere.

## A database connection

```python
with conn:
    conn.execute(...)
```

In `sqlite3`, the `with` is the TRANSACTION: it commits at the end and rolls back on an
exception. **It does not close the connection**, which surprises everybody once — the manager
does the transaction and `conn.close()` is still yours.

That is worth knowing as a general point: a library's manager does what its documentation says,
and "it is a `with`" does not tell you which undoing it performs.

## `tempfile`

```python
with tempfile.TemporaryDirectory() as d:
    write_things(Path(d))
# the directory and everything in it is gone here
```

The version that cleans up when the test fails, which is the version that matters.

## `contextlib.suppress`

```python
with suppress(FileNotFoundError):
    path.unlink()
```

`try`/`except`/`pass`, with the class named where a reader sees it. Two lines to one, and the
name is the point — a bare `except: pass` says nothing about what was expected.

## `redirect_stdout`

```python
buffer = io.StringIO()
with redirect_stdout(buffer):
    noisy_library_call()
```

For the library that prints and has no option not to. Lesson 15 uses it to test something that
was written to print.

## And the shape they share

Every one of them is setup, body, teardown — with the teardown guaranteed. **When you meet a
`with` in somebody's code, the question to ask is what it undoes**, and the answer is always in
`__exit__`.
