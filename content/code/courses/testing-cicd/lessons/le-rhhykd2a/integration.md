---
title: Integration tests
version: 1
---

An **integration test** runs your code against a real collaborator that your unit tests left out:
a database, a file system, a message queue, another service. It answers the question unit tests
cannot: **do the two sides agree?** Your SQL against the real engine's dialect, your column types
against the real schema, your constraint against the real constraint.

`shipquote` keeps quotes in SQLite, so a customer can come back to one. The store is small:

```python
"""Quotes kept in SQLite, so a customer can come back to one."""
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS quotes (
    id INTEGER PRIMARY KEY,
    cep TEXT NOT NULL CHECK (length(cep) = 8),
    weight_g INTEGER NOT NULL CHECK (weight_g > 0),
    cents INTEGER NOT NULL CHECK (cents >= 0),
    created_at TEXT NOT NULL
)
"""
COLUMNS = ("id", "cep", "weight_g", "cents", "created_at")


class Store:
    def __init__(self, path):
        self.db = sqlite3.connect(path)
        self.db.execute(SCHEMA)

    def save(self, cep, weight_g, cents, created_at):
        with self.db:
            cur = self.db.execute(
                "INSERT INTO quotes (cep, weight_g, cents, created_at)"
                " VALUES (?, ?, ?, ?)",
                (cep, weight_g, cents, created_at))
        return cur.lastrowid

    def get(self, quote_id):
        row = self.db.execute(
            "SELECT id, cep, weight_g, cents, created_at FROM quotes"
            " WHERE id = ?", (quote_id,)).fetchone()
        return None if row is None else dict(zip(COLUMNS, row))

    def recent(self, n):
        rows = self.db.execute(
            "SELECT id FROM quotes ORDER BY created_at DESC, id DESC LIMIT ?",
            (n,)).fetchall()
        return [r[0] for r in rows]

    def close(self):
        self.db.close()
```

None of this can be checked without running it against SQLite. A typo in `ORDER BY`, a column in
the wrong position, a `CHECK` that refuses something it should accept: each is a string the Python
interpreter does not look inside. The tests open a real database file in a temporary directory,
which pytest provides as `tmp_path`, and lesson 3 explains the fixture that does it.

```python
import sqlite3

import pytest

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    second = store.save("20040002", 300, 1590, "2026-10-05T13:31:00-03:00")
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save("0131010", 1200, 2190, "2026-10-05T13:30:00-03:00")
```

The third test is the one a unit test could never write. **It asserts that the database refuses a
seven-digit CEP**, which is a promise made by the schema, not by any Python. If somebody edits the
`CHECK` away, the Python still runs, and only this test notices.

`pytestmark = pytest.mark.integration` labels every test in the file, so the layer can be run on
its own:

```
ana@laptop:~/shipquote$ python -m pytest -m integration -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 31 items / 28 deselected / 3 selected

tests/test_store.py::test_a_saved_quote_comes_back_by_id PASSED          [ 33%]
tests/test_store.py::test_recent_lists_the_newest_first PASSED           [ 66%]
tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length PASSED [100%]

======================= 3 passed, 28 deselected in 0.17s =======================
```

Three of 31 were selected, and they took 0.17 seconds. SQLite lives in the same process as the
test, so here integration costs almost nothing. **With a database server it would not**: starting
PostgreSQL, creating a schema and cleaning up between tests turns milliseconds into seconds. This
repository's own CI starts a real PostgreSQL for exactly this reason, and lesson 6 reads that
workflow.

## Real, or a stand-in?

A common shortcut is to run integration tests against a lighter engine than production: SQLite in
the tests, PostgreSQL in production. It is faster and it is a trap. The two disagree on types, on
`ORDER BY` with ties, on what a `CHECK` may contain, and the test passes against the engine that is
not deployed. **An integration test is worth what its collaborator resembles production.**
`shipquote` uses SQLite in production too, so here the test is honest. Lesson 8 comes back to
this as *parity* between environments.

What integration tests do not see is the whole application: how a request reaches `Store`, how
the answer is encoded, whether the server starts. That is the next layer.
