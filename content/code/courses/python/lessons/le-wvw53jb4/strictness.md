---
title: The default that passes almost anything
version: 2
---

```python
def add(a, b):
    return a + b

add("x", 3)
```

```sh
Success: no issues found in 1 source file
```

**A first run that says nothing usually means nothing was checked.** An unannotated function is
not an error to `mypy` — it is a function it has no opinion about, and every call to it is a call
it cannot judge.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Four settings, each judging more of the file than the one before: the loosest checks arity, names and imports; then the bodies of unannotated functions; then every function must be annotated; then strict, which also stops a typed function resting on an unannotated one.\"> <text x=\"325\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">what it adds</text> <text x=\"575\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">what is still unjudged</text> <rect x=\"20\" y=\"32\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the default</text> <text x=\"210\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">arity, names, imports</text> <text x=\"460\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the body of every unannotated function</text> <rect x=\"20\" y=\"72\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_untyped_defs</text> <text x=\"210\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">those bodies too</text> <text x=\"460\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which functions have no annotation</text> <rect x=\"20\" y=\"112\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">disallow_untyped_defs</text> <text x=\"210\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every function must be annotated</text> <text x=\"460\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what the typed ones call</text> <rect x=\"20\" y=\"152\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"169\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">--strict</text> <text x=\"210\" y=\"169\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and may not call an unannotated one</text> <text x=\"460\" y=\"169\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing of this list</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">--strict is not a mode; it is a shorthand for a list of flags.</text> <text x=\"360\" y=\"221\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Four of them change your day, and disallow_untyped_defs is the loudest of the four.</text> </svg>", "caption": "A clean first run on a codebase with no annotations is not relief. It usually means nothing was checked."}
```

The honest reaction to a clean first run on a codebase with no annotations is not relief.

## What it checks anyway

```python
add(1, 2, 3)
```

```sh
error: Too many arguments for "add"  [call-arg]
```

Arity, names and imports are structural: a call with three arguments to a function that takes two
is wrong whatever the types are. So even at its loosest, the checker is not doing nothing.

## `--strict`, and what it turns on

```sh
mypy --strict app/
```

```sh
error: Function is missing a type annotation  [no-untyped-def]
error: Call to untyped function "add" in typed context  [no-untyped-call]
error: Returning Any from function declared to return "dict[Any, Any]"  [no-any-return]
error: Missing type parameters for generic type "dict"  [type-arg]
```

`--strict` is not a separate mode. It is a shorthand for a list of flags, and the four that
change your day are worth knowing by name:

- **`disallow_untyped_defs`** — every function must be annotated. This is the one that turns a
  silent codebase into a loud one.
- **`disallow_untyped_calls`** — a typed function may not call an unannotated one. This is what
  stops the checked half from quietly resting on the unchecked half.
- **`warn_return_any`** — a function declared to return `dict` may not just hand back whatever
  `json.load` gave it. `Any` is how a type is lost without anybody noticing.
- **`disallow_any_generics`** — write `dict[str, int]`, not a bare `dict`.

The rest are smaller: `warn_redundant_casts`, `warn_unused_ignores`, `strict_equality`,
`no_implicit_reexport`, and a few more.

## `check_untyped_defs`, which is the interesting one

```python
def total(items):
    n: int = "zero"
    return n
```

```sh
note: By default the bodies of untyped functions are not checked,
      consider using --check-untyped-defs  [annotation-unchecked]
```

`mypy` reads the *signature* of an unannotated function and skips its *body* entirely. Turning
this on checks inside those bodies without demanding the signatures first — **so it finds things
on day one and asks nobody to write an annotation**, which makes it the cheapest flag to switch
on across a whole codebase.
