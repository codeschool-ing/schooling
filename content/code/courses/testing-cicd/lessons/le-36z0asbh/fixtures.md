---
title: Fixtures, set up and torn down
version: 1
---

Every test needs a world to run in: a database with a schema, a server listening on a port, a file
in a known place. The code that builds that world and removes it afterwards is called a
**fixture**. Writing it inside each test buries the test's point under setup; writing it once and
sharing it is what fixtures are for.

In pytest a fixture is a function decorated with `@pytest.fixture`. A test asks for it by naming it
as a parameter, and pytest runs the fixture first and passes in what it returns. `shipquote`'s
store fixture, in `tests/conftest.py`, is five lines:

```schooling-example
{
  "language": "python",
  "file": "tests/conftest.py",
  "parts": [
    {
      "code": "@pytest.fixture\ndef store(tmp_path):\n    s = Store(tmp_path / \"quotes.db\")",
      "note": "Setup: a new SQLite file inside `tmp_path`, a directory pytest creates for this test alone. `tmp_path` is itself a fixture, which is how fixtures compose: this one asks for that one by name."
    },
    {
      "code": "    yield s",
      "note": "`yield` hands the store to the test and pauses here while the test runs."
    },
    {
      "code": "    s.close()",
      "note": "Teardown: whatever follows `yield` runs after the test, **whether it passed or failed**, so the connection is closed either way."
    }
  ]
}
```

`conftest.py` is a file pytest reads before the tests in its directory, so a fixture defined there
is available to every test file beside it, without an import.

## Watching it happen

`--setup-show` prints every fixture as it is set up and torn down, around each test:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py --setup-show -q

SETUP    S tmp_path_factory
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_a_saved_quote_comes_back_by_id (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_recent_lists_the_newest_first (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
        SETUP    F tmp_path (fixtures used: tmp_path_factory)
        SETUP    F store (fixtures used: tmp_path)
        tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length (fixtures used: request, store, tmp_path, tmp_path_factory) .
        TEARDOWN F store
        TEARDOWN F tmp_path
TEARDOWN S tmp_path_factory
3 passed in 0.65s
```

Read it as a nesting. `tmp_path_factory`, marked `S` for session, is set up once at the start and
torn down once at the end. Inside it, **each test gets a fresh `tmp_path` and a fresh `store`**,
marked `F` for function, and both are torn down before the next test starts. Three tests, three
databases, none of them shared.

## What a fixture buys

Two things, and the second matters more than the first.

**Less repetition.** The three store tests would otherwise each open a connection, create the
schema and close it. That is three copies of the same lines, and three places to forget the close.

**Isolation by default.** Because the store fixture is function-scoped, no test can see another
test's rows. A test that passes alone also passes in any order, next to any other test. Section 03
shows what happens when that guarantee is traded away for speed, and why the trade is tempting.

A fixture is also where cleanup becomes reliable. Code after `yield` runs even when the test fails,
which a `close()` at the end of a test body does not: an assertion that fails stops the test on
that line, and everything below it is skipped.
