---
title: A table of cases, kept as data
version: 1
---

Some rules are best checked as a table: inputs in columns, the expected answer in the last one,
one row per case. The shop publishes a freight table for customers, and `shipquote` keeps the same
cases in `tests/data/quotes.csv`:

```
cep,weight_g,subtotal_cents,cents
01310-100,300,5000,1290
01310-100,1200,5000,2190
20040-002,300,5000,1590
40010-000,2600,5000,4740
69005-010,300,5000,2990
69005-010,5000,5000,7040
70040-010,800,5000,2640
80010-000,300,19900,0
```

The test reads the file and turns every row into a test case:

```python
"""The price table the shop publishes, one row per case, checked as data."""
import csv
from pathlib import Path

import pytest

from shipquote.quote import freight

ROWS = list(csv.DictReader(open(Path(__file__).parent / "data" / "quotes.csv")))


@pytest.mark.parametrize("row", ROWS, ids=lambda r: f"{r['cep']}-{r['weight_g']}g")
def test_the_published_table(row):
    cents = freight(row["cep"], int(row["weight_g"]), int(row["subtotal_cents"]))
    assert cents == int(row["cents"])
```

`ids=` names each case from its own row, which is what makes the run readable:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote_table.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 8 items

tests/test_quote_table.py::test_the_published_table[01310-100-300g] PASSED [ 12%]
tests/test_quote_table.py::test_the_published_table[01310-100-1200g] PASSED [ 25%]
tests/test_quote_table.py::test_the_published_table[20040-002-300g] PASSED [ 37%]
tests/test_quote_table.py::test_the_published_table[40010-000-2600g] PASSED [ 50%]
tests/test_quote_table.py::test_the_published_table[69005-010-300g] PASSED [ 62%]
tests/test_quote_table.py::test_the_published_table[69005-010-5000g] PASSED [ 75%]
tests/test_quote_table.py::test_the_published_table[70040-010-800g] PASSED [ 87%]
tests/test_quote_table.py::test_the_published_table[80010-000-300g] PASSED [100%]

============================== 8 passed in 0.16s ===============================
```

## Why a file rather than a list in the test

`parametrize` with a list, as in lesson 1, is enough while a table is short and only programmers
change it. A CSV earns its place when **somebody else owns the numbers**. The commercial team can
read a spreadsheet; they cannot be expected to read Python. When the table is the shop's published
promise, a file the team can open, review and change in a pull request keeps the code and the
promise in one place.

## What a table catches

Here zone N's base price is raised from 2990 to 3090 in the code, as somebody might do after a new
contract with the carrier, and nobody touches the CSV:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote_table.py -q --tb=line
....FF..                                                                 [100%]
=================================== FAILURES ===================================
E   AssertionError: assert 3090 == 2990
     +  where 2990 = int('2990')
/home/ana/shipquote/tests/test_quote_table.py:15: AssertionError: assert 3090 == 2990
E   AssertionError: assert 7140 == 7040
     +  where 7040 = int('7040')
/home/ana/shipquote/tests/test_quote_table.py:15: AssertionError: assert 7140 == 7040
=========================== short test summary info ============================
FAILED tests/test_quote_table.py::test_the_published_table[69005-010-300g] - ...
FAILED tests/test_quote_table.py::test_the_published_table[69005-010-5000g]
2 failed, 6 passed in 0.15s
```

Both zone N rows fail, 3090 against 2990 and 7140 against 7040, and the other six pass. **The test
cannot know which side is right.** Maybe the price change was intended and the table must be
updated; maybe the code changed by accident. What the test guarantees is that the two cannot drift
apart silently: whoever changes one has to look at the other, in the same pull request, where a
reviewer sees both.

That is the general property of tests against stored expected output, often called **golden
files** or **snapshots**: the expected values are data, kept beside the code, and a change to
behaviour shows up as a diff to review. The danger is the habit of regenerating them automatically
whenever they fail. A snapshot accepted without reading checks nothing; it records whatever the
code does today and calls it correct.

## The rows to choose

The CSV is short on purpose. Its eight rows include one per zone that matters, a weight that
crosses several bands (2600 g, five extra bands), the largest weight in the table and the
free-shipping edge. A table with five hundred rows of ordinary cases adds run time and review time
and catches nothing the eight do not; the edges of lesson 1 section 13 are what earn a row.
