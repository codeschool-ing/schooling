---
title: Poetry, the same job with different words
version: 1
---

```sh
poetry init
poetry add "requests>=2.31"
poetry add --group dev pytest
poetry install
poetry run python main.py
```

Older, widely deployed, and doing the same things. If you have used `uv`, the mapping is almost
one to one — and since version 2 the **file** it writes is the same one, which was not true
before.

## What it writes

```toml
[project]
name = "rates"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests (>=2.31)"
]

[dependency-groups]
dev = [
    "pytest (>=9.1.1,<10.0.0)"
]

[build-system]
requires = ["poetry-core>=2.0.0,<3.0.0"]
build-backend = "poetry.core.masonry.api"
```

Three differences from what `uv` produced for the same two commands: the specifiers are in
**parentheses**, Poetry added an **upper bound** to `pytest` that `uv` did not, and it wrote a
`[build-system]` table because it assumes the project is a package.

That third one is the difference you will actually hit.

## The environment is not in the project

```sh
$ poetry env info -p
/root/.cache/pypoetry/virtualenvs/rates-mFpQSSuL-py3.11
```

Poetry keeps its environments in a central cache, named after the project path and a hash of it.
`uv` puts `.venv` beside your code.

Neither is wrong and the consequences differ: an editor finds `.venv` without being told, and a
central cache survives `rm -rf` of the project directory. If you prefer the first:

```sh
poetry config virtualenvs.in-project true
```

## The error everybody meets on their first day

```sh
$ poetry install
Error: The current project could not be installed: No file/folder found for package rates
If you do not want to install the current project use --no-root.
If you want to use Poetry only for dependency management but not for packaging,
you can disable package mode by setting package-mode = false in your pyproject.toml.
```

**Poetry assumes your project is a package to be built.** For an application — a web service, a
script, a data pipeline — it is not, and there is no `rates/` directory for it to install.

The error text tells you both answers, and the second is the one to write down:

```toml
[tool.poetry]
package-mode = false
```

After that `poetry install` reads the lock and installs the dependencies, which is what you
wanted.

## The commands, against `uv`

| | Poetry | `uv` |
| --- | --- | --- |
| add | `poetry add x` | `uv add x` |
| add, development | `poetry add --group dev x` | `uv add --dev x` |
| remove | `poetry remove x` | `uv remove x` |
| install from the lock | `poetry install` | `uv sync` |
| production only | `poetry install --only main` | `uv sync --no-dev` |
| run | `poetry run python x.py` | `uv run x.py` |
| show the tree | `poetry show --tree` | `uv tree` |

The verbs differ; the file does not.
