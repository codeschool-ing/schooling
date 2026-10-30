---
title: One workload, priced in three stores
version: 1
---

**The "my orders" screen of Quitanda's app is a workload with a clear shape**: a customer opens it,
and the app shows their recent orders, newest first. It is read by one key, the customer, and a range
under it, the order dates. Put numbers on it before choosing:

| | |
|---|---|
| lookups | 100,000 a day, 3,000,000 a month |
| each lookup returns | up to ten orders, under 4 KB in all |
| new orders | 20,000 a day, 600,000 a month, each under 1 KB |
| data kept | 50 GiB |
| latency | the screen opens in well under a second |

Three stores of this course could hold it: Firestore, a document per order under the customer;
Cloud SQL, a table with an index on the customer and the date; and BigQuery, the warehouse the
orders already reach. The program below prices all three with the São Paulo prices the earlier
lessons read:

```schooling-example
{"language": "python", "file": "my_orders.py", "parts": [{"code": "# Quitanda's \"my orders\" screen, priced in three stores.\n# Prices: southamerica-east1, USD, read 2026-10-30 from cloud.google.com.\nLOOKUPS = 3_000_000          # a month\nORDERS_PER_LOOKUP = 10\nNEW_ORDERS = 600_000         # a month\nGIB = 50                     # data kept\nHOURS = 730                  # a month\n\n", "note": "The workload, written down before any store is named. Every number below is one of these multiplied by a price, which is the order of the six questions."}, {"code": "def firestore():\n    reads = LOOKUPS * ORDERS_PER_LOOKUP * 0.045 / 100_000\n    writes = NEW_ORDERS * 0.135 / 100_000\n    stored = GIB * 0.135\n    return {'document reads': reads, 'document writes': writes, 'storage': stored}\n\n", "note": "**Firestore bills every document a query returns**, so a lookup of ten orders is ten reads, at $0.045 per 100,000. Writes are $0.135 per 100,000 and storage $0.135 per GiB-month, from cloud.google.com/firestore/pricing. The daily free quota is left out: it belongs to one database per project, and a business outgrows it."}, {"code": "def cloud_sql():\n    machine = (2 * 0.1239 + 8 * 0.021) * HOURS\n    disk = GIB * 0.51\n    return {'2 vCPU, 8 GiB, regional HA': machine, 'SSD, HA': disk}\n\n", "note": "**Cloud SQL bills the machine by the hour, whatever it does.** Enterprise edition with high availability, $0.1239 per vCPU-hour and $0.021 per GiB-hour of memory, and SSD at $0.51 per GiB-month with HA, the prices of lesson 6. The number of lookups does not appear at all."}, {"code": "def bigquery():\n    mib = LOOKUPS * 10                      # each query billed at least 10 MB\n    tib = mib / 1024 / 1024\n    return {f'{tib:.2f} TiB scanned, first TiB free': (tib - 1) * 11.25}\n\n", "note": "**BigQuery on demand bills each query for at least 10 MB per table it references**, however few rows it returns, at $11.25 per TiB in São Paulo after a free TiB a month, from cloud.google.com/bigquery/pricing. Three million tiny queries are a lot of minimums."}, {"code": "for name, lines in (('Firestore', firestore()), ('Cloud SQL', cloud_sql()), ('BigQuery', bigquery())):\n    print(name)\n    for what, usd in lines.items():\n        print(f'  {what:34} {usd:9.2f}')\n    print(f'  {\"total a month\":34} {sum(lines.values()):9.2f}')\n", "note": "One block per store, every line labelled, and the total. The output is the next table's source."}]}
```

```
ana@laptop:~/gcp$ python3 my_orders.py
Firestore
  document reads                         13.50
  document writes                         0.81
  storage                                 6.75
  total a month                          21.06
Cloud SQL
  2 vCPU, 8 GiB, regional HA            303.53
  SSD, HA                                25.50
  total a month                         329.03
BigQuery
  28.61 TiB scanned, first TiB free     310.62
  total a month                         310.62
```

## Firestore

**Thirteen dollars and a half of the twenty-one is reads**, because Firestore counts documents, not
queries: a screen of ten orders is ten reads. That is the access pattern it is priced for, and it
says something useful about the design. A screen that showed only the last order would cost a tenth
as much in reads, and a document per customer holding their last ten orders would make every lookup
one read, at the price of rewriting that document on every new order. In Firestore the shape of the
document is a line on the bill.

## Cloud SQL

**About fifteen times Firestore's bill, for a workload that uses a sliver of the machine.** The
instance is the price, with a standby in a second zone because lesson 7 would accept nothing less for
data the business depends on, and the price does not move whether the screen is opened three million
times or three. But the comparison has a second half. **If Quitanda's orders already live in Cloud
SQL**, as the previous section decided they do, the "my orders" screen is one more indexed
query on a machine that is paid for anyway, and its marginal cost is close to nothing. The cheapest
store for a workload is often the one already running for the workload next to it.

## BigQuery

**BigQuery is the store that should not be in this comparison**, and pricing it shows why. Every
lookup would be a query, and every query is billed for at least 10 MB per table it references,
however few rows it reads. Three million minimums are almost twenty-nine tebibytes a month of bytes
nobody read. And each lookup takes a second or more, because a query is a job that is planned,
given slots and run before it answers. A customer does not wait that long for a screen. The price
alone would have put BigQuery level with Cloud SQL; the second question, latency, rules it out before
the price is read, which is the order the first section of this lesson insisted on.

## What the three numbers say

| store | a month | what it says |
|---|---|---|
| Firestore | about 21 | the access pattern is the one it is priced for |
| Cloud SQL | about 329 alone, near zero beside the orders | the instance is the price, and it may already be paid |
| BigQuery | about 311, and too slow | a warehouse asked to be a database |

**Neither Firestore nor Cloud SQL is "the answer" from these numbers alone.** A team starting from
nothing would put "my orders" in Firestore; a team whose orders are already in Cloud SQL would add an
index and pay nothing more. Both are right for their situation, and both read the same three numbers.
