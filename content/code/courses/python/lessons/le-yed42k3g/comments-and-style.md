---
title: The indentation is the syntax
version: 1
---

## Comments

`#` and the rest of the line is ignored.

```python
# read the file the person named, not the one we assumed
path = sys.argv[1]
```

A comment that says *what* the line does is noise — the line already says that. A comment earns its
place when it says **why**, or names the thing that is not visible: the edge case, the reason this
is not the obvious approach, the bug it is working around.

## A docstring is not a comment

The first string in a file, a function or a class is its **docstring**, and it is part of the
object at runtime:

```python
def normalise(name):
    """Strip whitespace and lowercase, for comparing names typed by people."""
    return name.strip().lower()
```

`help(normalise)` prints that sentence. A `#` comment above the `def` would not — `help` cannot see
it. That is the whole difference, and it is why the convention is not arbitrary.

## Indentation is not a preference

In most languages the braces decide the block and the indentation is decoration that a formatter
fixes. In Python **the indentation IS the block**.

```python
if ready:
    send()
    log()
done()
```

`send` and `log` are inside the `if`. `done` is not. There is no other marker; move `done` four
spaces right and the meaning changes.

**Four spaces per level.** Not two, not a tab — four, because that is what the whole ecosystem
does and what every formatter in lesson 17 will produce.

**Do not mix tabs and spaces.** A file that looks aligned and mixes the two produces
`TabError: inconsistent use of tabs and spaces in indentation`, and you cannot see the cause by
reading it. Every editor has a *convert indentation to spaces* command; use it once and set the
editor to insert spaces from then on.

## The rest of the style

There is a document, PEP 8, and there is no point learning it by hand: **lesson 17 is a tool that
applies it for you**, and the tool is the answer. What is worth carrying until then is:

- `snake_case` for names of variables and functions
- `UPPER_CASE` for constants
- a blank line between functions, two between top-level definitions
- and a name that says what the thing is, because `data`, `temp` and `x` are three ways of not
  having decided
