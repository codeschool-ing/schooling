---
title: `dependencies`, groups, and `requires-python`
version: 1
---

```toml
[project]
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31",
    "pandas~=2.2.0",
]
```

Same specifiers as lesson 18, in a list. What was one line per package in `requirements.txt` is
one string per package here, and everything about `==`, `>=` and `~=` carries over unchanged.

## The development group

```toml
[dependency-groups]
dev = [
    "pytest>=9.1.1",
    "ruff>=0.15",
]
```

`[dependency-groups]` is a standard table, and both `uv` and Poetry write it. Things in a group
are **not** dependencies of the package: they are needed to work on it. Installing the project in
production installs `dependencies` and none of the groups.

```sh
uv sync            # dependencies + the dev group
uv sync --no-dev   # dependencies only
```

You can have more than one group — `docs`, `lint`, `typing` — and a group may include another.

## Optional dependencies, which are a different thing

```toml
[project.optional-dependencies]
postgres = ["psycopg[binary]>=3.1"]
excel = ["openpyxl>=3.1"]
```

```sh
pip install rates[postgres]
```

These are for **your users**, not for you: a feature of the package that needs an extra library,
which somebody installs by naming it in brackets. A development group is invisible to anybody who
installs your package; an optional dependency is part of its interface.

Getting the two the wrong way round is the common mistake, and it ships `pytest` to everybody who
installs your library.

## `requires-python`

```toml
requires-python = ">=3.11"
```

It is checked at install time: `pip` refuses on 3.10 with a message naming the requirement,
rather than installing and failing on the first piece of syntax it cannot parse.

It also tells `mypy`, `ruff` and the resolver which versions to reason about — and the resolver
uses it to pick dependency versions that work across the whole range, which is why a wide
`>=3.8` sometimes holds a library back several versions.
