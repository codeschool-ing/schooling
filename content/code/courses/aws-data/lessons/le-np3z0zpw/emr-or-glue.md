---
title: When EMR beats Glue, and when it does not
version: 1
---

**The usual belief is that EMR is the cheap option and Glue the convenient one.** Per hour of
machine, that is true, and by a wide margin. Per month of a real workload it is true only when the
machines are busy, and a cluster that is cheap per hour and idle for twenty-two of them is the most
expensive way in this lesson to run a two-hour job.

Start with the prices. EMR's line is only the fee, and the machine is EC2's, which this sheet does not
read. The machine's own price comes from the sheet of `cloud` lesson 4, which printed
`m7i.xlarge` at **0.32130** USD an hour on demand in São Paulo, and **0.20160** reserved for a year
with nothing paid up front.

```
ana@laptop:~/aws$ python3 prices.py emr glue
AWS public price list, sa-east-1, USD, excluding tax

EMR, USD
  EMR fee on an m7i.xlarge, per hour                    0.05040  hour
  Serverless, per vCPU-hour                             0.09048  hour
  Serverless, per GB-hour of memory                     0.00988  hour

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**A Glue DPU is 4 vCPU and 16 GB of memory, and so is an `m7i.xlarge`**, which makes the
comparison a fair one: one unit of the same size, for an hour, in each product.

| one unit of 4 vCPU and 16 GB, for an hour | arithmetic | USD |
|---|---|---|
| Glue | the DPU-hour | 0.69000 |
| Glue Flex | the Flex DPU-hour | 0.45000 |
| EMR Serverless | 4 × 0.09048 + 16 × 0.00988 = 0.36192 + 0.15808 | 0.52000 |
| EMR on EC2, on demand | 0.32130 + 0.05040 | 0.37170 |
| EMR on EC2, reserved | 0.20160 + 0.05040 | 0.25200 |

**EMR on EC2 is 0.37170 against Glue's 0.69000, a little over half**, and the EMR fee is the same
whatever way the machine is paid for, which is why a reserved machine brings it down to 0.25200.
Spot brings it down further, by an amount the market sets on the day.

## One night's job, five ways

Quitanda's nightly job uses ten units for two hours, thirty nights a month. The program below
prices it in each product, and prices one more case: the same EMR cluster left running all month.
Save it as `emr_vs_glue.py`:

```schooling-example
{"language": "python", "file": "emr_vs_glue.py", "parts": [{"code": "# USD per hour, sa-east-1. Glue and EMR from `python3 prices.py glue emr`;\n# the machine from the sheet of `cloud` lesson 4, m7i.xlarge on demand.\nGLUE_DPU = 0.69000\nGLUE_FLEX_DPU = 0.45000\nEMR_FEE = 0.05040\nM7I_XLARGE = 0.32130\nSERVERLESS_VCPU = 0.09048\nSERVERLESS_GB = 0.00988\nHOURS_PER_MONTH = 730\n\n", "note": "Six prices copied from the two sheets, with the place each came from written above them, and the 730 hours of an average month."}, {"code": "per_unit = {                       # one unit: 4 vCPU and 16 GB, for an hour\n    'Glue': GLUE_DPU,\n    'Glue Flex': GLUE_FLEX_DPU,\n    'EMR Serverless': 4 * SERVERLESS_VCPU + 16 * SERVERLESS_GB,\n    'EMR on EC2': M7I_XLARGE + EMR_FEE,\n}\n\n", "note": "**The price of one unit in each product.** Serverless charges processors and memory apart, so its unit is four of one and sixteen of the other; EMR on EC2 is the machine plus the fee."}, {"code": "WORKERS, HOURS, NIGHTS = 10, 2, 30\n\nfor name, usd in per_unit.items():\n    units = WORKERS + (1 if name == 'EMR on EC2' else 0)    # plus the primary node\n    month = units * HOURS * NIGHTS * usd\n    print(f'{name:<16}{usd:.5f} a unit-hour  {month:8.2f} a month')\n\n", "note": "Ten units for two hours, thirty nights. The cluster also needs its primary node, which coordinates and does none of the work, so EMR on EC2 pays for eleven machines where the others pay for ten units."}, {"code": "left_on = (WORKERS + 1) * HOURS_PER_MONTH * per_unit['EMR on EC2']\nprint(f'{\"EMR left on\":<16}{per_unit[\"EMR on EC2\"]:.5f} a unit-hour  {left_on:8.2f} a month')\n", "note": "The same eleven machines created once and never terminated: every hour of the month, whether a job runs or not."}]}
```

```
ana@laptop:~/aws$ python3 emr_vs_glue.py
Glue            0.69000 a unit-hour    414.00 a month
Glue Flex       0.45000 a unit-hour    270.00 a month
EMR Serverless  0.52000 a unit-hour    312.00 a month
EMR on EC2      0.37170 a unit-hour    245.32 a month
EMR left on     0.37170 a unit-hour   2984.75 a month
```

**The transient EMR cluster is the cheapest line, at 245.32, and the same cluster left running is
the most expensive by a factor of twelve, at 2984.75.** Nothing about the machines changed between
those two lines; only the hours did. Glue's 414.00 is 1.7 times the transient cluster, which is the price of nobody having to choose an
instance type, write a cluster definition or terminate anything. Glue Flex at 270.00 is about a tenth more than EMR, for a job that can wait for spare capacity.
EMR Serverless sits between the two Glues at 312.00. One cost the program leaves out falls on the EMR
cluster alone: AWS bills the minutes its machines take to boot and install before the step starts,
and moto, ready on the line it was created, gives no number to put there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart of USD a month against hours of work a night, for a job of ten units over thirty nights. Three lines rise from zero: Glue to about 4968 at 24 hours, EMR Serverless to about 3744, and transient EMR to about 2944. A dashed flat line, EMR left on, stays at 2984.75 whatever the hours. Glue crosses the flat line at 14.4 hours. A dotted mark at 2 hours shows Quitanda's job.\" data-fig=\"l24-month\"><defs><marker id=\"ah-l24-month\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"280\" x2=\"600\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80\" y1=\"280\" x2=\"80\" y2=\"30\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"80.0\" y1=\"280\" x2=\"80.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"80.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"166.66666666666669\" y1=\"280\" x2=\"166.66666666666669\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"166.66666666666669\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><line x1=\"253.33333333333334\" y1=\"280\" x2=\"253.33333333333334\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"253.33333333333334\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><line x1=\"340.0\" y1=\"280\" x2=\"340.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"340.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><line x1=\"426.6666666666667\" y1=\"280\" x2=\"426.6666666666667\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"426.6666666666667\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><line x1=\"513.3333333333333\" y1=\"280\" x2=\"513.3333333333333\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"513.3333333333333\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><line x1=\"600.0\" y1=\"280\" x2=\"600.0\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"600.0\" y=\"295\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><line x1=\"76\" y1=\"280.0\" x2=\"80\" y2=\"280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"76\" y1=\"230.0\" x2=\"80\" y2=\"230.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><line x1=\"76\" y1=\"180.0\" x2=\"80\" y2=\"180.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><line x1=\"76\" y1=\"130.0\" x2=\"80\" y2=\"130.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"76\" y1=\"80.0\" x2=\"80\" y2=\"80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><line x1=\"76\" y1=\"30.0\" x2=\"80\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"340.0\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hours of work a night, ten units</text><text x=\"80\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">USD a month</text><polyline points=\"80.0,280.0 600.0,31.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 600.0,92.8\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,280.0 600.0,132.8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></polyline><polyline points=\"80.0,130.8 600.0,130.8\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><text x=\"608.0\" y=\"31.60000000000005\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Glue</text><text x=\"608.0\" y=\"92.80000000000001\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">EMR Serverless</text><text x=\"608.0\" y=\"144.8068\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">transient EMR</text><text x=\"608.0\" y=\"120.76245000000003\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">EMR left on</text><circle cx=\"392.4\" cy=\"130.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><line x1=\"392.4135507246377\" y1=\"130.76245000000003\" x2=\"392.4135507246377\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"392.4135507246377\" y=\"116.76245000000003\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14.4 h</text><line x1=\"123.33333333333334\" y1=\"280\" x2=\"123.33333333333334\" y2=\"200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"127.33333333333334\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Quitanda's job: 2 h</text></svg>", "caption": "A cluster left on costs the same whether it works two hours a night or twenty; Glue only catches it at 14.4."}
```

**The left-on cluster costs the same at every hour of work, and Glue climbs with each one.** The two
lines cross where Glue's monthly cost reaches 2984.75: ten DPUs × 30 nights × 0.69 is 207.00 a
month for each hour of nightly work, and 2984.75 ÷ 207.00 is 14.4. **A job that runs more than about
fourteen hours a day is cheaper on a cluster that never stops than on Glue**, and below that a
cluster left on is paying for the hours nobody uses it.

## When EMR wins

**When the work is steady and large.** Many hours a day across many machines is where 0.37170
against 0.69000 becomes thousands of dollars a month, and a reserved machine or Spot widens the gap.

**When the job needs the machine.** A native library, a particular Spark configuration, a JAR on the
classpath, a tool of the Hadoop family that Glue does not run: on EMR it goes in a bootstrap action,
a script every machine runs as it boots, and on Glue it often cannot go at all.

**When people work on it.** Notebooks and interactive queries need something running when the
person arrives, and a cluster shared all day pays its idle hours once for everybody.

**When Spot fits the job.** A batch job that tolerates losing task nodes runs most of its work on the
cheapest capacity AWS sells, which Glue does not offer; its Flex option is the nearest thing.

## When Glue wins

**When the work is short, small or irregular**, so that a cluster would spend more of its life
booting and waiting than working.

**When nobody wants to own a cluster.** Glue has no machine types, no roles to configure, no
termination to forget and no release to upgrade, and lesson 17's job ran with nothing else around
it.

**When the job is ordinary ETL against the Data Catalog**, which Glue reads and writes natively, with
bookmarks that remember what was already processed.

**The judgement is about hours and people, not about Spark.** Both run the same engine. For
Quitanda's one nightly job, the transient cluster saves 414.00 − 245.32 = 168.68 a month over Glue,
and that saving is paid for in a cluster definition somebody writes, upgrades and is called about at
three in the morning. With one job, Glue is usually worth it; with forty, or with a job that runs all
day, the program above prints a number nobody can wave away.
