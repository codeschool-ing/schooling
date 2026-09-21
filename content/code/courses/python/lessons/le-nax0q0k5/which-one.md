---
title: Three arrangements, and how to tell which you are in
version: 1
---

**Look at the files before you type anything.** A repository tells you what it expects in one
`ls`, and running the wrong tool writes a second lock file that somebody has to delete.

| what is there | what to run |
| --- | --- |
| `uv.lock` | `uv sync`, then `uv run …` |
| `poetry.lock` | `poetry install`, then `poetry run …` |
| `requirements.txt` and nothing else | `python -m venv .venv`, then `pip install -r` |

A `pyproject.toml` on its own settles nothing: all three arrangements have one now, and so does a
project that only uses it to configure `ruff`.

## Reading it more precisely

```toml
[tool.poetry]              # Poetry, and possibly an old-style file
[tool.uv]                  # uv-specific settings
[build-system]
requires = ["poetry-core"] # built by Poetry
requires = ["hatchling"]   # built by hatch, managed by anything
```

`[build-system]` names the **backend that builds the wheel**, and it is independent of the tool
you use day to day: a project can be managed with `uv` and built with `hatchling`, or managed
with Poetry and built with `poetry-core`.

## The old-style Poetry file, which you will still meet

```toml
[tool.poetry]
name = "rates"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.31"
```

Poetry before version 2 wrote its own tables instead of `[project]`, with its own specifier
syntax: `^2.31` means `>=2.31,<3` and `~2.31` means `>=2.31,<2.32`. It still works, `uv` cannot
read it, and converting it is mechanical.

**`^` is Poetry's, not Python's.** It does not appear in a `[project]` table and `pip` does not
understand it.

## On somebody else's repository

1. `ls` for a lock file, and use the tool that wrote it.
2. Do not add a second one. Two lock files in a repository is two answers to one question, and
   nobody finds out which is being used until a deployment differs from a laptop.
3. If there is no lock file at all and only a `requirements.txt`, that is lesson 18 and it is
   fine. Proposing a migration is a conversation, not a commit.

## And if the choice is yours

`uv`, today. It is faster by an order of magnitude, it manages interpreters as well as packages,
and its lock file is a standard-shaped thing. Poetry is not a mistake and a project already on it
has no reason to move.

That recommendation has a date on it, which is the subject of the last reading in this lesson.
