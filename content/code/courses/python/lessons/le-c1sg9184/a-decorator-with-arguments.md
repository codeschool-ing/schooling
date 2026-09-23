---
title: The third layer, and why everybody looks it up
version: 2
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

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def retry(times):",
      "note": "**The first layer takes the argument.** `retry(times=3)` runs when the `@` line is read, before there is any function, and all it does is keep `times`."
    },
    {
      "code": "    def decorator(func):\n        @functools.wraps(func)",
      "note": "**The second takes the function.** This is the decorator proper, what `@` applies to `fetch`, and `functools.wraps` keeps `fetch`'s name and docstring on what it hands back."
    },
    {
      "code": "        def wrapper(*args, **kwargs):\n            for attempt in range(times):\n                try:\n                    return func(*args, **kwargs)\n                except OSError:\n                    if attempt == times - 1:\n                        raise",
      "note": "**The third takes the call**, and runs every time `fetch(url)` does: up to `times` attempts, returning the first that succeeds and raising the last `OSError` if none does."
    },
    {
      "code": "        return wrapper",
      "note": "The decorator hands back the wrapper, and that is what the name `fetch` points at from then on."
    },
    {
      "code": "    return decorator",
      "note": "And `retry` hands back the decorator. One `return` for each outer layer: leave either out and `None` ends up where a function should be."
    }
  ]
}
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
