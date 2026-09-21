---
title: `pyproject.toml`, and the two settings that have to agree
version: 1
---

```toml
[tool.black]
line-length = 88
target-version = ["py312"]

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "B", "SIM", "UP", "I", "A"]
ignore = ["E501"]
```

One file, at the project root, read by both. It is what makes your editor, your terminal and CI
do the same thing — a tool configured on the command line of one machine is a green check in one
place and a red one in the other.

## `line-length` in two places

The two tools do different things with the same number: `black` wraps at it, `ruff` reports lines
longer than it. **Set them to the same value**, or the formatter produces lines the linter
complains about, every time, on files nobody touched.

Then turn `E501` off anyway. Once the formatter owns the line width, a report about it is a
report about the formatter's decision.

## `target-version`

```toml
target-version = "py312"
```

For `black` it decides which syntax it may use in the output. For `ruff` it decides what `UP`
suggests — with `py312`, `Optional[int]` becomes `int | None` and `typing.List` becomes `list`.
Set it to the oldest version you deploy on, and the tools will not write syntax that fails there.

The spelling differs: `black` takes a list, `ruff` takes a string. That is the kind of detail
that costs ten minutes once.

## `ruff` has two tables

`[tool.ruff]` holds what applies to the whole tool — `line-length`, `target-version`, `exclude`.
`[tool.ruff.lint]` holds `select`, `ignore` and the per-file table; `[tool.ruff.format]` holds the
formatter's settings. Putting `select` in the outer table is a deprecation warning rather than an
error, which is how it goes unnoticed.

## What to exclude

```toml
[tool.ruff]
exclude = ["migrations", "generated"]
```

Machine-written files. Everything else is yours, and a directory excluded because it is
inconvenient is a directory that stops being checked and never comes back.
