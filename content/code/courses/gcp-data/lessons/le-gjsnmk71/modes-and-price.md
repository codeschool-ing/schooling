---
title: Native or Datastore mode, and a bill per operation
version: 1
---

**A Firestore database is created in one of two modes, Native or Datastore, and the choice is made
once.** Native mode is the one this lesson has used: documents, collections, subcollections, the
client libraries of Firebase for phones and browsers, real-time listeners that push changes to an app,
and security rules that let those clients read the database directly. Datastore mode is the older
Cloud Datastore's API on Firestore's storage: entities, kinds and ancestors, the
`google-cloud-datastore` library, for servers only, with none of the mobile and listener features.

**The wrong idea is that Datastore mode is the legacy you avoid.** It is the right mode for a database
only servers touch, and Google's guide to choosing a mode describes it for server projects; what it lacks, the
listeners and the mobile SDKs, is exactly what a back end never uses. Quitanda's app reads order history
straight from the phone and listens for the delivery status of an order in progress, which is Native
mode's job. A back-office service with no app would be just as well served by Datastore mode.

| | Native mode | Datastore mode |
|---|---|---|
| unit | document, in a collection | entity, of a kind |
| hierarchy | subcollections | ancestor paths, entity groups |
| clients | server libraries, and Firebase for mobile and web | server libraries only |
| real-time listeners and offline clients | yes | no |
| indexes | single-field automatic, composite declared | built-in automatic, composite declared |
| in the emulator | the default, `--database-mode` not needed | `--database-mode=datastore-mode` |

**Firestore also has two editions now, Standard and Enterprise**, which the emulator's help lists as
values of `--edition`. This lesson's pricing is the Standard edition's: the page read for it says so in
its first line and points at a separate page for Enterprise, whose prices are therefore not given
here.

## A bill per operation

**Firestore Standard is billed for what is done, not for what is running**: document reads, writes and
deletes, each per 100,000, and storage per GiB-month, with a free quota every day. There is no
instance, no node and nothing to size. From cloud.google.com/firestore/pricing, read on 2026-10-30,
`southamerica-east1`, USD:

| | free per day | beyond it |
|---|---|---|
| document reads | 50,000 | 0.045 per 100,000 |
| document writes | 20,000 | 0.135 per 100,000 |
| document deletes | 20,000 | 0.015 per 100,000 |
| stored data | 1 GiB | 0.135 per GiB-month |

**The free quota is per project, for one database**: the page says it applies to the `(default)`
database only, and a named database pays from the first read. A query is billed a read per document it
returns, and at least one read even when it returns nothing; index entries are not billed for a query
with at most one range field, and are billed one read per 1,000 for a query with more.

`price.py`:

```python
"""Firestore Standard edition, southamerica-east1, USD, list prices read on
2026-10-30 from cloud.google.com/firestore/pricing. The free quota is per day."""
PER_100K = {'reads': 0.045, 'writes': 0.135, 'deletes': 0.015}
FREE_PER_DAY = {'reads': 50_000, 'writes': 20_000, 'deletes': 20_000}
STORAGE_GIB_MONTH, FREE_GIB = 0.135, 1


def month(per_day, gib, days=30):
    usd = {op: max(0, n - FREE_PER_DAY[op]) * days / 100_000 * PER_100K[op] for op, n in per_day.items()}
    usd['storage'] = max(0, gib - FREE_GIB) * STORAGE_GIB_MONTH
    return usd


app = month({'reads': 400_000, 'writes': 6_000, 'deletes': 0}, gib=2)
report = month({'reads': 400_000 + 1_800_000, 'writes': 6_000, 'deletes': 0}, gib=2)
for name, bill in (('the app', app), ('the app and a nightly full read', report)):
    lines = ', '.join(f'{k} {v:,.2f}' for k, v in bill.items())
    print(f'{name:<32} {sum(bill.values()):>8,.2f}   ({lines})')
```

```
ana@laptop:~/gcp$ python3 price.py
the app                              4.86   (reads 4.72, writes 0.00, deletes 0.00, storage 0.14)
the app and a nightly full read     29.16   (reads 29.02, writes 0.00, deletes 0.00, storage 0.14)
```

**The app costs 4.86 a month**: 400,000 reads a day, every customer opening their order history, of
which 350,000 are beyond the free quota, 10.5 million a month at 0.045 per 100,000; 6,000 writes a
day, inside the free 20,000; and 2 GiB of documents and their index entries, 1 of them free. **A
nightly report that reads all 1.8 million orders multiplies that by six**, to 29.16, for one query that
reads every document once a day. That is the shape of a Firestore bill: almost nothing for an app that
reads what it shows, and a line that grows with every document a careless query touches. A report
across everything belongs in the warehouse of lesson 13, where reading everything is what the bill is
designed for.

**A screen can be priced before it is built**, because its reads are countable. The order history
shows twenty orders: twenty reads per visit. If it listens for changes instead of reading once, each
order that changes while the screen is open is another read, and the pricing page says a listener that
reconnects after more than 30 minutes offline is billed as a brand-new query. A search box that runs a
query on every key pressed is a query per letter, each billed at least one read even when it returns
nothing. None of these is expensive at Quitanda's size; each of them is a multiplier, and the bill is
the product of the multipliers.

**And the emulator charges nothing and counts nothing.** Neither the reads a query billed nor the index
entries it read were visible in this lesson, because the emulator does not produce Query Explain's
metrics. On Google Cloud they are the input to this arithmetic, alongside the console's usage page;
here, the arithmetic is done from the pricing page and the queries you can count by hand.
