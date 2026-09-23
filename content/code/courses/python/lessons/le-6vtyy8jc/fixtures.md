---
title: A fixture is asked for by name
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"A test asks for a fixture by naming it as an argument. pytest finds the fixture with that name, runs it, and passes back what it returned. With a yield, everything before it runs before the test and everything after it runs once the test is done.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">def test_conversion(rates):</text> <path d=\"M326 52 L394 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the argument name is the request</text> <rect x=\"400\" y=\"34\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"550\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">@pytest.fixture  def rates():</text> <path d=\"M394 84 L326 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and what it returned arrives as the argument</text> <text x=\"20\" y=\"148\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">and with a yield in it</text> <rect x=\"20\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"132\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">everything before the yield</text> <text x=\"132\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">before the test</text> <rect x=\"256\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"368\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the test runs</text> <path d=\"M246 178 L252 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"492\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"604\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">everything after the yield</text> <path d=\"M482 178 L488 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"604\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">after it, however it ended</text> </svg>", "caption": "A test says what it needs in its own signature, and nothing has to be set up by whoever remembered."}
```

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
