---
title: The default that passes almost anything
version: 1
---

```python
def add(a, b):
    return a + b

add("x", 3)
```

```text
Success: no issues found in 1 source file
```

**A first run that says nothing usually means nothing was checked.** An unannotated function is
not an error to `mypy` — it is a function it has no opinion about, and every call to it is a call
it cannot judge.

The honest reaction to a clean first run on a codebase with no annotations is not relief.

## What it checks anyway

```python
add(1, 2, 3)
```

```text
error: Too many arguments for "add"  [call-arg]
```

Arity, names and imports are structural: a call with three arguments to a function that takes two
is wrong whatever the types are. So even at its loosest, the checker is not doing nothing.

## `--strict`, and what it turns on

```sh
mypy --strict app/
```

```text
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

```text
note: By default the bodies of untyped functions are not checked,
      consider using --check-untyped-defs  [annotation-unchecked]
```

`mypy` reads the *signature* of an unannotated function and skips its *body* entirely. Turning
this on checks inside those bodies without demanding the signatures first — **so it finds things
on day one and asks nobody to write an annotation**, which makes it the cheapest flag to switch
on across a whole codebase.
