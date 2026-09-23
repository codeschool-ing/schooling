---
title: `X | None`, and the union that is a smell
version: 2
---

```python
def find(code: str) -> Rate | None:
    ...
```

**The most useful annotation in the lesson.** It says the function sometimes finds nothing, and
a checker then points at every caller that used the result without asking.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"A return type of Rate or None says the function has two possible answers. Asking whether it is None splits the two apart, and inside each arm the checker knows which one it is holding. A caller that never asks is what the checker points at.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"150\" y=\"26\" width=\"420\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">def find(code: str) -&gt; Rate | None</text> <text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">two possible answers, and only one has a rate in it</text> <path d=\"M360 90 L360 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"210\" y=\"110\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">if rate is None:</text> <path d=\"M300 146 L300 166 L180 166 L180 182\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M420 146 L420 166 L540 166 L540 182\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"186\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">None — handled here, and nowhere else</text> <rect x=\"380\" y=\"186\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rate — and from here on the checker knows it</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Optional[Rate] is the same thing in the older spelling, and its name is the trap:</text> <text x=\"360\" y=\"257\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">it never meant this argument may be left out.</text> </svg>", "caption": "The annotation does not stop the function returning nothing. It stops a caller from forgetting that it might."}
```

## The older spelling

```python
Optional[Rate]        # from typing — the same thing
Union[int, str]       # from typing — now int | str
```

`Optional[X]` means `X | None` and never meant "this argument may be omitted", which is what its
name suggests and what everybody assumes once. The `|` form is the one to write now.

## Narrowing

```python
rate = find(code)
if rate is None:
    return 0.0
return total * rate          # here the checker knows it is a Rate
```

A checker follows the `if` and knows that `rate` cannot be `None` below it. That is what makes
the annotation useful rather than annoying: you check once, and the rest of the function is
clean.

`if rate is not None:` and an early `return` do the same, which is lesson 4's guard clause paying
for itself again.

## A default of `None`

```python
def connect(timeout: int | None = None) -> None:
    if timeout is None:
        timeout = 30
```

The annotation is `int | None` and the default is `None`. Writing `timeout: int = None` is a
common slip, and a checker refuses it.

## When a union is a design smell

```python
def load(source: str | Path | bytes | IO) -> list[dict]: ...
```

Four things, and the body has to branch on which it got. **Two is often fine; four is usually a
function that should have been two functions**, or one that takes something narrow and a caller
that converts.

The honest exception is a boundary — a parser, an adapter, the thing that meets the outside
world. That is the one place where accepting several shapes is the job.
