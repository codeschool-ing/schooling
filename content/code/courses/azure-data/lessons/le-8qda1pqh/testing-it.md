---
title: Testing a transformation before it meets the night
version: 1
---

**A transformation written as code can be tested on four rows, on a laptop, in a second; a
transformation drawn as a data flow is tested by running it on a cluster.** That difference decides
more choices between the two than any other, and this section shows it. It runs on your computer and
needs no emulator, because the function under test touches no storage.

The four rows are chosen to break each rule once: an order sent twice, a payment in capitals with
spaces around it, a total with one decimal digit, `9,5`, and an order late in the evening. Save the
test beside `clean.py`:

`test_clean.py`:

```python
"""test_clean.py: the transformation's rules, checked on four rows, with no storage at all."""
import pyarrow as pa

from clean import clean

raw = pa.table({
    "order_id": ["1001-00002", "1001-00001", "1001-00001", "1001-00003"],
    "created_at": ["2026-10-01 07:18", "2026-10-01 07:04", "2026-10-01 07:04", "2026-10-01 21:59"],
    "customer_id": ["c-2", "c-1", "c-1", "c-3"],
    "neighbourhood": ["Moema", "Penha", "Penha", "Lapa"],
    "payment": [" PIX ", "credit", "credit", "Meal-Voucher"],
    "total": ["42,87", "9,5", "9,5", "1234,00"],
})
out = clean(raw).to_pylist()
assert [o["order_id"] for o in out] == ["1001-00001", "1001-00002", "1001-00003"], "one row per order"
assert [o["payment"] for o in out] == ["credit", "pix", "meal-voucher"], "payment in lower case"
assert [o["hour"] for o in out] == [7, 7, 21], "the hour of the order"
assert [o["total_cents"] for o in out] == [950, 4287, 123400], "totals in cents"
print("4 checks passed")
```

```
ana@laptop:~/azure$ python test_clean.py
4 checks passed
ana@laptop:~/azure$ sed -i "s/replace(total, ',', '.')/replace(total, ',', '')/" clean.py && python test_clean.py 2>&1 | tail -1; sed -i "s/replace(total, ',', '')/replace(total, ',', '.')/" clean.py
AssertionError: totals in cents
```

**The second command makes a mistake somebody could make on purpose**: removing the comma instead of
turning it into a point, which reads like a sensible shortcut. On every total with two decimal digits
it gives the right number, so the night's export, where the shop always writes two, would load without
a complaint. The fourth row is the one that catches it: `9,5` becomes `95` reais instead of `9.50`,
and the test names the rule it broke. The `sed` at the end puts the right line back.

## Why a data flow cannot do this

**A mapping data flow has a debug mode, and it runs on a cluster.** You switch it on in the editor,
Data Factory starts a Spark cluster for the session, and each transformation shows a preview of rows
as it is built. It is a good tool for looking at data, and it is billed while the session is on. What
it is not is a test: nothing in it runs again, on the same four rows, every time the data flow changes,
and fails the change when a rule breaks. A team can test a data flow by running the whole pipeline
against a small fixture in a development factory and comparing the output, which works and takes
minutes and a cluster each time.

**Code in a notebook can be tested the way this file is**, if it is written the way `clean.py` is:
the rules in functions, the storage at the edge. A notebook that reads, cleans and writes in one
long cell is as hard to test as a data flow, and the discipline that makes it testable is the
writer's, not the tool's. Notebooks in Fabric, Synapse and Databricks can all live in Git, and
`pipelines-etl` lesson 17 covers testing a pipeline in more depth than this course can.
