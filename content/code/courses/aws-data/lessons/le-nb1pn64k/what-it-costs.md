---
title: What an instance costs in a month
version: 1
---

**An RDS instance is billed for two things that run all the time and one that grows**: the instance,
by the hour, whether anybody queries it or not; the storage, by the GiB allocated, whether it is full
or not; and the backups, beyond an allowance. There is no charge per query and no charge per row,
which is the opposite of the services in lessons 9 and 15, and it means an idle database costs
exactly what a busy one costs. The price sheet's RDS block:

```
ana@laptop:~/aws$ python3 prices.py rds
AWS public price list, sa-east-1, USD, excluding tax

RDS, USD per hour
  PostgreSQL, db.m7g.large, Single-AZ                   0.22100  hour
  MySQL, db.m7g.large, Single-AZ                        0.22100  hour
  MariaDB, db.m7g.large, Single-AZ                      0.22100  hour
  PostgreSQL, db.m7g.large, Multi-AZ                    0.44200  hour
  PostgreSQL, db.t4g.micro, Single-AZ                   0.03400  hour
  SQL Server Standard, db.m6i.large, licence in         1.08700  hour

RDS storage and backup, USD per GB-month
  gp3, Single-AZ                                        0.21900  GB-month
  gp3, Multi-AZ                                         0.43800  GB-month
  backup beyond the free allowance                      0.09500  GB-month
```

## A month is 730 hours

AWS bills by the hour and the price sheet quotes by the hour, and the month this course uses is the
one AWS uses in its own calculator: 365 days times 24 hours divided by 12 months, 730 hours. Four
instances Quitanda could run, priced from the lines above:

| instance | engine | instance per month | gp3 storage per month | total |
|---|---|---|---|---|
| `db.t4g.micro`, 20 GiB | PostgreSQL | 0.034 × 730 = 24.82 | 20 × 0.219 = 4.38 | **29.20** |
| `db.m7g.large`, 100 GiB | PostgreSQL | 0.221 × 730 = 161.33 | 100 × 0.219 = 21.90 | **183.23** |
| `db.m7g.large` Multi-AZ, 100 GiB | PostgreSQL | 0.442 × 730 = 322.66 | 100 × 0.438 = 43.80 | **366.46** |
| `db.m6i.large`, 100 GiB | SQL Server Standard | 1.087 × 730 = 793.51 | 100 × 0.219 = 21.90 | **815.41** |

**The micro is for development, and nothing else.** Two burstable vCPUs and 1 GiB of memory are
enough to run the migrations and the tests against a real engine, and 29.20 a month is less
than the time anybody would spend arguing about it. It is not where Quitanda's orders live.

**PostgreSQL, MySQL and MariaDB cost the same on the same machine**: 0.221 an hour each for a
`db.m7g.large`. The engine is free and what is priced is AWS's work, which is the same for the three.
So among the open-source engines the choice is about the database and never about the price.

**Multi-AZ is exactly double**, the instance and the storage both, because it is a second instance with
a second volume in another zone, kept in step with the first. Lesson 7 is what the second copy buys.

**The licence is most of the SQL Server bill.** A `db.m6i.large` has the same 2 vCPU and 8 GiB as the
`db.m7g.large`, and costs 1.087 an hour against 0.221: 4.9 times as much, and the difference is
Microsoft's licence, which RDS includes and charges by the hour. A company with SQL Server in its
cupboard pays that difference every month it stays, which is the strongest commercial argument for
moving an engine rather than only a server.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Monthly cost of four RDS instances in São Paulo, 730 hours, split into instance and gp3 storage. db.t4g.micro PostgreSQL with 20 GiB: 24.82 plus 4.38, 29.20. db.m7g.large PostgreSQL with 100 GiB: 161.33 plus 21.90, 183.23. The same Multi-AZ: 322.66 plus 43.80, 366.46. db.m6i.large SQL Server Standard with the licence included and 100 GiB: 793.51 plus 21.90, 815.41.\" data-fig=\"l06-monthly\"><defs><marker id=\"arr-l06-monthly\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"220.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.t4g.micro</text><text x=\"220.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL, 20 GiB</text><rect x=\"230.0\" y=\"40.0\" width=\"12.8\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"242.8\" y=\"40.0\" width=\"2.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"253.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">29.20</text><text x=\"220.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m7g.large</text><text x=\"220.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL, 100 GiB</text><rect x=\"230.0\" y=\"90.0\" width=\"83.1\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"313.1\" y=\"90.0\" width=\"11.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"332.4\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">183.23</text><text x=\"220.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m7g.large</text><text x=\"220.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL Multi-AZ, 100 GiB</text><rect x=\"230.0\" y=\"140.0\" width=\"166.2\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"396.2\" y=\"140.0\" width=\"22.6\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"426.8\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">366.46</text><text x=\"220.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db.m6i.large</text><text x=\"220.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL Server Standard, 100 GiB</text><rect x=\"230.0\" y=\"190.0\" width=\"408.7\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"638.7\" y=\"190.0\" width=\"11.3\" height=\"24.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"658.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">815.41</text><line x1=\"230.0\" y1=\"236.0\" x2=\"650.0\" y2=\"236.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"230.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"650.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">815.41</text><text x=\"440.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD per month, 730 hours</text><rect x=\"470.0\" y=\"38.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">instance</text><rect x=\"570.0\" y=\"38.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"588.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">storage</text></svg>", "caption": "The same size of machine: the SQL Server licence is most of its bill, and Multi-AZ doubles both parts."}
```

## Storage is allocated, not used

**You pay for the 100 GiB you asked for**, on the day you ask, whether the database holds 3 GiB or 99.
Storage on RDS grows and does not shrink: `modify-db-instance` can raise the allocation without a
restart, and storage autoscaling raises it for you when the free space runs low, up to a ceiling you
set. Lowering it means moving the data to a new instance with a smaller volume. So allocate for the next
year, not the next five, and set the autoscaling ceiling.

**Backups are free up to the size of the database.** AWS documents an allowance of backup storage equal
to the storage provisioned in the region, and charges 0.095 per GiB-month beyond it. Seven days of
automated backups of a 100 GiB database that changes slowly stay inside the allowance; thirty-five
days of a database that rewrites itself every night do not. Lesson 7 shows what the backups are, and
the manual snapshots that are kept until somebody deletes them are where this line usually grows.

## The two ways to pay less

**A stopped instance still pays for its storage.** `stop-db-instance` stops the hourly charge for the
machine, and RDS starts the instance again on its own after seven days, a documented limit that
catches people who meant to stop a test database for a month. For an instance that is needed in office
hours only, stopping it at night pays; for one that is needed in a month's time, a snapshot and a
deletion pays, and lesson 7 restores from one.

**A commitment is the other way**, a Reserved Instance for one or three years in exchange for a lower
hourly price, and it is a decision about the business more than about the database.
`aws-foundations` lesson 14 reads the bill with it, and none of the prices in this lesson include one.
