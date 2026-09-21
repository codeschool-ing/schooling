---
title: `*args, **kwargs`, and the `return` everybody forgets
version: 1
---

```python
def timed(func):
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.perf_counter() - start:.3f}s")
        return result
    return wrapper
```

Two mechanical facts, and the two mistakes that come from missing either.

## The wrapper is what gets called

```python
def wrapper():              # no
    ...

@timed
def load(path): ...

load("data.csv")            # TypeError: timed.<locals>.wrapper() takes 0
                            #            positional arguments but 1 was given
```

After decoration, `load` IS the wrapper. Whatever the caller passes arrives there, so the wrapper
must accept anything — `*args, **kwargs` — and hand it straight on, with the stars again at the
call.

**The error names `timed.<locals>.wrapper`**, and the qualified name is the first clue that
decoration is involved at all — `timed` is the decorator, and `wrapper` is the function it built.

## The wrapper is what returns

```python
def wrapper(*args, **kwargs):
    func(*args, **kwargs)       # no return
```

Now every decorated function answers `None`. Nothing raises, the work still happens, and the bug
looks like the decorated function being broken — in nine functions at once, if you decorated
nine.

**`result = func(...)` and `return result`**, or `return func(...)` when there is nothing to do
afterwards.

## Keeping something from before and after

```python
        start = time.perf_counter()
        try:
            return func(*args, **kwargs)
        finally:
            print(f"{func.__name__} took {time.perf_counter() - start:.3f}s")
```

The `try`/`finally` from lesson 8 is how the "after" part still happens when the wrapped function
raises. A timing decorator that only logs on success is one that tells you nothing about the call
that hung.

## Passing the exception through

Do not catch it unless the decorator's job is to catch it. A wrapper that swallows an exception
has hidden a failure in a place nobody will look, and it has done it everywhere it is applied.
