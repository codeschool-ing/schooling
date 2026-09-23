---
title: `yield`, and the function that pauses
version: 2
---

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1

for i in countdown(3):
    print(i)          # 3, 2, 1
```

A function with a `yield` anywhere in it is a GENERATOR FUNCTION. Calling it runs none of the
body: it hands back a generator object. Each `next` runs the body until the next `yield`, hands
back that value, and **pauses there** — with `n` and every other local still alive.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Calling a generator function runs none of its body. Each next runs it as far as the next yield, hands that value back and stops there with every local still alive. When the loop ends the generator raises StopIteration instead of returning a value.\"> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">def countdown(n): while n &gt; 0: yield n; n -= 1</text> <rect x=\"20\" y=\"40\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">countdown(3)</text> <text x=\"186\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nothing in the body has run yet</text> <text x=\"700\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">a generator object</text> <rect x=\"20\" y=\"78\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">runs to the yield, and stops there</text> <text x=\"700\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3</text> <rect x=\"20\" y=\"116\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"131\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resumes AFTER the yield, with n still 3</text> <text x=\"700\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">2</text> <rect x=\"20\" y=\"154\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"169\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resumes again, and n is still alive</text> <text x=\"700\" y=\"169\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">1</text> <rect x=\"20\" y=\"192\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the while ends, so the body falls off</text> <text x=\"700\" y=\"207\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">StopIteration</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Everything the body knows survives the pause: n, and every other local.</text> <text x=\"360\" y=\"253\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">That is the whole difference from a function that returns a list.</text> </svg>", "caption": "A generator is a function that can be stopped in the middle and started again from there, which is why it can produce a value at a time for ever."}
```

## What it replaces

```python
class Countdown:                     # the same thing, by hand
    def __init__(self, n): self.n = n
    def __iter__(self): return self
    def __next__(self):
        if self.n <= 0: raise StopIteration
        self.n -= 1
        return self.n + 1
```

Eight lines against three, and the eight have a place to put a bug. **Anything you would write as
a class holding a position is a generator instead**, and the last section of this lesson writes
one both ways on purpose.

## `return` inside a generator

```python
def take_until_blank(lines):
    for line in lines:
        if not line.strip():
            return            # ends it — no value comes back
        yield line
```

A bare `return` stops the generator, which raises `StopIteration` for the caller. A `return
value` sets the exception's `value` attribute, which almost nothing reads — so treat `return` as
"stop" and yield everything you mean to hand over.

## Yielding from another generator

```python
def both(a, b):
    yield from a
    yield from b
```

`yield from` hands over to another iterable until it is exhausted. It is the same as a `for` loop
with a `yield` in it, and it is shorter and faster.

## The one to watch

```python
def loaded():
    rows = expensive()        # this does NOT run at call time
    for r in rows:
        yield r
```

Nothing in the body happens until the first `next`. That is the whole point, and it is a surprise
when the expensive line was there to fail early — a generator that is never iterated never runs,
and never raises.
