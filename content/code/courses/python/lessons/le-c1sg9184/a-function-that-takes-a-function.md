---
title: The inner function, and what it remembers
version: 2
---

```python
def shout(text):
    return text.upper()

def twice(func):
    def wrapper(text):
        return func(func(text))
    return wrapper

loud = twice(shout)
loud("ada")        # 'ADA'
```

`twice` takes a function and returns a NEW function. Nothing about that is special syntax — it
is lesson 5's "a function is a value", applied twice in one place.

## The closure

`wrapper` uses `func`, which is not its own parameter and not a global. It is the parameter of
the function `wrapper` was defined inside, and it is still there after `twice` has returned.

**That is a closure**, and it is the machinery the whole lesson rests on: the inner function
remembers the variables that were around it when it was made.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A decorator returns a new function that holds the original one inside it. A call goes into the wrapper, through whatever it does first, into the original, back out through whatever it does after, and the caller gets that answer.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"150\" y=\"44\" width=\"420\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"164\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the wrapper that timed() returned</text> <rect x=\"176\" y=\"76\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"251\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what it does first</text> <rect x=\"394\" y=\"76\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"469\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what it does after</text> <rect x=\"250\" y=\"118\" width=\"220\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">load_rows, the original</text> <path d=\"M330 91 L352 91 L352 113\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M474 134 L494 134 L494 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"91\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a call arrives here</text> <path d=\"M138 91 L146 91\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"702\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the answer, back out</text> <path d=\"M574 91 L586 91\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The wrapper reaches the original through a name that was never its own parameter</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and is not a global — it is a closure, and it is the whole machinery of this lesson.</text> </svg>", "caption": "The wrapper is an ordinary function with the original held inside it. Nothing here is syntax — it is a function that was still around when the inner one was made."}
```

```python
a = twice(shout)
b = twice(strip)
```

Two wrappers, each remembering a different `func`. They do not interfere, because each call to
`twice` made a new inner function with its own surroundings.

## Why the inner function exists at all

Because a decorator has to give back something CALLABLE that has not been called yet. It cannot
return `func(x)` — it does not have an `x`. It returns a function that will call `func` when
somebody eventually calls IT.

## The shape, before any syntax

```python
def decorator(func):
    def wrapper(...):
        # before
        result = func(...)
        # after
        return result
    return wrapper
```

Every decorator in this lesson is that shape with the details filled in. The `@` is a shorthand
for the line that uses it, and it is the next section.
