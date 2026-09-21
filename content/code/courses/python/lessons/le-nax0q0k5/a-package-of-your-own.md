---
title: Layout, `build-system`, and installing it with `-e`
version: 1
---

```sh
rates/
  pyproject.toml
  src/
    rates/
      __init__.py
      cli.py
  tests/
    test_cli.py
```

**The `src/` layout.** The importable package sits one directory down, which means the project
root is not on `sys.path` and a test importing `rates` gets the *installed* copy rather than the
directory beside it. That is the whole argument for it: the tests exercise what a user gets.

## `build-system`

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

The backend that turns your source into a wheel. `hatchling`, `setuptools`, `poetry-core` and
`flit` all do it, and for a straightforward package the choice barely matters — `hatchling` is
the current default recommendation and needs no configuration for the layout above.

This table is what makes the directory *buildable*. Without it, `pip install .` does not know
what to do.

## Building

```sh
$ uv build
Successfully built dist/rates-0.1.0.tar.gz
Successfully built dist/rates-0.1.0-py3-none-any.whl
```

Two artefacts. The **sdist** (`.tar.gz`) is the source, and the **wheel** (`.whl`) is the
installable one — a zip file with a fixed layout:

```sh
rates/__init__.py
rates/cli.py
rates-0.1.0.dist-info/METADATA
rates-0.1.0.dist-info/WHEEL
rates-0.1.0.dist-info/entry_points.txt
rates-0.1.0.dist-info/RECORD
```

`py3-none-any` in the filename means: any Python 3, no ABI, any platform. A package with compiled
parts has a name like `cp311-cp311-manylinux_2_17_x86_64` instead, and there is one per platform.

## The editable install

```sh
pip install -e .
```

```sh
$ python -c "import rates; print(rates.__file__)"
/tmp/rates/src/rates/__init__.py

$ rates
rates 0.1.0
```

`import rates` resolves to your source tree rather than to a copy in `site-packages`, so an edit
takes effect on the next run with no reinstall — measured: changing one line in `cli.py` and
running `rates` again printed the new text.

`uv` does this by default: a project managed by `uv` with a `[build-system]` is installed
editable into its own environment by `uv sync`.

## `[project.scripts]`

```toml
[project.scripts]
rates = "rates.cli:main"
```

The `rates` command above came from that line and the editable install. The value is
`module:function`, and the file it generates is what puts the name on your `PATH`.
