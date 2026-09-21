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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 286\" role=\"img\" aria-label=\"A declared range is a question, and the answer changes as the index does: the same range resolves to one version today and a later one six months from now. A lock file records the exact version and the hash of every package, so the second install produces the same bytes as the first.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <rect x=\"190\" y=\"26\" width=\"340\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pyproject.toml — requests&gt;=2.31</text> <text x=\"300\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">today</text> <text x=\"520\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">six months later</text> <text x=\"20\" y=\"113\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">with no lock file</text> <rect x=\"220\" y=\"96\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"300\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <rect x=\"440\" y=\"96\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"520\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.34.2</text> <path d=\"M386 113 L434 113\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"20\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">with uv.lock beside it</text> <rect x=\"220\" y=\"156\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"300\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <rect x=\"440\" y=\"156\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"520\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <path d=\"M386 173 L434 173\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">every package pinned, with the hash of the file</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The lock holds the five you asked for AND the forty they asked for.</text> <text x=\"360\" y=\"267\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">That second half is the one nobody writes down by hand.</text> </svg>", "caption": "The range says what you are willing to accept. The lock says what you actually got, and it is the second one a colleague needs."}
```

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
