---
title: Two keywords, and what needing one usually means
version: 1
---

```python
count = 0

def bump():
    global count
    count += 1
```

`global` says the name belongs to the module. Without it the assignment would make `count` local
and the module's value would never move.

```python
def counter():
    n = 0
    def step():
        nonlocal n        # the enclosing function's n, not the module's
        n += 1
        return n
    return step
```

`nonlocal` says the name belongs to the nearest ENCLOSING function. It cannot reach module level,
and if there is no such name the file does not compile — a `SyntaxError`, raised when the module
is read and before a single line of it runs. That is the good failure: a typo in the name is
caught without anybody calling anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three copies of the same three nested scopes. With no declaration the write lands in the innermost function and the module name never moves. With global it lands in the module. With nonlocal it lands in the function immediately around.\"> <text x=\"125\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">count += 1</text> <rect x=\"20\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"32\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">module</text> <rect x=\"34\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"46\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">outer()</text> <rect x=\"48\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"60\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inner()</text> <circle cx=\"140\" cy=\"128\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></circle> <text x=\"154\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">count</text> <text x=\"125\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a name of its own, and the module never moves</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">global count</text> <rect x=\"255\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"267\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">module</text> <rect x=\"269\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"281\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">outer()</text> <rect x=\"283\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"295\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inner()</text> <circle cx=\"375\" cy=\"52\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"389\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">count</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the module's name, wherever it is written</text> <text x=\"595\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">nonlocal count</text> <rect x=\"490\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"502\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">module</text> <rect x=\"504\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"516\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">outer()</text> <rect x=\"518\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\"></rect> <text x=\"530\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inner()</text> <circle cx=\"620\" cy=\"92\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"634\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">count</text> <text x=\"595\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the name in the function immediately around</text> </svg>", "caption": "The declaration does not change what is read. It changes which box the write lands in."}
```

## Why they are rare

A function that changes a module-level name has an effect its signature does not mention. Two
things follow, and both are ordinary rather than theoretical:

- **its result depends on what ran before it**, so a test has to set the world up and put it back
- **two of them are hard to read together**, because the connection between them is a name in a
  third place

The usual alternative is to take the value and hand it back:

```python
def bump(count):
    return count + 1
```

Now the caller decides what happens to the result, and nothing about the function depends on
history.

## Where `global` is fine

A module-level constant, written once at import and never assigned again, needs no keyword at all
— reading is free. A genuine single-process cache or a registry filled at start-up is the case
where `global` earns its line, and **it deserves a comment saying why**, because the next reader
will assume it was an accident.

`nonlocal` has one home worth knowing: a closure that keeps state between calls, which is the
shape lesson 12 builds decorators from.
