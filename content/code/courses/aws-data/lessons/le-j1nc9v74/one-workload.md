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
| data kept | 50 GB |
| latency | the screen opens in well under a second |

The prices of the three stores this section compares come from the sheet, with S3 and Redshift
beside them, which the other sections of this lesson quote:

```
ana@laptop:~/aws$ python3 prices.py s3 dynamodb aurora redshift athena
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month

Aurora PostgreSQL, USD
  db.r7g.large, Standard, per hour                      0.43884  hour
  db.r7g.large, I/O-Optimized, per hour                 0.57081  hour
  storage, Standard                                     0.19000  GB-month
  storage, I/O-Optimized                                0.42800  GB-month
  I/O, Standard, per million requests                   0.28000  million
  Serverless v2, per ACU-hour                           0.25000  ACU-hour

Redshift, USD
  ra3.large, per node-hour                              0.86600  hour
  ra3.xlplus, per node-hour                             1.73100  hour
  ra3.4xlarge, per node-hour                            5.19500  hour
  managed storage                                       0.04300  GB-month
  Serverless, per RPU-hour                              0.59760  RPU-hour
  Spectrum, per TB scanned                              5.00000  TB

Athena, USD
  SQL queries, per TB scanned                           9.00000  TB
```

## DynamoDB

**The table's partition key is the customer and its sort key the order date**, the design lesson 9
taught, so a lookup is one `Query` reading under 4 KB: one read request unit when strongly consistent.
A new order is one write under 1 KB: one write request unit.

| on demand, one month | arithmetic | USD |
|---|---|---|
| reads | 3,000,000 × 0.18750 ÷ 1,000,000 | 0.56 |
| writes | 600,000 × 0.93750 ÷ 1,000,000 | 0.56 |
| storage beyond 25 GB | (50 − 25) × 0.37500 | 9.38 |
| **total** | | **10.50** |

**Ten dollars and a half a month, and storage is nine of them.** The requests are cheap because each
one touches one key, which is the access pattern DynamoDB prices for.

## Aurora PostgreSQL

**The same workload as a table with an index on the customer and the date** is one indexed query per
lookup, served in milliseconds from memory once the working set is warm. The price is the instance,
whatever the number of lookups.

| Standard, one month | arithmetic | USD |
|---|---|---|
| one db.r7g.large | 0.43884 × 730 | 320.35 |
| storage | 50 × 0.19000 | 9.50 |
| I/O, if 30 million reads a month miss the cache | 30 × 0.28000 | 8.40 |
| **total** | | **338.25** |

**Thirty-two times DynamoDB's bill, for a workload that uses a sliver of the machine**, and a writer
with no standby, which lesson 7 would not accept for anything the business depends on. But the
comparison has a second half. **If Quitanda's orders already live in Aurora**, as the previous section
decided they do, the "my orders" screen is one more query on a machine that is paid for anyway, and
its marginal cost is close to nothing. The cheapest store for a workload is often the one already
running for the workload next to it.

## Athena

**Athena is the store that should not be in this comparison**, and pricing it shows why. Every lookup
would be a query, and Athena bills every query for at least 10 MB scanned, however little it reads.

| one month | arithmetic | USD |
|---|---|---|
| 3,000,000 queries at the 10 MB minimum | 3,000,000 × 10 MB = 30 TB × 9.00 | 270.00 |

**270.00 a month at the very least, and each lookup takes seconds**, because a query is planned,
queued and run over files before it answers. A customer does not wait seconds for a screen. The price
alone would have made Athena look close to Aurora; the second question, latency, rules it out before
the price is read, which is the order the first section of this lesson insisted on.

## What the three numbers say

| store | a month | what it says |
|---|---|---|
| DynamoDB | 10.50 | the access pattern is the one it is built for |
| Aurora | 338.25 alone, near zero beside the orders | the instance is the price, and it may already be paid |
| Athena | 270.00 at least, and too slow | a lake engine asked to be a database |

**Neither DynamoDB nor Aurora is "the answer" from these numbers alone.** A team starting from
nothing would put "my orders" in DynamoDB; a team whose orders are already in Aurora would add an
index and pay nothing more. Both are right for their situation, and both read the same three numbers.
