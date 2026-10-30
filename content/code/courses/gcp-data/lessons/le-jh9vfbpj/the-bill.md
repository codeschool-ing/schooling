---
title: What it costs, against Cloud SQL
version: 1
---

**AlloyDB is billed for three things: the vCPUs and memory of every node, the storage the cluster
holds, and its backups.** There is no charge per read or per write, and no I/O line of any kind.
Cloud SQL, lesson 6, is billed for the vCPUs and memory of every instance and for the disk each one
was given. So comparing the two is comparing a higher rate for compute against a lower total for
storage, and which one wins depends on the shape of the database, not on the product.

**The rates, from the two pricing pages**, São Paulo, USD, list prices before any commitment, read on
2026-10-30 at cloud.google.com/alloydb/pricing and cloud.google.com/sql/pricing:

| | AlloyDB, N2 and C4A | Cloud SQL Enterprise |
|---|---|---|
| per vCPU-hour | 0.1051 | 0.062, or 0.1239 high-availability |
| per GiB of memory per hour | 0.01781 | 0.0105, or 0.021 high-availability |
| storage, per GiB-month | 0.476909, used, once per cluster | 0.255 SSD, or 0.51 high-availability, as provisioned, per instance |
| backups, per GiB-month | 0.158994 | 0.12 |

**AlloyDB's compute costs about 70% more per node**, and its storage per GiB is close to the
high-availability SSD of Cloud SQL. The numbers that decide it come from multiplying those rates by a
real shape, and a short program does it so that every figure can be checked.

## Quitanda's orders database, both ways

**The shape**: a primary of 8 vCPUs and 64 GiB with high availability, read capacity of two more
machines of the same size, and 500 GiB of data. On AlloyDB that is a regional primary and a read pool
of two nodes; on Cloud SQL, a high-availability instance and two read replicas.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Quitanda's orders database, priced as AlloyDB and as Cloud SQL Enterprise.\n\nUSD a month, southamerica-east1, list prices read on 2026-10-30 from\ncloud.google.com/alloydb/pricing and cloud.google.com/sql/pricing.\n\"\"\"\nHOURS = 730\n\n", "note": "The docstring says where every number below comes from, and when it was read. **730 hours** is the month both pricing pages use for their own monthly figures."}, {"code": "ALLOYDB = {'vcpu': 0.1051, 'gib': 0.01781, 'storage': 0.476909}\nCLOUDSQL = {'vcpu': 0.062, 'gib': 0.0105, 'ha_vcpu': 0.1239, 'ha_gib': 0.021,\n            'ssd': 0.255, 'ha_ssd': 0.51}\n\n", "note": "**The rates, copied from the pages.** AlloyDB's N2 and C4A price per vCPU-hour and per GiB-hour, and its regional storage per GiB-month. Cloud SQL Enterprise edition's general-purpose machines, with the separate rates the page lists for a high-availability instance, and its SSD storage per GiB-month, zonal and high-availability."}, {"code": "VCPU, GIB, DATA, READERS = 8, 64, 500, 2\n\n\ndef node(rates, vcpu='vcpu', gib='gib'):\n    return (VCPU * rates[vcpu] + GIB * rates[gib]) * HOURS\n\n", "note": "**The shape both are priced for**: machines of 8 vCPUs and 64 GiB, 500 GiB of data, and two machines' worth of read capacity beside the primary. `node` is one machine for a month at a given pair of rates."}, {"code": "alloydb = {\n    'primary, regional, 2 nodes': 2 * node(ALLOYDB),\n    'read pool, 2 nodes': READERS * node(ALLOYDB),\n    'storage, 500 GiB, once': DATA * ALLOYDB['storage'],\n}\n", "note": "**AlloyDB bills the regional primary as two nodes**, the active one and the standby, at the same rate as any node, and the storage once for the whole cluster."}, {"code": "cloudsql = {\n    'primary, high availability': node(CLOUDSQL, 'ha_vcpu', 'ha_gib'),\n    'two read replicas': READERS * node(CLOUDSQL),\n    'SSD, 500 GiB, primary': DATA * CLOUDSQL['ha_ssd'],\n    'SSD, 500 GiB, each replica': READERS * DATA * CLOUDSQL['ssd'],\n}\n\n", "note": "**Cloud SQL bills the high-availability primary at its own rates**, which already include the standby, and **storage per instance**: the primary's disk at the high-availability rate, and a full disk for each replica."}, {"code": "for name, bill in (('AlloyDB', alloydb), ('Cloud SQL Enterprise', cloudsql)):\n    print(name)\n    for line, usd in bill.items():\n        print(f'  {line:<30}{usd:>10,.2f}')\n    print(f'  {\"a month\":<30}{sum(bill.values()):>10,.2f}')\n", "note": "Each bill line by line, then its total. Nothing is rounded until it is printed."}]}
```

```
ana@laptop:~/gcp$ python3 compare.py
AlloyDB
  primary, regional, 2 nodes      2,891.73
  read pool, 2 nodes              2,891.73
  storage, 500 GiB, once            238.45
  a month                         6,021.92
Cloud SQL Enterprise
  primary, high availability      1,704.70
  two read replicas               1,705.28
  SSD, 500 GiB, primary             255.00
  SSD, 500 GiB, each replica        255.00
  a month                         3,919.98
```

**AlloyDB costs 2,101.94 more a month for the same machines**, 6,021.92 against 3,919.98, and the
lines say where. Compute is 5,783.46 on AlloyDB and 3,409.98 on Cloud SQL; storage is 238.45 against
510.00. The storage line is AlloyDB's advantage, and the compute line is larger.

**One node for an hour shows the gap at its smallest scale**:

```
ana@laptop:~/gcp$ python3 -c 'print(round(8 * 0.1051 + 64 * 0.01781, 5), round(8 * 0.062 + 64 * 0.0105, 5), round(8 * 0.1239 + 64 * 0.021, 5))'
1.98064 1.168 2.3352
```

**1.98064 against 1.168 for the same 8 vCPUs and 64 GiB.** That is the 70%, and a regional primary
pays it twice, for two nodes, while Cloud SQL's high-availability rate, 2.3352, is double its own
single rate too.

## Where the line falls

**Storage is the line AlloyDB wins on**, so the question is how much data closes the gap. Each GiB on
this shape costs AlloyDB 0.476909, once. On Cloud SQL the same GiB is on three disks, 0.51 on the
primary and 0.255 on each replica, 1.02 in all. The compute difference divided by the storage
difference per GiB is the amount of data at which the two bills meet:

```
ana@laptop:~/gcp$ python3 -c 'print(round((2 * 2891.73 - 1704.70 - 1705.28) / (0.51 + 2 * 0.255 - 0.476909)))'
4370
```

**About 4,370 GiB**, a little over 4 TiB, before AlloyDB's storage saving pays for its compute, on
these machines and these prices. Quitanda's 500 GiB is far below it. Three things move the line, and
each is a reason to do this arithmetic with your own numbers rather than to trust this one:

- **Every replica moves it down.** Each Cloud SQL replica brings another full disk, 0.255 a GiB, and
  each AlloyDB read node brings none; four replicas instead of two raise Cloud SQL's storage to 1.53 a
  GiB.
- **Provisioned is not used.** A Cloud SQL disk is sized above the data it holds, with room to grow,
  and it is billed at its size. A disk of 700 GiB holding 500 bills as 700, on the primary and on each
  replica; the program above gave Cloud SQL the benefit of the doubt by sizing it exactly.
- **Fewer, smaller nodes.** If the columnar engine lets the analysts' reports run on one read node
  instead of two, or a smaller one, the compute line shrinks by a node's worth, 1,445.87 a month at
  this size. That is a bet on a measurement nobody can take without a cluster, and it is the
  measurement to take on the free trial below before building on it.

**Three things are in neither bill.** Backups are priced in the table above and grow with what is
kept. Network traffic out of the region is lesson 5's subject, and the same for both. And Enterprise
Plus, Cloud SQL's other edition, has its own rates on the same page, a faster failover and a data
cache; it would narrow the gap from the other side. Committed use discounts
lower both, by the percentages on each page, for one or three years of commitment.

## The free trial, and what it is for

**AlloyDB offers a free trial cluster for 30 days**, which the pricing page describes as up to 1 TB of
data, an 8 vCPU primary and one 8 vCPU read pool node, in addition to the credit a new Google Cloud
account receives. That is the shape priced above, minus the high availability and one reader, and it
is enough to answer the one question this lesson could not: how much faster the analysts' report
runs on the columnar engine, with Quitanda's own data, and so how many nodes the real cluster needs.
**It was not used for this course**, which has no account, and nothing on this page was measured on
AlloyDB.
