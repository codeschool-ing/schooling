---
title: Data profiling and data quality scans
version: 1
---

**A pipeline that runs green can load nonsense.** The nightly job of lesson 24 checks that it ran, not
that the orders it loaded make sense: a column of totals that is suddenly 5% empty, an order id that
appears twice, a negative price. None of those fails a `LOAD` or a `SELECT`, and each of them reaches
a dashboard. Dataplex has two kinds of scan for this, and they answer different questions.

**A data profile scan describes a table**: for each column, the share of nulls, the number of
distinct values, the minimum and maximum, the commonest values, the average of a number. It passes no
judgement. **A data quality scan judges a table against rules**: each rule is a condition every row
should meet, with a threshold for the share of rows that must meet it, and the scan says pass or fail
per rule and for the whole. A profile is what you read before you know what the rules should be; the
rules are what runs every night afterwards.

## The rules, and the threshold that makes them practical

**A rule is evaluated per row and judged over all of them.** Dataplex offers a handful of built-in kinds. They are worth knowing by name, because they cover most of what anybody writes:

| rule | the condition on each row |
|---|---|
| non-null | the column has a value |
| range | the value is between a minimum and a maximum |
| set | the value is one of a list |
| regex | the value matches a pattern |
| uniqueness | no other row has the same value |
| row condition | a SQL expression over the row is true |
| table condition | a SQL expression over the whole table is true, such as a row count |

**Every rule carries a threshold**, the share of rows that must pass for the rule to pass, and
**the threshold is what turns a rule into something that can run every night**. A rule at 100% fails
on the first odd row, which is right for a key that must be unique and wrong for a phone number typed
by a customer. The scan also takes a **row filter**, and an **incremental** setting that judges only
rows newer than the last run, on a column the scan is told to watch.

## The same arithmetic, on your laptop

Dataplex runs its scans on BigQuery tables, and no emulator answers for either. **What follows is a
model of the idea, not Dataplex**: the same profile and the same four kinds of rule, computed by
DuckDB, the engine lesson 1 installed, on a CSV small enough to read whole. Save twenty of Quitanda's
orders as `orders.csv`:

```
order_id,customer_id,total_cents,phone
o-10001,c-40,1380,+55 11 94361-8085
o-10002,c-36,690,+55 11 93095-8819
o-10003,c-18,1290,+55 11 98038-4972
o-10004,c-40,,+55 11 94308-1471
o-10005,c-38,1380,+55 11 93362-3120
o-10006,c-23,23490,+55 11 97368-6968
o-10007,c-24,690,+55 11 91497-5808
o-10008,c-34,899,+55 11 99347-1718
o-10009,c-37,690,98607-6138
o-10010,c-27,4290,+55 11 98078-4288
o-10011,c-18,2790,+55 11 94233-7296
o-10012,c-30,1290,+55 11 91965-2628
o-10013,c-19,-500,+55 11 99928-9989
o-10014,c-39,690,+55 11 91770-7664
o-10014,c-39,690,+55 11 91770-7664
o-10015,c-23,3450,+55 11 92484-9907
o-10016,c-27,899,+55 11 97672-1737
o-10017,c-30,23490,+55 11 92226-1663
o-10018,c-28,899,+55 11 94926-2339
o-10019,c-23,1290,+55 11 98123-4567
```

And the program, `~/gcp/scan.py`:

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A data profile and a data quality check of one CSV, the way Dataplex scans compute them.\n\n    python3 scan.py profile orders.csv\n    python3 scan.py quality orders.csv\n\nA MODEL OF THE IDEA, NOT DATAPLEX: the same arithmetic, run by DuckDB on your laptop.\n\"\"\"\nimport sys\n\nimport duckdb\n\n", "note": "**The docstring's last line is the one that matters**: DuckDB does the arithmetic Dataplex's scans do, on a file instead of a BigQuery table."}, {"code": "mode, path = sys.argv[1], sys.argv[2]\ndb = duckdb.connect()\ndb.execute(f\"CREATE VIEW t AS SELECT * FROM read_csv('{path}', header=true)\")\nrows = db.execute('SELECT count(*) FROM t').fetchone()[0]\n\n", "note": "DuckDB reads the CSV as a view, `t`, and guesses each column's type from the values, so `total_cents` is a number and the empty one is a null."}, {"code": "if mode == 'profile':\n    print(f'{rows} rows')\n    for (col,) in db.execute(\"SELECT column_name FROM (DESCRIBE t)\").fetchall():\n        nulls, distinct, low, high = db.execute(\n            f'SELECT count(*) FILTER (WHERE \"{col}\" IS NULL), count(DISTINCT \"{col}\"), '\n            f'min(\"{col}\"), max(\"{col}\") FROM t').fetchone()\n        print(f'  {col:<12} null {nulls / rows:6.1%}  distinct {distinct:>3}  min {low}  max {high}')\n    sys.exit()\n\n", "note": "**The profile**: for each column, the share of nulls, the distinct count, the minimum and the maximum. A profile judges nothing; it only describes."}, {"code": "RULES = [\n    ('order_id is unique',       'order_id', 'count(*) OVER (PARTITION BY order_id) = 1', 1.00),\n    ('total_cents is not null',  'total_cents', 'total_cents IS NOT NULL', 1.00),\n    ('total_cents in 1..500000', 'total_cents', 'total_cents BETWEEN 1 AND 500000', 0.90),\n    ('phone looks Brazilian',    'phone', \"regexp_full_match(phone, '\\\\+55 11 9\\\\d{4}-\\\\d{4}')\", 0.95),\n]\n", "note": "**The rules**, each a name, a column, a condition on one row and a threshold. Uniqueness is a window: a row passes if its id appears once in the whole table. The phone pattern is São Paulo's mobile format, written as a regular expression."}, {"code": "failed = 0\nfor name, col, predicate, threshold in RULES:\n    passed = db.execute(f'SELECT count(*) FILTER (WHERE ok) FROM (SELECT {predicate} AS ok FROM t)').fetchone()[0]\n    ratio = passed / rows\n    verdict = 'PASS' if ratio >= threshold else 'FAIL'\n    failed += verdict == 'FAIL'\n    print(f'{verdict}  {name:<26} {passed}/{rows} = {ratio:.1%}, threshold {threshold:.0%}')\nprint(f'{len(RULES) - failed} of {len(RULES)} rules passed')\n", "note": "Each rule counts the rows whose condition is true, divides by all the rows, and passes if the share reaches the threshold. A null makes a condition neither true nor false, so it counts as a failure, which is also what Dataplex does unless a rule is told to ignore nulls."}]}
```

```
ana@laptop:~/gcp$ python3 scan.py profile orders.csv
20 rows
  order_id     null   0.0%  distinct  19  min o-10001  max o-10019
  customer_id  null   0.0%  distinct  13  min c-18  max c-40
  total_cents  null   5.0%  distinct   9  min -500  max 23490
  phone        null   0.0%  distinct  19  min +55 11 91497-5808  max 98607-6138
```

**The profile flags the problems without naming them.** `total_cents` is 5.0% null, one value in
twenty; its minimum is -500, which no price should be; `order_id` has 19 distinct values in 20 rows,
so one id repeats; and the largest `phone` sorts after every number that starts with `+`, which is
what a phone without its country code does. A person reading this writes the rules:

```
ana@laptop:~/gcp$ python3 scan.py quality orders.csv
FAIL  order_id is unique         18/20 = 90.0%, threshold 100%
FAIL  total_cents is not null    19/20 = 95.0%, threshold 100%
PASS  total_cents in 1..500000   18/20 = 90.0%, threshold 90%
PASS  phone looks Brazilian      19/20 = 95.0%, threshold 95%
2 of 4 rules passed
```

**Two rules failed and two passed, and the two that passed did so at exactly their threshold.**
The uniqueness rule found 18 of 20 rows unique, because the repeated `o-10014` makes two rows that
are not, and at a threshold of 100% that fails. The non-null rule found 19 of 20 and fails for the
same reason. The range rule passed at 90% because its threshold is 90%: the null total and the -500
both failed the condition, and two failures in twenty were allowed. **The phone rule passed at 95%
with one bad number in it.** That is the threshold doing what it was set to do, and it is also how a
slow decline goes unnoticed, which is why a scan's results are kept and compared from night to night,
not only read as pass or fail.

## What the real scans cost

**Both kinds of scan are billed as Dataplex premium processing**, in DCU-hours, a unit the page calls
abstract: what a scan consumes depends on the rows, the columns, the bytes it reads and the rules, and
the page gives no fixed figure per scan. From cloud.google.com/dataplex/pricing, read 2026-10-30, São
Paulo: **$0.141282 per DCU-hour** for premium processing, and $0.095246 for standard processing, the
tier that covers discovery. Billing is per second with a minimum of one minute per scan, and the
standard tier has 100 DCU-hours a month free, the premium tier none. If a nightly scan of Quitanda's
orders took half a DCU-hour, an assumption and not a figure from the page:

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.5 * 30 * 0.141282, 2))'
2.12
```

**About 2.12 dollars a month for one table scanned every night.** The levers the page names are the
same ones that make the scan cheaper anywhere: scan only new rows with the incremental setting,
filter rows, sample a percentage, and scan only the columns that have rules. A scan that reads a
whole partitioned table every night to judge one day of it pays for every day each time.
