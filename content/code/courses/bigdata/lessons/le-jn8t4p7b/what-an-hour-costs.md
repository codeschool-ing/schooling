---
title: What an hour of cluster costs
version: 1
---

**A cluster is billed for the time its machines exist, busy or not.** Every price on a cloud
provider's list is some version of *machines × hours × price per machine-hour*, plus storage by the
gigabyte-month and network by the gigabyte. Prices differ by provider, region, machine type and year,
and change; so this section uses **one assumed price throughout, US$0.20 an hour for a machine of 4
cores and 16 GB**, a round number of the right order for an ordinary on-demand machine. Before
deciding anything real, replace it with the price from your provider's list.

**The report, priced.** Suppose the production version of it runs on a cluster of 10 such machines,
and that, like the lab's, the slow version takes eight times as long as the tuned one:

| | runs | machine-hours a day | a month at US$0.20 |
|---|---|---|---|
| tuned, 10 minutes a morning | once a day | 10 × 1/6 = 1.7 | US$10 |
| slow, 80 minutes a morning | once a day | 10 × 8/6 = 13.3 | US$80 |

**Seventy dollars a month is not why the report was fixed**; the analysts waiting over an hour every
morning were. Tuning pays in money when the job is large or frequent: the same factor of eight on a
job of
200 machines that runs hourly is the difference between US$4,800 and US$38,400 a month.

**The cluster that is never switched off is the larger cost.** The same 10 machines kept running for
the morning report, every hour of a 30-day month:

| | machine-hours a month | at US$0.20 |
|---|---|---|
| a cluster that exists only while the tuned report runs | 10 × 1/6 × 30 = 50 | US$10 |
| the same cluster, always on | 10 × 24 × 30 = 7,200 | US$1,440 |

**This is what lesson 3's object storage made possible.** When the data lives in an object store, a
cluster can be created for a job and deleted after it, and nothing is lost, because nothing was on
it. HDFS on the cluster's own disks rules that out: the cluster is the storage, so it stays on. The
storage still costs money, by the gigabyte-month, but a terabyte kept in an object store costs a small
fraction of a cluster kept on to hold it. Managed services, lesson 13, start a cluster in a few
minutes, and those minutes are billed too: for a ten-minute job, an extra three minutes of start-up is
nearly a third more.

**And an application that holds what it does not use is the same waste at a smaller scale**, lesson
2's dynamic allocation. A notebook session that keeps 10 executors through an 8-hour working day and
computes for one of those hours holds 70 executor-hours idle a day. At a quarter of a machine each,
US$0.05 an hour, that is US$3.50 a day for one person, and a team of twenty pays it every working
day.
Lesson 13's measurement, executors released half a minute after the work stopped, is that cost
removed.
