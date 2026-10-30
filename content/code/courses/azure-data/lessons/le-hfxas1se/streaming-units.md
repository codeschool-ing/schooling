---
title: Streaming units, partitions and the bill
version: 1
---

**This section is taught from Microsoft's documentation and was not run.** Nothing in the course's
lab measures a job's capacity or its cost.

**A Stream Analytics job is sized in streaming units**, a blend of processor and memory set on the
job, `streaming_units = 3` in the declaration of this lesson's first section. More units let the
job read faster and hold more state, the open windows of the section on windows. The job's own
metric for this is **SU % utilisation**, the share of its memory in use. Microsoft's guidance is
to keep it below about 80 per cent so that a burst does not run the job out of memory. Past that,
events queue at the input and the output falls behind, which shows up as a growing **watermark
delay**, the distance between now and the job's watermark.

## Parallel when the partitions line up

**A job runs in parallel when its input partitions, its query and its output line up.** The input is
read partition by partition; if the query's grouping keeps each partition's events apart, and the
output can be written by partition too, each partition is processed on its own and the job scales by
adding units. Microsoft calls such a query **embarrassingly parallel**. With compatibility level 1.2,
the level the declaration sets, the service aligns the query with the input's partitions without being
told; older queries say it with `PARTITION BY PartitionId`.

The checkout count of this lesson is not one of those. It counts every checkout of a minute in one
number, so the four partitions of `clicks` have to meet in one place, and the usual shape is two
steps: count per partition in parallel, then add the four counts. In the query language that is a
`WITH` step:

```sql
WITH per_partition AS (
    SELECT PartitionId, COUNT(*) AS checkouts
    FROM [clicks] TIMESTAMP BY at PARTITION BY PartitionId
    WHERE page = '/checkout'
    GROUP BY PartitionId, TumblingWindow(minute, 1)
)
SELECT System.Timestamp() AS window_end, SUM(checkouts) AS checkouts
INTO [checkouts-per-minute]
FROM per_partition
GROUP BY TumblingWindow(minute, 1)
```

The first step does the heavy part, reading and counting, once per partition; the second adds four
numbers a minute. **The partitions of lesson 22 are the ceiling here too**: a hub with four
partitions gives a job at most four parallel readers, whatever units it is given.

## A job is billed while it runs

**The bill is streaming units by the hour, for every hour the job is started**, whether one event
arrives or a million. There is no charge per event processed and none per query; a job that waits
all night for clicks that do not come costs what a busy one costs. The arithmetic below uses an
illustrative price, a round number for the sum and not Azure's: 0.11 USD per streaming unit-hour.

| job | units | hours in a 30-day month | illustrative price | month |
|---|---|---|---|---|
| checkouts per minute, always on | 3 | 730 | 0.11 USD | 240.90 USD |
| the same job, started 07:00 to 23:00 only | 3 | 16 × 30 = 480 | 0.11 USD | 158.40 USD |

**Stopping a job overnight saves a third of the bill and costs the night's windows**, and when it
starts again in the morning it has to be told where to begin: from the moment it is started, from a
time you give, or from where it stopped. The last of these reads the night's events from the event
hub, which is only possible if the hub's retention of lesson 22 covers the night. That choice is the
same one as `starting_position` in lesson 22, made for you by the service.

For real prices, the price sheet of lesson 1, with the network; it was not run for this course:

```sh
python prices.py "Stream Analytics" Standard
```

The name a service carries in the price list is Microsoft's choice, and an empty answer means the
filter matched no service rather than that the service is free.

The output side has a bill of its own: the SQL database the counts are written to, or the event hub
another job reads. And what a job promises about delivering each row exactly once to that output is
the subject of lesson 24.
