---
title: Rightsizing from two weeks of use
version: 1
---

**A VM is oversized when its busiest hours would still fit on a smaller one.** Not its average: its
busiest hours, because a VM sized to the average falls over at the peak. Two weeks of hourly CPU for three
of the shop's VMs, generated in the shape of the `Perf` table that a data collection rule (lesson 8) would
fill, go in `perf.kql`:

```kql
// perf.kql: two weeks of hourly CPU for three VMs, in the shape of the Perf table
.set-or-replace Perf <|
range TimeGenerated from datetime(2026-10-05 03:00) to datetime(2026-10-19 02:00) step 1h
| extend hour = hourofday(TimeGenerated - 3h), day = dayofmonth(TimeGenerated - 3h)
| extend k = 1
| join kind=inner (datatable(Computer: string, vcpus: int) ["vm-shop-batch", 8, "vm-reports", 4, "vmss-shop-workers_0", 4] | extend k = 1) on k
| extend noise = abs(hash(strcat(Computer, TimeGenerated), 100)) / 100.0
| extend CounterValue = round(case(
    Computer == "vm-shop-batch", iff(hour between (1 .. 4), 11.0, 3.0) + 4 * noise,
    Computer == "vm-reports", 1.0 + noise,
    iff(hour between (8 .. 19), 55.0, 25.0) + 20 * noise), 1)
| project TimeGenerated, Computer, ObjectName = "Processor", CounterName = "% Processor Time", CounterValue, vcpus
```

Real `Perf` rows arrive every minute, and the course writes one per hour, which is enough for the
question. Then the question, as a query:

```kql
// rightsize.kql: CPU over two weeks, and what it would be on a VM with fewer vCPUs
Perf
| where CounterName == "% Processor Time"
| summarize avg_cpu = round(avg(CounterValue), 1), p95_cpu = round(percentile(CounterValue, 95), 1) by Computer, vcpus
| extend p95_on_half = round(p95_cpu * 2, 1), p95_on_quarter = round(p95_cpu * 4, 1)
| project Computer, vcpus, avg_cpu, p95_cpu, p95_on_half, p95_on_quarter
| order by p95_cpu asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < rightsize.kql
Computer             vcpus  avg_cpu  p95_cpu  p95_on_half  p95_on_quarter
vm-reports           4      1.5      1.9      3.8          7.6
vm-shop-batch        8      6.2      13.2     26.4         52.8
vmss-shop-workers_0  4      49.8     72.4     144.8        289.6
```

The projection is simple arithmetic: the same work on half the vCPUs keeps them twice as busy. It is an
approximation, since memory, disk and network do not scale the same way, and it is honest enough to rank
the candidates.

**`vm-shop-batch` is the candidate.** Eight vCPUs whose 95th percentile is 13%: on a quarter of the size,
two vCPUs, its busiest hours would run at about 53%, with room to spare. **`vmss-shop-workers_0` is right as it
is**: its 95th percentile is already well into the seventies, and half the size would run out of CPU.
**`vm-reports` is a different case** again, and the next query says why.
