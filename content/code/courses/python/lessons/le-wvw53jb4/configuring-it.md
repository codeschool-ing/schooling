---
title: `pyproject.toml`, and the per-module override
version: 2
---

```toml
[tool.mypy]
python_version = "3.12"
files = ["app"]
strict = true
```

```sh
mypy        # no arguments: it reads the config and checks what it names
```

Settings in a file rather than on a command line, so that your editor, your terminal and CI all
run the same check. A flag somebody passes locally and CI does not is a green build on one
machine and a red one on the other, for the same commit.

`python_version` matters more than it looks: it decides which syntax and which standard-library
signatures the checker believes in. Set it to what you deploy on.

## The override, which is how adoption actually happens

```toml
[tool.mypy]
files = ["app"]
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = ["app.legacy.*"]
disallow_untyped_defs = false
```

**Strict everywhere, loose in one named place.** Without the override the run reports
`app/legacy/old.py:1: error: Function is missing a type annotation`; with it, `Success: no issues
found in 4 source files` — and the rest of the package is still strict.

The double brackets are TOML's array-of-tables: you write the block again for the next module,
and `module` takes a list, so one block can name several.

## The third party that has no annotations

```toml
[[tool.mypy.overrides]]
module = ["someoldlib.*"]
ignore_missing_imports = true
```

Scoped to the library that is the problem. `ignore_missing_imports = true` at the top level
silences the message for everything, including the import you misspelled — which is the next
section's subject.

## What not to put in it

`exclude` looks like the tool for a directory you are not ready for, and it is the wrong one: an
excluded module is still IMPORTED by the modules you do check, so its errors come back through
the front door and you have made the report confusing rather than smaller. An override with
loosened flags keeps it checked at a level it can pass.
