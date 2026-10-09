---
title: The incremental load
version: 1
---

**An incremental extraction reads only the rows that changed since the last run.** It needs the
source to say when each row changed, and the shop does: every table carries `updated_at`, which
the tills and the back office set whenever they write a row. A sale sets it when the order is
placed; a refund sets it again when the status changes.

So the question each night becomes: *which rows have an `updated_at` later than the last time I
looked?* The first night there was no last time, and everything comes:

```
ana@vm:~/etl$ python incremental.py customers
shop.customers: 5098 rows, the first run, watermark now 03-01 22:21:41
ana@vm:~/etl$ python incremental.py orders
shop.orders: 17195 rows, the first run, watermark now 03-01 23:50:30
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 17195 rows, the first run, watermark now 03-01 23:50:30
```

(The third line, with `60` on the end, is a second copy of the same extraction with a setting the
section after next explains. Read past it for now.)

The next night `shop` plays 2 March, and the extraction reads the day:

```
ana@vm:~/etl$ sudo shop day 2026-03-02
```

```
ana@vm:~/etl$ python incremental.py orders
shop.orders: 261 rows since 03-01 23:50:30, watermark now 03-02 23:59:47
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 265 rows since 03-01 23:50:30, watermark now 03-02 23:59:47
```

**261 rows instead of 17,453.** The 261 are the day's new orders and the earlier orders whose
status changed that day — both kinds have a new `updated_at`, and the extraction does not need to
know which kind each one is. The cost now grows with the change, not with the table: in five years
it is still two or three hundred rows a night.

## What it asks of the source

The whole method rests on one column, and on three promises about it that the source has to keep:

- **every write sets it** — an `UPDATE` that forgets to touch `updated_at` is a change no
  incremental pipeline will ever see;
- **it never goes backwards** for a row;
- **it is indexed**, or "the rows changed since yesterday" is a full scan in disguise. The shop has
  `orders_updated_at` for exactly this.

The first promise is the one that breaks. A developer fixes a typo in a customer's city by hand,
straight in the database, and does not think about `updated_at`; the warehouse keeps the typo for
ever. **Where the source's owner agrees, a trigger that sets `updated_at` on every write turns the
promise into a guarantee**. The lab's shop does not have one, which keeps its timestamps exactly where the day's file put them.
