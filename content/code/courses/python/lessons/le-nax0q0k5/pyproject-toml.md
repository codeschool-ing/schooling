---
title: The file that replaced four
version: 1
---

```toml
[project]
name = "rates"
version = "0.1.0"
description = "Currency rates"
requires-python = ">=3.11"
dependencies = ["requests>=2.31"]
```

**One file, one format, read by every tool.** `setup.py` built the package, `requirements.txt`
installed it, `setup.cfg` held the settings for tools that could not read `setup.py`, and
`MANIFEST.in` listed the files none of the others mentioned.

## `[project]` is a standard, not a tool's format

The table above is defined by a specification rather than by whichever program you happen to run.
`uv`, Poetry, `pip` and `hatch` all read the same keys, which is why a project can move between
them without an edit.

The keys worth knowing:

- **`name`** and **`version`** — what it is called and which release this is.
- **`requires-python`** — the interpreters it claims to work on. `pip` refuses to install it on
  anything else, which is a better failure than an import error halfway through.
- **`dependencies`** — a list of the same specifiers as `requirements.txt`.
- **`readme`**, **`license`**, **`authors`**, **`classifiers`** — metadata that matters when it
  is published and not before.

## `[project.scripts]`

```toml
[project.scripts]
rates = "rates.cli:main"
```

Installing the package puts a `rates` command on the `PATH` that calls `main()` in `rates.cli`.
That is how every command-line tool you have installed with `pip` got its name.

## The tool tables

```toml
[tool.ruff.lint]
select = ["E", "F", "B"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
strict = true
```

Everything under `[tool.<name>]` belongs to that tool and is ignored by the rest. This is why
lessons 15, 16 and 17 all put their configuration here: it is one file to read when you join a
project, instead of five dotfiles at the root.

## And TOML, briefly

```toml
key = "string"
number = 88
flag = true
list = ["a", "b"]

[table]
nested = "value"

[[array-of-tables]]
one = 1

[[array-of-tables]]
two = 2
```

That is most of it. The double brackets are how a list of tables is written — which you have
already seen as `[[tool.mypy.overrides]]`.
