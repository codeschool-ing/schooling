---
title: What an instance costs in a month
version: 1
---

**A Cloud SQL instance is billed for things that run all the time and one that grows**: the vCPUs and
the memory, by the hour, whether anybody queries them or not; the disk, by the GiB you set, whether it
is full or not; and the backups, by the GiB they hold. There is no charge per query and no charge per
row, which is the opposite of BigQuery in lessons 13 and 14, and it means an idle database costs
exactly what a busy one does.

**On Enterprise the machine is not priced as a machine.** The pricing page prints a price per vCPU-hour
and a price per GiB-hour of memory, and an instance of 2 vCPU and 8 GiB pays two of the first and eight
of the second. For `southamerica-east1`, from cloud.google.com/sql/pricing, read 2026-10-30, in USD:

| | per vCPU-hour | per GiB-hour of memory |
|---|---|---|
| Enterprise | 0.062 | 0.0105 |
| Enterprise, high availability | 0.1239 | 0.021 |
| Enterprise Plus, N2 series | 0.0805 | 0.0137 |
| Enterprise Plus, N2, high availability | 0.1611 | 0.0273 |

| storage and the rest | price |
|---|---|
| SSD | 0.255 per GiB-month, 0.51 with high availability |
| HDD | 0.135 per GiB-month, 0.27 with high availability |
| backups | 0.12 per GiB-month used |
| `db-f1-micro`, shared core, 0.6 GiB | 0.0158 an hour |
| SQL Server licence, Standard | 0.13 per core-hour, at least 4 cores |
| SQL Server licence, Enterprise | 0.47 per core-hour, at least 4 cores |

## A month is 730 hours

The pricing page's monthly figures are its hourly ones times 730, which is 365 days times 24 hours
divided by 12, and every price in this course uses the same month. Five instances Quitanda could run,
priced by a program short enough to read whole.

`sqlcost.py`:

```python
"""A month of five Cloud SQL instances in southamerica-east1, from the pricing page."""
HOURS = 730                       # the month every Google pricing table uses

# USD, cloud.google.com/sql/pricing, southamerica-east1, read 2026-10-30
ENTERPRISE = {'cpu': 0.062, 'gib': 0.0105, 'ha_cpu': 0.1239, 'ha_gib': 0.021}
PLUS_N2 = {'cpu': 0.0805, 'gib': 0.0137, 'ha_cpu': 0.1611, 'ha_gib': 0.0273}
SSD, SSD_HA = 0.255, 0.51         # per GiB-month
MICRO = 0.0158                    # db-f1-micro, per hour, shared core
SQLSERVER_STANDARD = 0.13         # licence, per core-hour, at least 4 cores


def machine(price, cpu, gib, ha=False):
    if ha:
        return (cpu * price['ha_cpu'] + gib * price['ha_gib']) * HOURS
    return (cpu * price['cpu'] + gib * price['gib']) * HOURS


def show(name, compute, disk):
    print(f'{name:<44}{compute:>9,.2f}{disk:>8,.2f}{compute + disk:>10,.2f}')


print(f'{"a month, 730 hours":<44}{"machine":>9}{"disk":>8}{"total":>10}')
show('db-f1-micro, 10 GiB, PostgreSQL', MICRO * HOURS, 10 * SSD)
show('Enterprise, 2 vCPU 8 GiB, 100 GiB', machine(ENTERPRISE, 2, 8), 100 * SSD)
show('the same, high availability', machine(ENTERPRISE, 2, 8, ha=True), 100 * SSD_HA)
show('Enterprise Plus, 2 vCPU 16 GiB, 100 GiB', machine(PLUS_N2, 2, 16), 100 * SSD)
show('Enterprise, 2 vCPU 8 GiB, SQL Server Std',
     machine(ENTERPRISE, 2, 8) + max(2, 4) * SQLSERVER_STANDARD * HOURS, 100 * SSD)
```

```
ana@laptop:~/gcp$ python3 sqlcost.py
a month, 730 hours                            machine    disk     total
db-f1-micro, 10 GiB, PostgreSQL                 11.53    2.55     14.08
Enterprise, 2 vCPU 8 GiB, 100 GiB              151.84   25.50    177.34
the same, high availability                    303.53   51.00    354.53
Enterprise Plus, 2 vCPU 16 GiB, 100 GiB        277.55   25.50    303.05
Enterprise, 2 vCPU 8 GiB, SQL Server Std       531.44   25.50    556.94
```

**The micro is for development, and nothing else.** A shared core and 0.6 GiB of memory run the
migrations and the tests against a real engine, and 14.08 a month is less than anybody's time spent
arguing about it. It is not covered by Cloud SQL's SLA, and it is not where Quitanda's orders live.

**The Enterprise instance is 177.34**: 2 × 0.062 + 8 × 0.0105 = 0.208 an hour, 151.84 a month, and
25.50 for the disk. That is the instance of the previous sections.

**High availability is almost exactly double**, the machine and the disk both, because it is a second
machine with a second disk in another zone, kept in step with the first. Lesson 7 is what the second
copy buys, and it is the line where 354.53 has to be argued for.

**Enterprise Plus costs more per vCPU and much more for memory**, and it comes with twice the memory
per vCPU: 2 × 0.0805 + 16 × 0.0137 = 0.3802 an hour. The 303.05 buys the SLA, the shorter
maintenance and the longer logs of the editions table, and 16 GiB rather than 8; whether a database
needs the memory is a question for its working set, not for the edition.

**The licence is most of the SQL Server bill.** The same 2 vCPU and 8 GiB as the Enterprise line, and
then four cores of Standard licence at 0.13 an hour, because Microsoft licenses at least four cores
per instance whatever the instance has: 0.52 an hour for the licence against 0.208 for the machine,
556.94 against 177.34. The pricing page adds that a highly available instance pays for one licence,
not two, since only one machine runs the engine at a time.

## What else lands on the bill

**Storage is what you set, not what you use**, and with auto-increase on, what you set only goes up.
Allocate for the next year and set the ceiling.

**Backups are billed for what they hold**, at 0.12 a GiB-month. Lesson 7 says how many are kept and for
how long. The reference for `--retained-transaction-log-days` adds a warning that belongs here: where
the logs for point-in-time recovery are kept on the instance's disk, more days of them is more disk.

**An old major version costs extra.** The pricing page's "Extended support" table charges, in
São Paulo, 0.105 per vCPU-hour in the first two years after a version's end of standard support and
0.21 in the third, on top of the instance. For the Enterprise instance above, with its 2 vCPU, a year
late on an upgrade is:

```
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.105 * 730, 2))'
153.3
```

**153.30 a month on top of 177.34**, nearly doubling it. The upgrade from the first section,
the one Google does not do for you, has a price for not doing it.

**A public IP address that is not in use is charged by the hour**, 0.015 in this region, and the egress
from an instance is priced like the network of lesson 5, by where the bytes go.

**A stopped instance still pays for its disk.** Setting `--activation-policy=never` with
`gcloud sql instances patch` stops the machine and its hourly charge, and the disk, the backups and
the reserved addresses keep billing. For an instance needed in office hours only, stopping it at
night pays; for one needed in a month's time, an export to a bucket and a deletion pays more.

**A commitment is the other way to pay less**: a committed use discount for one or three years, which
the pricing page prints beside every price, 0.0465 instead of 0.062 a vCPU-hour for one year in São
Paulo. It is a decision about the business more than about the database, `gcp-foundations` lesson 13
reads it on the bill, and none of the prices in this lesson include one.
