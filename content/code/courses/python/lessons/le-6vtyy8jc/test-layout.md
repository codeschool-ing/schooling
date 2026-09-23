---
title: `tests/`, `conftest.py`, and the import that fails
version: 2
---

```sh
project/
  pyproject.toml
  conftest.py            <- empty, and load-bearing
  app/
    __init__.py
    rates.py
  tests/
    test_rates.py
```

```python
# tests/test_rates.py
from app.rates import total
```

```sh
E   ModuleNotFoundError: No module named 'app'
=========================== short test summary info ============================
ERROR tests/test_rates.py
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
```

**Without the `conftest.py` at the root, that import fails.** With it — empty, zero bytes —
everything passes. `pytest` treats the directory holding the topmost `conftest.py` as the root and
puts it on `sys.path`, so `app` becomes importable.

This is the single most common first hour with `pytest`, and the fix looks like superstition until
you know what the file is for.

## What `conftest.py` actually is

It is where fixtures live that more than one test file needs. A `conftest.py` in `tests/` is
visible to everything under `tests/`; one in `tests/api/` is visible to that subdirectory only.
Nothing imports it — `pytest` finds it by name and applies it by position.

```python
# tests/conftest.py
import pytest

@pytest.fixture
def rates():
    return {"BRL": 1.0, "USD": 5.4}
```

Every test under `tests/` may now take `rates` as an argument without importing anything.

## Tests outside the package, and the `__init__.py` question

`tests/` sits beside `app/` rather than inside it, so the suite is not shipped with the
application and imports it the way a user does. Leave `__init__.py` out of `tests/` and two test
files may not share a basename — `tests/api/test_rates.py` and `tests/db/test_rates.py` collide.
Put it in, and they do not.

## Configuration in `pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q --strict-markers"
```

`testpaths` means a bare `pytest` does not walk your virtual environment. `--strict-markers`
turns a misspelled `@pytest.mark.slwo` into an error rather than a marker nobody registered and
nothing selects.
