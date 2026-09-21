---
title: The third layer, and why everybody looks it up
version: 1
---

```python
@retry(times=3)
def fetch(url):
    ...
```

Write the `@` as a call, as the earlier section said:

```python
fetch = retry(times=3)(fetch)
```

**Two calls.** `retry(times=3)` runs first and must return a DECORATOR; that decorator is then
called with `fetch`. So there are three layers rather than two.

```python
def retry(times):                       # 1. takes the argument
    def decorator(func):                # 2. takes the function
        @functools.wraps(func)
        def wrapper(*args, **kwargs):   # 3. takes the call
            for attempt in range(times):
                try:
                    return func(*args, **kwargs)
                except OSError:
                    if attempt == times - 1:
                        raise
        return wrapper
    return decorator
```

Read it from the inside out: `wrapper` does the work, `decorator` makes a wrapper for one
function, `retry` makes a decorator for one setting.

## Why it cannot be two layers

Because `@` applies whatever is after it to the function below. If `retry` took the function, it
would have nowhere to put `times`. The call has to happen before the `@` does anything.

## The one that catches people

```python
@retry            # no parentheses
def fetch(url): ...
```

Now `times` is the FUNCTION, and `decorator` is what `fetch` becomes — so calling `fetch(url)`
calls `decorator(url)` and returns a wrapper instead of a result. Nothing raises until much
later, and the message is about something unrelated.

**A decorator that takes arguments must always be written with parentheses**, even empty ones,
unless it was deliberately built to handle both.

## And the honest note

This is the part of the lesson that people look up every time, including people who write these
often. Writing the `@` out as a call is what makes it readable, and there is no shame in doing
that on paper before typing it.
