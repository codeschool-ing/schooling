---
title: Where the cost moves
version: 1
---

Both versions took under a quarter of a second, so speed is not what separates them here. **What
separates them is what each one moved, and what each one can still do afterwards.**

What each left in the warehouse:

```
ana@vm:~/etl$ psql -d wh -c "SELECT relname, n_live_tup AS rows, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_stat_user_tables ORDER BY relname"
        relname        | rows |  size  
-----------------------+------+--------
 books                 | 1200 | 168 kB
 elt_sales_by_category |   98 | 16 kB
 etl_sales_by_category |   98 | 16 kB
 order_lines           | 3048 | 224 kB
 orders                | 1933 | 152 kB
(5 rows)
```

The ETL table holds 98 rows in 16 kB. To give the same answer, the ELT version copied 1,933 orders,
3,048 lines and all 1,200 books — 6,181 rows and 544 kB, thirty-four times the space, before it
answered anything. At a week of a small shop that is nothing. At five years of a large one it is
the warehouse bill, and lesson 19 puts a price on it.

## What the raw rows buy

On Thursday the buyer asks a question nobody planned for: **which publishers sold the most books
that week?** The ETL table cannot answer it. It holds categories, and the publisher was thrown away
in Python on the way in. Answering means changing `etl.py`, extracting the week again from the
shop, and hoping the shop still says what it said on Sunday.

The raw layer already has everything the shop had, so the answer is one query, today, with no
visit to the source:

```
ana@vm:~/etl$ psql -d wh -c "SELECT b.publisher, sum(l.quantity) AS books FROM raw.orders o JOIN raw.order_lines l USING (order_id) JOIN raw.books b USING (book_id) WHERE o.status = 'completed' GROUP BY 1 ORDER BY 2 DESC LIMIT 3"
 publisher | books 
-----------+-------
 Maré      |   543
 Farol     |   315
 Granito   |   290
(3 rows)
```

**That is the argument that won.** ELT spends storage, which got cheap, to buy the ability to
answer tomorrow's question from yesterday's extraction, which stayed valuable. Columnar warehouses
that charge for storage by the terabyte-month and run SQL on as many machines as you pay for made
the trade easy, and it is why most new pipelines load first.

## What ETL still saves

- **The source's time.** Both versions read the source once. But each new question in ETL means
  reading it again, and the source is the system the tills depend on.
- **The warehouse's time.** ELT's transformation runs on the warehouse, competing with the people
  reading it. A heavy transformation at nine in the morning is a slow dashboard.
- **Exposure.** Every column copied raw is a column the warehouse now holds, and must protect,
  and must erase when somebody asks. That one is the subject of the last section.
