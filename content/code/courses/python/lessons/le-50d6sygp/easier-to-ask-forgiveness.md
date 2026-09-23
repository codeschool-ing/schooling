---
title: Try it, rather than checking first
version: 2
---

Two ways to write the same thing:

```python
# look before you leap
if os.path.exists(path):
    text = open(path).read()

# easier to ask forgiveness than permission
try:
    text = open(path).read()
except FileNotFoundError:
    text = ""
```

The second is the Pythonic one, and the reason is not taste.

## The check has a race in it

Between `exists(path)` and `open(path)` the file can be deleted, renamed or replaced. The check
answered truthfully about a moment that has passed, and the `open` fails anyway — so you needed
the `except` regardless, and the check bought nothing but a second question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Checking first asks a question, and between the answer and the use anything outside the program can change: the file is deleted and the open fails anyway. Trying instead tests the state at the instant it is used, which is the only instant that matters.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">look before you leap</text> <rect x=\"20\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exists(path) is True</text> <rect x=\"250\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">something else deletes it</text> <rect x=\"480\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"590\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open(path) raises anyway</text> <path d=\"M240 80 L240 88 L480 88 L480 80\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">this gap is not yours to close</text> <text x=\"20\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">easier to ask forgiveness</text> <rect x=\"20\" y=\"152\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open(path)</text> <text x=\"256\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">it works, or it raises — either way you know now</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">So the except was needed either way, and the check bought a second question.</text> <text x=\"360\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">It also costs a lookup on every call, where the exception costs only when it happens.</text> </svg>", "caption": "The check answered truthfully about a moment that had already passed. The try is the only thing that asks at the instant of use."}
```

**Anything outside your program — a file, a network, another process — can change between the
check and the use.** The try is the only thing that tests the state at the instant you use it.

## It is also usually faster

The check costs a lookup on every call, and the exception costs only when it happens. For the
common case where it usually works, the try wins — and where it usually fails, the difference
rarely matters.

## Where a check IS better

```python
if not rows:            # asking about your own data
    return 0
```

When the thing you are asking about is yours, in memory, and cannot change under you, an `if` is
clearer. Nobody writes `try: rows[0] except IndexError` to find out whether a list is empty.

The line is: **ask about your own values; try the ones that belong to the world.**

## The one to watch

```python
try:
    value = config["port"]
except KeyError:
    value = 5432
```

Correct, and `config.get("port", 5432)` says it in one line. When the standard library already
has the forgiving version — `.get`, `.pop` with a default, `next(it, None)` — that is the one to
use. Handling the exception is for when there is no such method.
