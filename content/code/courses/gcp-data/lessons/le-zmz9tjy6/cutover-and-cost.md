---
title: The cutover, and what the changes cost
version: 1
---

**The cutover is the minute the applications stop writing to the old database and start writing to
the new one**, and everything before it exists to make that minute short and boring. With a
continuous migration running, the destination is seconds behind the source, so the downtime is not
the hours of the backfill but the time it takes to stop the writers, let the last changes cross,
check, and start the writers against the destination.

**The order is the part people get wrong**, and getting it wrong in either direction loses data:
switch the applications before the last changes have crossed and those changes are lost; let the
applications write to both and the two databases disagree.

1. **Run the job until it is quiet.** The backfill is finished, and the replication delay the job
   reports is a few seconds.
2. **Stop the writers on the source.** Put the shop into maintenance, or revoke the application
   user's right to write, so that nothing new reaches the old database.
3. **Wait for the last changes to cross**, until the delay reaches zero and the counts and totals of
   the important tables agree on both sides, the check lesson 23 made between Spark and DuckDB.
4. **Promote the destination** and point the applications at it.
5. **Keep the source read-only** for as long as a rollback might be wanted. The old database is the
   backup of the first day.
6. **Drop the replication slot on the source**, the warning of the practice section, once the job
   is gone for good. A slot left behind after a cutover is the classic way to fill a disk a month
   later, and the `lost` slot of that section is what `max_slot_wal_keep_size` makes of it instead.

For Quitanda's first project the destination is BigQuery rather than a new database, so there is no
application to move: the stream simply runs, and the cutover is the day the reports stop reading the
old PostgreSQL. The same order applies on the day the shop itself moves to Cloud SQL.

## What Datastream costs

**Datastream bills the gibibytes it processes, and nothing for a stream that is idle**, the pricing
page says, read on 2026-10-30. Change data capture is tiered per billing account and per month, and
in São Paulo the first 2,500 GiB cost $3.176 a GiB, the next 2,500 $2.382, the next 5,000 $1.906,
and everything above 10,000 GiB $1.27. Backfill costs $0.635 a GiB after 500 GiB free a month, which a note further down the same page
calls a one-time credit per billing account instead. **The
page's warning is the line to read twice**: the processed byte is Datastream's internal
representation of the data, and for most uses it is two to five times larger than the data itself.
Save the bill as `datastream_bill.py`:

```schooling-example
{"language": "python", "file": "datastream_bill.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, from cloud.google.com/datastream/pricing.\nCDC_TIERS = [(2500, 3.176), (2500, 2.382), (5000, 1.906), (None, 1.27)]  # GiB in the tier, USD a GiB\nBACKFILL_FREE, BACKFILL = 500, 0.635                                   # GiB a month, USD a GiB\n\n", "note": "**The page's two tables for São Paulo.** Change data capture is tiered by the GiB processed in a month, each tier charged only for what falls inside it; backfill is flat after 500 GiB free a month."}, {"code": "def cdc(gib):\n    usd = 0.0\n    for size, price in CDC_TIERS:\n        part = gib if size is None else min(gib, size)\n        usd += part * price\n        gib -= part\n        if gib <= 0:\n            break\n    return usd\n\ndef backfill(gib):\n    return max(0, gib - BACKFILL_FREE) * BACKFILL\n\n", "note": "A tiered price walked tier by tier: the first 2,500 GiB at the first rate, the next 2,500 at the second, and so on. A flat rate times the whole volume would overcharge every GiB past the first tier."}, {"code": "print(f'the page\\'s example, 600 GiB backfill and 3,000 GiB of changes: '\n      f'{backfill(600) + cdc(3000):.2f}')\n\n", "note": "The worked example on the pricing page, repriced at São Paulo's rates, to check the function against a case the page explains."}, {"code": "SHOP_GIB, CHANGES_GIB = 40, 30          # Quitanda's shop database, and a month of its changes\nfor factor in (2, 5):                   # the page: processed bytes are 2 to 5 times the data\n    print(f'Quitanda at {factor}x: backfill {backfill(SHOP_GIB * factor):.2f}, '\n          f'changes {cdc(CHANGES_GIB * factor):.2f} a month')\n", "note": "**Quitanda's own case, at both ends of the page's warning.** The page says the bytes Datastream counts are an internal representation, two to five times the size of the data for most uses, so the same database is priced at both factors."}]}
```

```
ana@laptop:~/gcp$ python3 datastream_bill.py
the page's example, 600 GiB backfill and 3,000 GiB of changes: 9194.50
Quitanda at 2x: backfill 0.00, changes 190.56 a month
Quitanda at 5x: backfill 0.00, changes 476.40 a month
```

**9194.50 for the page's own example**, a 600 GiB backfill and 3,000 GiB of changes, priced at São
Paulo's rates: 100 GiB of backfill at $0.635, 2,500 GiB of changes at $3.176 and 500 at $2.382. The
page computes the same case at Iowa's rates; the function walks the tiers the same way the page's
arithmetic does, which is the check that it is right.

**For Quitanda, the backfill is free and the changes are not.** A 40 GiB shop database is under 500
GiB of backfill even at five times its size. A month of 30 GiB of changes costs 190.56 if
Datastream counts them at twice their size and 476.40 at five times, and the program cannot say
which, because the factor depends on the data's types and on how often rows change. **The honest
plan is to run the stream for a week and read the processed bytes it reports**, then multiply, rather
than to quote either number to the business as the price.

**What this bill does not include is the destination.** Writing into BigQuery in merge mode means
BigQuery applying the changes to the tables, which its change data capture bills on BigQuery's own
page, and a `dataFreshness` of fifteen minutes is what keeps that bill small. A migration to Cloud
SQL bills the Cloud SQL instance from the day it is created. **The cost that matters most is not on
any page**: a cutover that goes wrong costs the shop's orders for however long it takes to notice,
and the order above, with the counts compared before the promote, is cheaper than any tier.
