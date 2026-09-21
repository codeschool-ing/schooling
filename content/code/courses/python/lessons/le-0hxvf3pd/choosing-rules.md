---
title: The default set, and the family it leaves out
version: 1
---

```text
default: E4, E7, E9, F
```

**The default is small on purpose** — it is what almost any codebase can pass on its first run.
It is imports, undefined names, and a handful of `E` rules that are unambiguous.

What it leaves out is the point of this section:

```python
def load_rates(path, cache = {}):
    if path in cache:
        return cache[path]
    ...
```

```text
(default rules)  Found 0 errors.
(with B)         B006 Do not use mutable data structures for argument defaults
```

A default argument is evaluated **once, at definition**, so that dictionary is shared by every
call the process ever makes. It works, and it is a cache that never empties and crosses between
callers.

## Turning families on

```toml
[tool.ruff.lint]
select = ["E", "F", "B", "SIM", "UP", "I", "A"]
ignore = ["E501"]
```

`select` **replaces** the default rather than adding to it, so listing `B` alone would turn `F`
off. Write out the whole set you want.

A reasonable starting list is the one above: the defaults, plus bugbear for the defects, plus
import sorting, simplifications, upgrades and shadowed built-ins. Add a family, run
`--statistics`, fix or ignore, commit. One family per pull request.

## The per-file ignore

```toml
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/*" = ["S101"]
```

A package's `__init__.py` imports names so that other modules can import them from there, and
every one of those is "unused" as far as `F401` can see. That is a property of the file rather
than a mistake in it, which is exactly what this table is for.

`S101` is "don't use `assert`", which is right in application code and wrong in a test file.

**A per-file ignore belongs in the config; a `# noqa` belongs on a line.** The config is where a
rule about a KIND of file goes, and it is reviewed once instead of appearing on forty lines.

## `# noqa`, precisely

```python
import os      # noqa: F401     silences F401 here
import sys     # noqa           silences EVERYTHING here
import json    # noqa: E501     silences nothing: the finding is F401
```

Name the code. A bare `# noqa` also silences the rule that starts applying to that line next
year.

```toml
[tool.ruff.lint]
extend-select = ["RUF100"]
```

`RUF100` reports `Unused noqa directive (unused: F401)` — a suppression whose reason has gone.
Without it, the comments accumulate and nobody can tell which ones still matter.
