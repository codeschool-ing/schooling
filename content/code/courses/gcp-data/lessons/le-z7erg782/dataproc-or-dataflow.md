---
title: When Dataproc beats Dataflow, and when it does not
version: 1
---

**The usual belief is that Dataproc is the cheap option and Dataflow the convenient one.** Per hour
of work, the first half is barely true: priced from Google's pages for São Paulo, the same machine
costs within about a fifth of the same amount in both. What decides the bill is the hours nobody
works, and what decides the choice is mostly not the bill at all.

## The prices, and where each came from

Every number below was read on 2026-10-30, in US dollars, for `southamerica-east1`.

| what | price | page |
|---|---|---|
| `n2-standard-4`, 4 vCPU and 16 GiB, on demand | $0.30832 an hour | `cloud.google.com/products/compute/pricing/general-purpose` |
| Dataproc management fee, clusters | $0.010 per vCPU-hour | `cloud.google.com/dataproc/pricing` |
| standard persistent disk | $0.000082192 per GiB-hour | `cloud.google.com/compute/disks-image-pricing` |
| Dataproc Serverless, standard tier | $0.095246 per DCU-hour | `cloud.google.com/dataproc/pricing` |
| Dataflow batch worker vCPU | $0.084 an hour | `cloud.google.com/dataflow/pricing` |
| Dataflow batch worker memory | $0.0053355 per GiB-hour | `cloud.google.com/dataflow/pricing` |
| Dataflow standard persistent disk | $0.000081 per GiB-hour | `cloud.google.com/dataflow/pricing` |

**The management fee is the only line that is Dataproc's own on a cluster**, and the pricing page
states it as one rate, $0.010 per vCPU-hour, applied to every vCPU of the master and of both kinds
of worker. Everything else on a cluster's bill is Compute Engine's: the machines, at the price of
their type, and the disks. The Compute Engine page also sells the same `n2-standard-4` for less
under a one- or three-year commitment, and as Spot at a price that changes daily, which is why no
line here is Spot.

Three things are left out of every line below and are worth naming. **Dataflow Shuffle** bills
$0.01747 per GiB of data shuffled in a batch job in São Paulo, and Serverless bills shuffle
storage per GiB-hour; both depend on the data, and this job shuffles one row per customer. **The
storage and the reads** of the buckets are the same whichever engine reads them. **Committed-use and
sustained-use discounts** lower the Compute Engine lines and are left at the on-demand price.

## One night's job, four ways

Quitanda's nightly job, grown to the size it will have in a year: ten workers of 4 vCPU and 16 GiB
for two hours, thirty nights a month. The program prices one unit of that size in each product,
then the month, and then the same cluster left running. Save it as `dataproc_vs_dataflow.py`:

```schooling-example
{"language": "python", "file": "dataproc_vs_dataflow.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, with the page each line came from.\nN2_STANDARD_4 = 0.30832    # an hour, on demand: cloud.google.com/products/compute/pricing/general-purpose\nFEE_PER_VCPU = 0.010       # an hour, Dataproc on Compute Engine: cloud.google.com/dataproc/pricing\nPD_STANDARD = 0.000082192  # a GiB-hour: cloud.google.com/compute/disks-image-pricing\nDCU = 0.095246             # an hour, Serverless, standard tier: cloud.google.com/dataproc/pricing\nDF_VCPU = 0.084            # an hour, Dataflow batch: cloud.google.com/dataflow/pricing\nDF_GIB = 0.0053355         # a GiB-hour of memory, Dataflow batch\nDF_PD = 0.000081           # a GiB-hour of standard disk, Dataflow\nHOURS_PER_MONTH = 730\n\n", "note": "Seven prices from four pages, each with its page beside it, and the 730 hours of an average month."}, {"code": "node = N2_STANDARD_4 + 4 * FEE_PER_VCPU + 100 * PD_STANDARD   # with a 100 GiB boot disk\nexecutor = (4 * 0.6 + 16 * 0.1) * DCU                         # 4 vCPU and 16 GiB are 4 DCUs\nworker = 4 * DF_VCPU + 16 * DF_GIB + 25 * DF_PD               # 25 GiB of disk, with Shuffle\nprint(f'one unit of 4 vCPU and 16 GiB for an hour: cluster {node:.5f}, '\n      f'Serverless {executor:.5f}, Dataflow {worker:.5f}')\n\n", "note": "**One unit of the same size in each product, for an hour.** A cluster node is the machine, the fee on its four vCPUs and its disk. A Serverless executor is converted to DCUs at the page's rates, 0.6 a vCPU and 0.1 a GiB. A Dataflow worker is billed by vCPU, memory and disk directly."}, {"code": "WORKERS, HOURS, NIGHTS = 10, 2, 30\nmonth = {\n    'Dataproc cluster': (WORKERS + 1) * node * HOURS * NIGHTS,          # plus the master\n    'Dataproc Serverless': (WORKERS + 1) * executor * HOURS * NIGHTS,   # plus the driver\n    'Dataflow': WORKERS * worker * HOURS * NIGHTS,\n    'cluster left on': (WORKERS + 1) * node * HOURS_PER_MONTH,\n}\nfor name, usd in month.items():\n    print(f'{name:<21}{usd:8.2f} a month')\n\n", "note": "Ten units for two hours, thirty nights. A cluster also pays for its master and a Serverless batch for its driver, both the same size as a worker; Dataflow coordinates the job itself and bills only the workers. The last line is the same cluster created once and never deleted."}, {"code": "per_nightly_hour = WORKERS * worker * NIGHTS\nprint(f'left on, the cluster is cheaper than Dataflow above '\n      f'{month[\"cluster left on\"] / per_nightly_hour:.1f} hours of work a night')\n", "note": "Where the flat line of a cluster that never stops meets Dataflow's rising one: what a month of the idle cluster costs, divided by what each hour of nightly work costs Dataflow over thirty nights."}]}
```

```
ana@laptop:~/gcp$ python3 dataproc_vs_dataflow.py
one unit of 4 vCPU and 16 GiB for an hour: cluster 0.35654, Serverless 0.38098, Dataflow 0.42339
Dataproc cluster       235.32 a month
Dataproc Serverless    251.45 a month
Dataflow               254.04 a month
cluster left on       2863.01 a month
left on, the cluster is cheaper than Dataflow above 22.5 hours of work a night
```

**Per hour of the same unit, the three are close: 0.35654 for a cluster node, 0.38098 for a
Serverless executor and 0.42339 for a Dataflow worker.** The cluster is cheapest because Compute
Engine's machine plus a cent of fee per vCPU is less than Dataflow's vCPU and memory rates, which
include the service that manages the workers. Over the month the gap shrinks again, because the
cluster and the batch each pay for one more machine than Dataflow does: the master, and the driver.
**235.32, 251.45 and 254.04 are within 8% of each other**, which is less than the difference one
badly sized job makes.

**The fourth line is the one that matters.** The same eleven machines, created once and never
deleted, cost 2863.01 a month, twelve times the ephemeral cluster, for exactly the same work.
Nothing about the machines changed between the two lines; only the hours did.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart of USD a month against hours of work a night, for a job of ten workers over thirty nights. Three lines rise from zero almost together: Dataflow to about 3048 at 24 hours, Dataproc Serverless to about 3017, and an ephemeral Dataproc cluster to about 2824. A dashed flat line, the cluster left on, stays at 2863.01 whatever the hours. Dataflow crosses it at 22.5 hours. A dotted mark at 2 hours shows Quitanda's job.\" data-fig=\"l23-month\"><line x1=\"80.0\" y1=\"280.0\" x2=\"560.0\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280.0\" x2=\"80.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280.0\" x2=\"80.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"80.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"160.0\" y1=\"280.0\" x2=\"160.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"160.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><line x1=\"240.0\" y1=\"280.0\" x2=\"240.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"240.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><line x1=\"320.0\" y1=\"280.0\" x2=\"320.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"320.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><line x1=\"400.0\" y1=\"280.0\" x2=\"400.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"400.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><line x1=\"480.0\" y1=\"280.0\" x2=\"480.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"480.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><line x1=\"560.0\" y1=\"280.0\" x2=\"560.0\" y2=\"284.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"560.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><line x1=\"76.0\" y1=\"280.0\" x2=\"80.0\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"76.0\" y1=\"244.3\" x2=\"80.0\" y2=\"244.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"244.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500</text><line x1=\"76.0\" y1=\"208.6\" x2=\"80.0\" y2=\"208.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"208.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><line x1=\"76.0\" y1=\"172.9\" x2=\"80.0\" y2=\"172.9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"172.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1500</text><line x1=\"76.0\" y1=\"137.1\" x2=\"80.0\" y2=\"137.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"137.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><line x1=\"76.0\" y1=\"101.4\" x2=\"80.0\" y2=\"101.4\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"101.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2500</text><line x1=\"76.0\" y1=\"65.7\" x2=\"80.0\" y2=\"65.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"76.0\" y1=\"30.0\" x2=\"80.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"320.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hours of work a night, ten workers</text><text x=\"80.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">USD a month</text><polyline points=\"80.0,280.0 560.0,62.3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 560.0,64.5\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 560.0,78.3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,75.5 560.0,75.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><text x=\"568\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Dataflow</text><text x=\"90\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cluster left on</text><text x=\"568\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Serverless</text><text x=\"568\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ephemeral cluster</text><circle cx=\"530.0\" cy=\"75.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><line x1=\"530.0\" y1=\"75.5\" x2=\"530.0\" y2=\"280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"524.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">22.5 h</text><line x1=\"120.0\" y1=\"280.0\" x2=\"120.0\" y2=\"215.7\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"124.0\" y=\"210.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Quitanda's job: 2 h</text></svg>", "caption": "Per hour of work the three are within a tenth of each other; a cluster left on costs the same whether it works two hours a night or twenty, and Dataflow only catches it at 22.5."}
```

**The flat line and the rising ones meet at 22.5 hours of work a night.** Ten Dataflow workers cost
4.23393 an hour, which over thirty nights is 127.02 a month for each nightly hour, and 2863.01
divided by that is 22.5. So a cluster that never stops is cheaper than Dataflow only for work that
keeps it busy almost the whole day. Below that, a cluster left on is paying for hours nobody uses,
and the guard is the `--delete-max-idle` of the previous section, not a cheaper machine type.

## When Dataproc wins

**When the code is already Spark or Hadoop.** A team with years of Spark jobs, Hive queries or
MapReduce moves them to Dataproc with paths changed from `hdfs://` to `gs://`, and that is the
largest single reason Dataproc exists. Rewriting the same jobs in Apache Beam for Dataflow is a
project; moving them is an afternoon per job.

**When the job needs the machine.** A native library, a particular Spark configuration, a JAR on
the classpath, an agent that must run beside the job: on Dataproc it goes in an initialization
action or a custom image, and on Dataflow it has to go into a worker container instead.

**When people work on it.** Notebooks, Spark SQL explored by hand, an analyst on Trino: these need
something running when the person arrives, and a cluster shared all day pays its idle hours once
for everybody, with `--delete-max-idle` for the evening.

**When Spot fits the job.** A large batch job that tolerates losing secondary workers can run most
of its work on the cheapest capacity Google sells, at a price this lesson could not put a number
on. Dataflow's nearest equivalent is FlexRS, which the Dataflow page describes as discounting batch
vCPU and memory in exchange for starting the job up to six hours later.

## When Dataflow wins

**When the pipeline is new**, and particularly when it is both batch and stream. Lesson 21 wrote one
Beam pipeline for both, and lesson 22 gave it windows and watermarks; Spark has its own streaming
engine, and on Dataproc it runs on a cluster somebody has to keep up all day.

**When nobody wants to own a cluster.** Dataflow has no image to upgrade, no worker count to choose
in advance, no initialization action to time out and no cluster to forget. It scales the workers
of each job from what the job is doing, and stops them when it ends.

**When the work is irregular.** A job that runs some nights and not others, or runs for minutes, is
where Dataflow and Serverless, which bill only while work happens, are cheapest, and where a
cluster spends more of its life booting than working.

**The judgement is about the code you have and the hours you use, not about the engine.** For
Quitanda's one new nightly job, Dataflow costs 254.04 − 235.32 = 18.72 a month more than an
ephemeral cluster, and buys a pipeline nobody has to size, upgrade or delete. The day the company
inherits a hundred Spark jobs from an acquisition, or a data scientist wants a notebook on the same
data every morning, Dataproc stops being the cheaper engine and becomes the obvious one.
