---
title: What is in one, and why it is committed
version: 1
---

```toml
[[package]]
name = "certifi"
version = "2026.7.22"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/.../certifi-2026.7.22.tar.gz",
          hash = "sha256:741e2c3b351ddf…", size = 138112 }
wheels = [
    { url = "https://files.pythonhosted.org/.../certifi-2026.7.22-py3-none-any.whl",
      hash = "sha256:62f22742b58a1a33…", size = 136983 },
]
```

One entry per package, for **every** package — the five you asked for and the forty they asked
for. An exact version, where it came from, and the hash of the file. `uv.lock` for a project with
one dependency and one development tool is two hundred lines; `poetry.lock` for the same project
is three hundred.

## What it guarantees

That two installs produce the same bytes. `pyproject.toml` says `requests>=2.31`, which was true
of 2.31.0 in March and is true of 2.34.2 today; the lock says which one, and the hash says which
file.

Lesson 18's Thursday — a transitive dependency moving under a pin that looked exact — cannot
happen, because the transitive half is pinned too.

## It is committed, and never edited

It goes into git, like any other fact about the project. It is generated, so a conflict in it is
resolved by regenerating rather than by merging — `uv lock` or `poetry lock` after taking the
other side's `pyproject.toml`.

**A hand edit is the one thing that breaks the guarantee**, because the hashes stop matching what
the versions claim and nothing checks that until an install fails somewhere else.

## `install` against `sync`

```sh
$ uv sync --no-dev
Uninstalled 5 packages in 4ms
 - pytest==9.1.1
 …
```

`install` makes sure everything in the file is present. **`sync` makes the environment equal to
the file**, which means removing what is not in it.

The difference is a dependency somebody deleted three months ago that is still installed on one
machine — the machine where the bug cannot be reproduced.

## Updating

```sh
uv lock --upgrade-package requests   # one package, everything else held
uv lock --upgrade                    # everything, within the declared ranges
```

Updating one thing is a small reviewable diff. Updating everything is a diff nobody reads, and it
belongs in a pull request of its own with the tests run against it.

## In CI

```sh
uv lock --check        # is the lock consistent with pyproject.toml?
uv sync --frozen       # install from the lock, do not resolve
```

```sh
The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
```

The first is what catches somebody adding a dependency and forgetting to commit the lock. The
second is what a deployment runs: it installs what was tested and cannot resolve to anything else
on the day the index changes.

Poetry's equivalents are `poetry check --lock` and `poetry install --sync`.
