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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Four files used to divide the job between them: one built the package, one installed it, one held the settings for tools that could not read the first, and one listed the files none of the others mentioned. One table in one file replaces them, and four different tools read the same keys out of it.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">what it replaces</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup.py — built the package</text> <rect x=\"20\" y=\"78\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">requirements.txt — installed it</text> <rect x=\"20\" y=\"120\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup.cfg — settings for tools that could not read setup.py</text> <rect x=\"20\" y=\"162\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">MANIFEST.in — the files none of the others mentioned</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">[project], in pyproject.toml</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">pyproject.toml</text> <rect x=\"380\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uv</text> <path d=\"M417 136 L417 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"462\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"499\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">poetry</text> <path d=\"M499 136 L499 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"544\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"581\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pip</text> <path d=\"M581 136 L581 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"626\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"663\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hatch</text> <path d=\"M663 136 L663 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"540\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">all four read the same keys</text> </svg>", "caption": "The table is defined by a specification rather than by whichever program you happen to run, which is why a project can move between them without an edit."}
```

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
