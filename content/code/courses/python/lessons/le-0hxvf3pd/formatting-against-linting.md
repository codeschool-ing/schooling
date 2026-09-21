---
title: One rewrites the file; the other reports what it found
version: 1
---

```sh
black app/          # changes bytes, says almost nothing
ruff check app/     # says a lot, changes nothing
```

**A formatter decides how the code is laid out.** Where the line breaks, which quote character,
how a long call is arranged. There is no right answer to any of it, which is why handing it to a
program costs nothing and settles it permanently.

**A linter decides whether the code contains something suspect.** An import nobody uses, a `try`
that catches everything, a default argument that is a list. Those have right answers, so the tool
reports them and leaves the fixing to you.

## Why they are two tools and not one

```sh
black rewrote 22 lines of the demonstration module.
ruff reported the same 4 findings before and after.
```

**Layout is not evidence.** A finding that changed when the file was reformatted would be a
finding about the formatting, and neither tool would be worth running. Keeping them apart is what
makes each one's output mean something.

It also means they run at different moments. The formatter runs on save and on every file, with
no thought involved. The linter runs and produces a list somebody reads.

## The overlap, and how to handle it

`ruff` has rules about whitespace and line length — the `E` family, inherited from `pycodestyle`
— and a formatter already decides all of that. Running both means the linter complains about
lines the formatter chose.

```toml
[tool.ruff.lint]
ignore = ["E501"]         # line length: the formatter's job
```

The convention is to let the formatter win: turn off the rules that are about layout and keep the
ones that are about meaning.

## And `ruff format`

```sh
ruff format app/
```

`ruff` is a formatter too, and it aims to produce what `black` produces. On the module in this
lesson's demonstration the two outputs are **byte for byte identical**, which is the claim it
makes and one you can check with `diff` on your own code before you switch.
