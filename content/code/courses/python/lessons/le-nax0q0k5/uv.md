---
title: `uv`, and the four commands that are most of it
version: 2
---

```sh
uv init                      # write pyproject.toml
uv add "requests>=2.31"      # add a dependency, resolve, install, lock
uv run main.py               # run, in the project's environment
uv sync                      # make the environment match the lock
```

**It does environments, installs, resolution, locking and running.** Written in Rust, and fast
enough that the speed changes how you work: the `uv add` below resolved six packages in 184
milliseconds and installed five in five.

## `uv add`

```sh
$ uv add "requests>=2.31"
Using CPython 3.11.15 interpreter at: /usr/local/bin/python3
Creating virtual environment at: .venv
Resolved 6 packages in 184ms
Installed 5 packages in 5ms
 + certifi==2026.7.22
 + charset-normalizer==3.5.1
 + idna==3.20
 + requests==2.34.2
 + urllib3==2.8.0
```

One command did five things: found an interpreter, created `.venv` **in the project directory**,
resolved, installed, and wrote the line into `pyproject.toml`. There was no environment to
activate first — it made one.

```sh
uv add --dev pytest          # into [dependency-groups]
uv remove requests           # out of the file, out of the environment, out of the lock
```

## `uv run`

```sh
$ rm -rf .venv
$ uv run main.py
Creating virtual environment at: .venv
Installed 10 packages in 9ms
requests 2.34.2
```

**`uv run` checks the environment against the lock before running anything.** Deleting `.venv`
entirely and running the script rebuilt it and ran, in one command. Nothing was activated, and
nothing could have been running against a stale environment.

That is the argument for using it rather than activating: `uv run pytest`, `uv run ruff check .`,
`uv run python -m whatever`. Each one is guaranteed to be running against the file.

## `uv sync`, which is not `install`

```sh
$ uv sync --no-dev
Resolved 12 packages in 3ms
Uninstalled 5 packages in 4ms
 - iniconfig==2.3.0
 - packaging==26.3
 - pluggy==1.6.0
 - pygments==2.21.0
 - pytest==9.1.1
```

It **removed** five packages, because the set it was asked for does not contain them. `pip
install` has no such verb: it adds, and an environment accumulates.

## The flags that belong in CI

```sh
uv lock --check     # fail if the lock does not match pyproject.toml
uv sync --frozen    # install from the lock without re-resolving
```

```sh
$ uv lock --check
The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
```

The first catches the pull request that changed a dependency and did not relock. The second is
what a deployment should run: it installs exactly what was tested and cannot silently resolve to
something else.

## `uv tree`

```sh
rates v0.1.0
├── requests v2.34.2
│   ├── certifi v2026.7.22
│   ├── charset-normalizer v3.5.1
│   ├── idna v3.20
│   └── urllib3 v2.8.0
└── pytest v9.1.1 (group: dev)
```

The answer to "what is this and why is it here", which `pip list` cannot give you.
