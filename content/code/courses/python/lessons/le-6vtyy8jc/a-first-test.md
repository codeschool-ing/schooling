---
title: A file, a function, and a bare `assert`
version: 1
---

```python
# test_slug.py
from app.slug import slugify

def test_spaces_become_hyphens():
    assert slugify("Hello World") == "hello-world"
```

```sh
pytest
```

```sh
test_slug.py .                                                           [100%]
============================== 1 passed in 0.02s ===============================
```

**That is the whole interface.** No class to inherit from, no `assertEqual`, no registration
anywhere. A file whose name starts with `test_`, a function whose name starts with `test_`, and a
plain Python `assert` inside it.

## What `pytest` looks for

Run with no arguments, it walks down from where you are and collects every `test_*.py`, and inside
each one every function called `test_*`. Anything else in the file is ordinary code — helpers,
imports, constants — and is left alone.

## The dot

```sh
test_slug.py .F                                                          [100%]
```

One character per test, in the order they ran: `.` passed, `F` failed, `E` raised before the test
body started, `s` skipped. On a suite of four hundred it is a progress bar you can read.

## Running less than everything

```sh
pytest tests/test_slug.py              # one file
pytest tests/test_slug.py::test_spaces_become_hyphens   # one test
pytest -k slug                         # every test whose name contains "slug"
pytest -x                              # stop at the first failure
pytest --lf                            # only the ones that failed last time
```

`-x` and `--lf` together are how a broken suite gets fixed: run the failures, stop at the first,
fix, repeat. `-q` shortens the report and `-v` gives one line per test with its full name.

## The exit code

`pytest` exits 0 when everything passed and non-zero otherwise, which is the whole of what CI
needs from it. Everything else in the output is for you.
