---
title: Scope, and the state that leaks
version: 1
---

A fixture's **scope** decides how often it is built. The default, `function`, builds it for every
test. `module` builds it once per test file, `session` once per run. A wider scope is cheaper, and
lesson 1 measured the reason to want it: the HTTP server fixture is module-scoped because shutting a
server down costs half a second, and paying that for every functional test would multiply it.

The price of a wider scope is **shared state**. Every test using a module-scoped store writes into
the same database, and a test can then pass or fail depending on what ran before it.

## pytest refuses the obvious mistake

Change only the decorator of the store fixture to `scope="module"` and pytest stops before any
test runs:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q -k saved
E                                                                        [100%]
==================================== ERRORS ====================================
____________ ERROR at setup of test_a_saved_quote_comes_back_by_id _____________
ScopeMismatch: You tried to access the function scoped fixture tmp_path with a module scoped request object. Requesting fixture stack:
tests/conftest.py:13:  def store(tmp_path)
Requested fixture:
.venv/lib/python3.13/site-packages/_pytest/tmpdir.py:290:  def tmp_path(request: 'FixtureRequest', tmp_path_factory: 'TempPathFactory') -> 'Generator[Path]'
=========================== short test summary info ============================
ERROR tests/test_store.py::test_a_saved_quote_comes_back_by_id - Failed: Scop...
2 deselected, 1 error in 0.16s
```

The store asks for `tmp_path`, which is created per test. A module-scoped fixture cannot depend on
a function-scoped one, because it would outlive the thing it was built from, and pytest says so
with `ScopeMismatch`. That refusal is useful: it is a design error caught at setup rather than a
strange failure later.

## The mistake pytest cannot see

The way round it is `tmp_path_factory`, which is session-scoped and makes directories on request.
Here the fixture is rewritten to use it, and one new test is added that asserts a fresh store has
no quotes:

```python
def test_a_new_store_has_no_quotes(store):
    assert store.recent(10) == []
```

```
ana@laptop:~/shipquote$ git diff tests/conftest.py
diff --git a/tests/conftest.py b/tests/conftest.py
index a9a0d29..9320668 100644
--- a/tests/conftest.py
+++ b/tests/conftest.py
@@ -10,9 +10,9 @@ from shipquote.app import Handler
 from shipquote.store import Store
 
 
-@pytest.fixture
-def store(tmp_path):
-    s = Store(tmp_path / "quotes.db")
+@pytest.fixture(scope="module")
+def store(tmp_path_factory):
+    s = Store(tmp_path_factory.mktemp("db") / "quotes.db")
     yield s
     s.close()
 
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q --tb=line
...F                                                                     [100%]
=================================== FAILURES ===================================
E   assert [3, 2, 1] == []
      
      Left contains 3 more items, first extra item: 3
      Use -v to get more diff
/home/ana/shipquote/tests/test_store.py:27: assert [3, 2, 1] == []
=========================== short test summary info ============================
FAILED tests/test_store.py::test_a_new_store_has_no_quotes - assert [3, 2, 1]...
1 failed, 3 passed in 0.16s
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -q -k no_quotes
.                                                                        [100%]
1 passed, 3 deselected in 0.15s
```

Run with the other three, the new test fails: the store already holds quotes 1, 2 and 3, written
by the tests before it. Run alone, with `-k no_quotes`, it passes. **The same test, the same code,
two results, decided by what else ran.** Notice also what did not fail: `recent(2) == [second,
first]` still passed, because the two newest rows happened to be its own. Shared state does not
always show; it shows the day a test is added or the order changes.

## Choosing a scope

Widen a fixture's scope when two things are true:

1. **It is expensive to build**, measurably, as the server's half second is.
2. **Tests cannot change it**, or each test cleans up after itself completely.

A server that answers requests and keeps nothing qualifies. A database that tests write into does
not, unless every test undoes its writes, which section 05 shows how to arrange. When in doubt keep
the default: a slow suite is visible on every run, and an order-dependent one fails at random on
somebody else's machine.
