---
title: A fixture is asked for by name
version: 1
---

```python
import pytest

@pytest.fixture
def rates():
    return {"BRL": 1.0, "USD": 5.4}

def test_conversion(rates):
    assert rates["USD"] == 5.4
```

**The argument name is the request.** `pytest` looks for a fixture called `rates`, runs it, and
passes what it returned. That reads oddly for about a day and then stops, and it is what makes a
test's dependencies visible in its signature.

## Teardown after the `yield`

```python
@pytest.fixture
def conn():
    c = connect()
    yield c
    c.close()
```

Everything before the `yield` is setting up, the value yielded is what the test receives, and
everything after it is tearing down. **It runs whether the test passed or failed**, which is the
part a `try`/`finally` in each test would get wrong eventually.

## Scope

```python
@pytest.fixture(scope="module")
def conn():
    ...
```

`function` is the default and gives every test its own. `class`, `module`, `package` and
`session` widen it: one build shared by everything in that scope, torn down at the end of it.

A wider scope is faster and it means **one test can leave state behind for the next one** — a row
inserted, a file written, a counter advanced. Take the narrowest scope that is fast enough, and
when you widen it, reset the state in the test rather than trusting the order they run in.

## The ones you did not write

```python
def test_writes_a_file(tmp_path):
    p = tmp_path / "rates.csv"
    p.write_text("BRL,1.0\n")
    assert p.read_text().startswith("BRL")
```

`tmp_path` is a fresh directory per test, named after it — `/tmp/pytest-of-you/pytest-0/
test_writes_a_file0/`. `capsys` captures what was printed, `monkeypatch` undoes what it changed,
`caplog` collects log records. `pytest --fixtures` lists every one available where you are.

## Fixtures that use fixtures

```python
@pytest.fixture
def account(db):
    return db.insert_account("a@b.c")
```

A fixture asks for another the same way a test does. That is how a chain of setting up gets built
once and reused, and `pytest` works out the order.
