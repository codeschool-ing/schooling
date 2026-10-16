---
title: The bill for a warehouse
version: 1
---

**A provisioned cluster costs its nodes for every hour it exists, and Serverless costs its RPUs
for every hour it works.** Which is cheaper depends on one quantity, the hours of work a day, and
the two prices of the sheet are enough to find where the line falls:

```
ana@laptop:~/aws$ python3 prices.py redshift
AWS public price list, sa-east-1, USD, excluding tax

Redshift, USD
  ra3.large, per node-hour                              0.86600  hour
  ra3.xlplus, per node-hour                             1.73100  hour
  ra3.4xlarge, per node-hour                            5.19500  hour
  managed storage                                       0.04300  GB-month
  Serverless, per RPU-hour                              0.59760  RPU-hour
  Spectrum, per TB scanned                              5.00000  TB
```

## Two nodes, all month

The cluster of this lesson is two `ra3.xlplus` nodes. A 30-day month is 720 hours:

| | arithmetic | USD a month |
|---|---|---|
| compute | 2 nodes × 1.731 × 720 h | 2,492.64 |
| managed storage, 500 GB | 500 × 0.043 | 21.50 |
| **total** | | **2,514.14** |

**Compute is 99% of it.** The 500 GB that Quitanda's orders take after compression cost less than
the cluster runs up in seven hours. That is the arithmetic behind RA3's design: storage is cheap and
grows on its own, and the node-hours are the decision.

**A paused cluster stops the compute line.** `pause-cluster` keeps the data and the endpoint and
stops charging for the nodes until `resume-cluster`, and AWS bills only the storage meanwhile:

```
ana@laptop:~/aws$ aws redshift pause-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text
paused
ana@laptop:~/aws$ aws redshift describe-clusters --cluster-identifier quitanda-dw --query "Clusters[0].[ClusterStatus,NumberOfNodes]" --output text
paused	2
ana@laptop:~/aws$ aws redshift resume-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text
available
```

moto changed the status and stopped nothing, because nothing was running. On AWS, a cluster paused
for the twelve hours of every night that nobody queries saves half the compute line, 1,246.32 USD a
month. The price is a few minutes of waiting each morning while it resumes, and somebody or
something remembering to pause it.

## Serverless, for some hours a day

Serverless charges 0.5976 USD per RPU-hour, only while queries run. Two workloads, each in a 30-day
month:

| workload | arithmetic | USD a month |
|---|---|---|
| analysts, 4 hours a day at 32 RPUs | 32 × 0.5976 × 4 × 30 | 2,294.78 |
| a dashboard, 1 hour a day at 8 RPUs | 8 × 0.5976 × 1 × 30 | 143.42 |

**At 32 RPUs, the line falls at about four and a third hours a day.** An hour at 32 RPUs is 32 ×
0.5976 = 19.1232 USD, and 2,492.64 ÷ (19.1232 × 30) is 4.34: below that many busy hours a day,
Serverless costs less than the two nodes; above it, the cluster does. At 8 RPUs an hour is 4.7808
USD and the line moves to 17.38 hours a day, so a small Serverless workgroup stays cheaper unless it
is busy nearly all the time. Storage is the same 0.043 per GB-month in both, so it does not move the
line. **The number to watch is the busy hours, not the size of the data.**

These are list prices. Reserved nodes, paid a year or three ahead, cost less per hour; the sheet
does not print them and the course does not quote them.

## Querying the lake from Redshift

**Redshift Spectrum reads files in S3 from inside a Redshift query**, through an external table, so
a report can join last month's orders in the warehouse with three years of history that never left
the lake. It is billed like Athena, by the data scanned: 5.00 USD per TB in the sheet. A query
that scans 0.2 TB of CSV costs 0.2 × 5.00 = 1.00 USD, and the same rows in Parquet, read for two of
their twenty columns, scan a fraction of that. Lesson 15 measures the bytes a query scans, and
lesson 19 is the two decisions that set them.
