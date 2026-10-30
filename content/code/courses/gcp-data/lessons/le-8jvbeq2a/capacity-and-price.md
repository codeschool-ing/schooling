---
title: Nodes, processing units, editions, and what it charges for
version: 1
---

**Spanner charges for three things: compute capacity by the hour, storage by the GiB-month, and data
moved between regions.** Compute is the instance's nodes or processing units, billed whether the
instance is busy or not; storage is what the databases hold, with their indexes; replication between
regions applies only to dual-region and multi-region configurations. There is no charge per query or
per row read. So the bill is set by how much capacity the instance keeps running, and the question
is what decides that number.

**The wrong idea is that Spanner is too expensive for anything small.** It used to start at one node.
It now starts at 100 processing units, a tenth of a node, and the pricing page says an instance of
200 processing units for 6 hours is billed 1.2 node-hours. Every change of capacity is billed for at
least one hour.

## The rates

**From the pricing page, regional `southamerica-east1`, USD, list prices, read on 2026-10-30** at
cloud.google.com/spanner/pricing. The page prices compute per node-hour by **edition**, and a node in
a regional configuration includes its three replicas:

| | per node-hour, regional |
|---|---|
| Standard | 1.35 |
| Enterprise | 1.845 |
| Enterprise Plus | 2.565 |
| storage, SSD, all three replicas | 0.45 per GiB-month |
| storage, HDD, all three replicas | 0.09 per GiB-month |

**The editions differ in what an instance may be, not in speed.** The pricing page says dual-region and
multi-region configurations are available in Enterprise Plus, and optional read-only replicas in
Enterprise and Enterprise Plus; Standard is a regional instance with the core of Spanner. The editions
overview at cloud.google.com/spanner/docs/editions-overview lists the rest, and the command line knows
the three names:

```
ana@laptop:~/gcp$ gcloud spanner instances create --help | sed -n '/^     --edition/,/Standard edition/p'
     --edition=EDITION
        Spanner edition. EDITION must be one of:

         EDITION_UNSPECIFIED
            Spanner's legacy pricing model. For more information, see the
            Spanner editions overview
            (https://cloud.google.com/spanner/docs/editions-overview)
         ENTERPRISE
            Enterprise edition
         ENTERPRISE_PLUS
            Enterprise Plus edition
         STANDARD
            Standard edition
```

`price.py`:

```python
"""Spanner, regional southamerica-east1, USD a month at list prices read on
2026-10-30 from cloud.google.com/spanner/pricing."""
HOURS = 730
NODE_HOUR = {'Standard': 1.35, 'Enterprise': 1.845, 'Enterprise Plus': 2.565}
SSD_GIB_MONTH = 0.45

for edition, rate in NODE_HOUR.items():
    print(f'{edition:<16} 100 PU {0.1 * rate * HOURS:>8,.2f}'
          f'   1 node {rate * HOURS:>9,.2f}   3 nodes {3 * rate * HOURS:>9,.2f}')
print(f'500 GiB of SSD storage {500 * SSD_GIB_MONTH:,.2f}')
```

```
ana@laptop:~/gcp$ python3 price.py
Standard         100 PU    98.55   1 node    985.50   3 nodes  2,956.50
Enterprise       100 PU   134.69   1 node  1,346.85   3 nodes  4,040.55
Enterprise Plus  100 PU   187.25   1 node  1,872.45   3 nodes  5,617.35
500 GiB of SSD storage 225.00
```

**The smallest instance is 98.55 a month on Standard**, 100 processing units for 730 hours, and one
node is 985.50, which matches the monthly figure the pricing page prints itself. Quitanda's 500 GiB
add 225.00 of storage, replicas included. For comparison with lesson 8, one AlloyDB node of 8 vCPUs
cost 1,445.87 a month; but a Spanner node is not a machine of a given size, so the two do not compare
node for node, only bill for bill, for the same load.

## What decides the number of nodes

**CPU, measured, and storage, within a limit per node.** Google's guidance is to keep a regional
instance's high-priority CPU utilisation below 65%, so that a zone can fail and the survivors absorb
its load, and each node or processing unit can hold a limited amount of data, which the quotas page
documents. An instance of 100 processing units holding more than its share of data must grow even if
it is idle. Spanner's managed autoscaler, in the Enterprise editions, moves the capacity between limits
you set.

**None of that can be measured here**, and the emulator shows why in the plainest way. It accepts an
instance of any legal size and gives it no capacity at all:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-big --config=emulator-config --description="Five nodes" --nodes=5
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances describe quitanda-big --format='value(nodeCount,processingUnits)'
5	5000
```

**Five nodes, created in a second, on a laptop.** And it will not change one afterwards:

```
ana@laptop:~/gcp$ gcloud spanner instances update quitanda --processing-units=200
ERROR: (gcloud.spanner.instances.update) HttpError accessing <http://localhost:9020/v1/projects/planner-dev/instances/quitanda?alt=json>: response: <{'content-type': 'application/json', 'date': 'Fri, 30 Oct 2026 18:47:49 GMT', 'content-length': '83', 'status': 501}>, content <{"code":12,"message":"Cloud Spanner Emulator does not support updating instances."}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
```

## Everything else the emulator does not do

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PLAN
 None No query plan

ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PROFILE
┌────────────────────┬──────────┬───────────────┬──────────────┬───────────────────┐
│ TOTAL_ELAPSED_TIME │ CPU_TIME │ ROWS_RETURNED │ ROWS_SCANNED │ OPTIMIZER_VERSION │
├────────────────────┼──────────┼───────────────┼──────────────┼───────────────────┤
│ 2.126915ms         │ Unknown  │ 2             │ Unknown      │ Unknown           │
└────────────────────┴──────────┴───────────────┴──────────────┴───────────────────┘
 None No query plan

Product   Units
rice-5kg  31
banana    41
```

**`No query plan`.** Spanner's plans, which show where a query read and whether it crossed splits, are
not produced by the emulator in any query mode; `PROFILE` returns the rows and a table of statistics
whose CPU time and rows scanned are `Unknown`. The full list, from what this lesson ran:

| on Spanner | in the emulator |
|---|---|
| splits, moved by load and size | none; one process |
| replicas, a leader per split, TrueTime | none; one clock |
| query plans in `PLAN` and `PROFILE` | `No query plan` |
| concurrent read-write transactions | one at a time; the other is aborted |
| instance configurations per region | only `emulator-config` listed, and others accepted unchecked |
| changing an instance's capacity | refused, `does not support updating instances` |
| editions | the flag accepted, and nothing recorded |
| performance, latency, cost | nothing to measure |

**Two of those rows are traps rather than gaps**, and they are the ones to remember:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-sp --config=regional-southamerica-east1 --description="São Paulo" --processing-units=100 --edition=ENTERPRISE
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances describe quitanda-sp
config: projects/planner-dev/instanceConfigs/regional-southamerica-east1
createTime: '2026-10-30T18:47:52.108394845Z'
displayName: São Paulo
name: projects/planner-dev/instances/quitanda-sp
processingUnits: 100
state: READY
updateTime: '2026-10-30T18:47:52.108394845Z'
```

**`regional-southamerica-east1` was not in the emulator's own list, and it was accepted**; on Google
Cloud it would be checked against the configurations your project may use. And `--edition=ENTERPRISE`
was accepted and then absent from the description, so an edition chosen against the emulator is
chosen against nothing. The schema, the SQL, the keys and the transactions behaved as Spanner's; the
capacity and the bill are taught from the documentation, and the pricing page's **free trial
instance**, 90 days and up to 10 GiB, is where a first real measurement costs nothing.
