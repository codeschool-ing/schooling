---
title: The storage bill, and the two choices that set it
version: 1
---

**BigQuery bills storage at one of four rates, and two independent choices pick the rate.** The
first is not yours to make: a table or a partition that has gone 90 days without being modified
drops to the **long-term** rate on its own, and goes back to **active** the moment it is written to.
The second is yours, once per dataset: whether the bill counts the **logical** bytes of the last
section, or the **physical** bytes BigQuery actually stores after compression. These are the four
rates for São Paulo, from `cloud.google.com/bigquery/pricing`, read on 2026-10-30:

| southamerica-east1, USD per GiB-month | active | long-term |
|---|---|---|
| **logical** bytes | 0.023 | 0.016 |
| **physical** bytes | 0.07 | 0.035 |

**The first 10 GiB of storage each month is free**, the page says, and Quitanda's orders weigh
0.092 GiB. So the table this lesson built costs nothing to store, and would still cost nothing with
three years of the same orders in it, which comes to about 1.7 GiB at 0.092 for every sixty days. The
bill for orders is the query bill. The storage bill begins to matter with the data that is large by
nature, such as the app's click stream, which arrives through Pub/Sub in lesson 19, and the arithmetic below is done on
a round 1 TiB so the rates are easy to compare.

## Active and long-term

**Long-term is the same storage, at about half the price.** The page is explicit that nothing else
changes: "There is no difference in performance, durability, or availability between active and
long-term storage." What decides it is whether the data was modified in the last 90 consecutive
days, and the page lists what counts as modifying: a load or a query that writes into the table, a
copy into it, a DML statement, a `CREATE OR REPLACE TABLE`, streaming rows into it. Querying the table
does not reset the clock, and neither does exporting it, creating a view over it or copying it
somewhere else.

**Each partition of a partitioned table is counted separately**, and that one sentence of the page is
worth more than anything else in this section. A table of orders partitioned by day, as lesson 15
builds, receives a new partition every night and never touches last year's. After three years, the
last 90 partitions are active and the other thousand or so are long-term, about nine bytes in ten.
**The same orders in one unpartitioned table are entirely active**, because every nightly load
modifies the table, and with it the 90-day clock of every row in it.

## Logical and physical

**Logical billing counts the uncompressed size; physical billing counts what is actually stored, at
three times the rate.** At 0.023 against 0.07, physical billing is cheaper only for data that
compresses by more than 0.07 ÷ 0.023 = 3.04, and for long-term data by more than 0.035 ÷ 0.016 =
2.19. The Parquet files of the last section came out at 3.06. Nobody can tell from that whether
BigQuery's own format would do better or worse, and that is the honest position: the choice depends
on a ratio this lab cannot measure, and that BigQuery reports for every table in its
`INFORMATION_SCHEMA.TABLE_STORAGE` view, which is where the decision is made on a real project.

**Physical billing also charges for time travel and fail-safe.** **Time travel** is BigQuery keeping
the previous versions of a table's data, so that a query written `FOR SYSTEM_TIME AS OF` an earlier
moment can read the table as it was, and a table deleted by mistake can be brought back. Google's
documentation, "Data retention with time travel and fail-safe", gives the window as seven days by
default, configurable per dataset down to two. **Fail-safe** is a further seven days after that, in
which the data can only be recovered by Google's support, not by you. The pricing page says it in
one sentence: "There are no charges for time travel and failsafe storage for logical storage. Time
travel and failsafe storage charges apply for physical storage." So a table that is rewritten every
night carries, under physical billing, the bytes it replaced for up to fourteen days, and pays for
them at the active rate.

## The arithmetic, as a program

**Three numbers decide the bill**: the logical size, the compression ratio, and the share of the
bytes that are long-term. A fourth, the physical bytes kept for time travel and fail-safe, applies
only to the physical model. Save this as `~/gcp/storage.py`:

`storage.py`:

```python
import sys

PRICE = {  # USD per GiB-month, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30
    'logical': {'active': 0.023, 'long-term': 0.016},
    'physical': {'active': 0.07, 'long-term': 0.035},
}

logical_gib, ratio, long_term = (float(a) for a in sys.argv[1:4])
kept_gib = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0


def month(model, gib, extra=0.0):
    rate = PRICE[model]
    return (gib * (1 - long_term) + extra) * rate['active'] + gib * long_term * rate['long-term']


physical_gib = logical_gib / ratio
print(f'logical  {logical_gib:9,.1f} GiB  {month("logical", logical_gib):8,.2f} USD a month')
print(f'physical {physical_gib:9,.1f} GiB  {month("physical", physical_gib, kept_gib):8,.2f} USD a month')
```

**It leaves out the free 10 GiB**, which is the same few cents under either model, and it takes the
compression ratio as given, since that is the number nobody here can measure. Three cases, for 1 TiB
of logical bytes compressing three to one:

```
ana@laptop:~/gcp$ python3 storage.py 1024 3 0
logical    1,024.0 GiB     23.55 USD a month
physical     341.3 GiB     23.89 USD a month
ana@laptop:~/gcp$ python3 storage.py 1024 3 0.9
logical    1,024.0 GiB     17.10 USD a month
physical     341.3 GiB     13.14 USD a month
ana@laptop:~/gcp$ python3 storage.py 1024 3 0.9 20
logical    1,024.0 GiB     17.10 USD a month
physical     341.3 GiB     14.54 USD a month
```

**All active, the two models cost almost the same**, 23.55 against 23.89, because three to one is
just below the 3.04 where they cross. **Nine tenths long-term, physical is cheaper by a quarter**,
13.14 against 17.10, because the long-term line crosses at 2.19 and three is well above it. **Twenty
GiB of replaced data kept for time travel and fail-safe** adds 20 × 0.07 = 1.40 to the physical bill
and nothing to the logical one. A table that is rewritten every night would keep far more than that,
and could make physical billing the dearer of the two.

**The model is chosen per dataset, and not lightly.** On a real project it is one statement, shown
here and not run:

```sql
ALTER SCHEMA quitanda SET OPTIONS (storage_billing_model = 'PHYSICAL');
```

Google's documentation on the storage billing models says that once a dataset's model has been
changed, it cannot be changed again for 14 days, so it is not a switch to flip every month as the
numbers move.

## Compute is the other bill

**Not one line of this section depends on how often the table is queried.** A table read a thousand
times a day costs the same to store as one nobody reads, and a table that is free to store, like
Quitanda's orders, can still cost a fortune to query. Compare the rate for Cloud Storage's Standard
class in the same region, 0.035 USD per GiB-month on `cloud.google.com/storage/pricing`, read on the
same day: the files in the bucket cost more per GiB than the active logical rate of the table they
were loaded into, and less than its physical one. The query bill is the second meter, and it is the
next lesson.
