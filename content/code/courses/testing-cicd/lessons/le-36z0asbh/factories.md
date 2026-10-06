---
title: Factories for test data
version: 1
---

A test of the store needs a quote to save: a CEP, a weight, a price and a timestamp. Written out
in every test, those four values are noise, and they hide the one value each test is actually
about. A **factory** builds a valid object with sensible defaults and lets the test override only
the fields it cares about.

`shipquote`'s factory, from step 7 of the project, is a function in `tests/factories.py`:

```schooling-example
{
  "language": "python",
  "file": "tests/factories.py",
  "parts": [
    {
      "code": "\"\"\"Test data with sensible defaults: a test names only what it is about.\"\"\"\nfrom itertools import count\n\n_ids = count(1)",
      "note": "A counter shared by every call, so each quote the factory builds is different from the last."
    },
    {
      "code": "def a_quote(**overrides):\n    \"\"\"A valid quote row; override the fields the test cares about.\"\"\"\n    n = next(_ids)\n    quote = {\n        \"cep\": \"01310100\",\n        \"weight_g\": 1200,\n        \"cents\": 2190,\n        \"created_at\": f\"2026-10-05T13:{n % 60:02d}:00-03:00\",\n    }",
      "note": "The defaults describe one ordinary, valid quote: a CEP in São Paulo, 1.2 kg, R$ 21,90. The timestamp uses the counter so that two quotes built in a row never share a `created_at`, which matters to a store that sorts by it."
    },
    {
      "code": "    quote.update(overrides)\n    return quote",
      "note": "The test's overrides replace the defaults. Everything else stays valid."
    }
  ]
}
```

And the store tests, rewritten to use it:

```python
import sqlite3

import pytest

from tests.factories import a_quote

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save(**a_quote(cents=2190))
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save(**a_quote(created_at="2026-10-05T13:30:00-03:00"))
    second = store.save(**a_quote(created_at="2026-10-05T13:31:00-03:00"))
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save(**a_quote(cep="0131010"))
```

Each test now names what it is about and nothing else. The first is about cents, so it says
`cents=2190`. The second is about ordering by time, so it sets two `created_at` values. The third is
about a CEP the database must refuse, so it passes `cep="0131010"`, and the reader can see that is
seven digits without searching for it among three other arguments.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 3 items

tests/test_store.py::test_a_saved_quote_comes_back_by_id PASSED          [ 33%]
tests/test_store.py::test_recent_lists_the_newest_first PASSED           [ 66%]
tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length PASSED [100%]

============================== 3 passed in 0.20s ===============================
```

## Why not literals

Literals are fine when every value in them matters. They stop being fine when the object grows. Add
a `carrier` column to quotes next month, and every test that spells out a quote has to change,
including the ones that have nothing to do with carriers. With a factory, one default changes.

There is a second, quieter benefit: **a factory's defaults are valid by construction**. A test that
types `weight_g=0` by accident fails with a CHECK error and looks like a store bug. A factory's
default weight is a real weight, so a test only hits an invalid value when it asks for one.

## Builders and libraries

The function above is the simplest form. Larger projects use libraries that do the same with more
structure: `factory_boy` in Python, `FactoryBot` in Ruby, `Fishery` in TypeScript. They add
sequences for unique values, related objects built on demand and integration with ORMs. Whatever
the tool, the idea is the one shown here: **valid defaults, explicit overrides, and nothing in the
test that the test is not about.**
