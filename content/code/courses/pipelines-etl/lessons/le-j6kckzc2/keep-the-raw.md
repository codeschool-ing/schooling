---
title: Keep the raw rows, and say what you saw
version: 1
---

Sunday night Ana sends the first week's report. She keeps a copy of the table she sent it from:

```
ana@vm:~/etl$ psql -d wh -c "CREATE TABLE sent_report AS SELECT * FROM etl_sales_by_category"
SELECT 98
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM sent_report"
 books | revenue_cents 
-------+---------------
  3278 |      21941220
(1 row)
```

**On Thursday an auditor asks her to reproduce that number.** Four more days of trade have
happened. She reruns the ETL for the same week:

```
ana@vm:~/etl$ sudo shop until 2026-03-11
ana@vm:~/etl$ python etl.py 2026-03-01 2026-03-07
read 3048 rows from the shop, wrote 98 to the warehouse
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM etl_sales_by_category WHERE day <= '2026-03-07'"
 books | revenue_cents 
-------+---------------
  3252 |      21764780
(1 row)
```

Twenty-six books and R$ 1,764.40 have vanished from a week that ended four days ago. Nobody lost
anything: between Sunday and Thursday the back office refunded and cancelled some of the first
week's orders, and `etl.py` asks the shop what it says *now*. **The ETL pipeline cannot reproduce
its own report**, because the thing it read no longer exists in the form it read it.

The ELT pipeline can. The raw tables hold the rows as they were extracted on Sunday, and
rebuilding the answer from them gives Sunday's number exactly:

```
ana@vm:~/etl$ psql -d wh -f sales_by_category.sql
DROP TABLE
SELECT 98
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM elt_sales_by_category"
 books | revenue_cents 
-------+---------------
  3278 |      21941220
(1 row)
```

## Two different questions, both legitimate

The two numbers are not one right and one wrong. They answer different questions:

- **3,278 books** is *what the pipeline saw on Sunday*. It is what the report said, and what
  decisions were made on. An audit needs it.
- **3,252 books** is *what the shop now believes about that week*, refunds included. Finance
  needs it.

A warehouse that holds only one of them will one day be asked for the other. **The raw layer is how
you keep the first**, and lessons 4 and 5 are how you find the changes that make the second, so
that the warehouse can say both and say which is which.

Three habits follow, whichever shape a pipeline has:

- Keep what was extracted, unchanged, for as long as somebody might ask about it.
- Record when it was extracted. These raw tables do not, and lesson 4 adds the column.
- Never "fix" a raw row. Fix the transformation and rebuild from the raw rows instead; that is what
  they are for.
