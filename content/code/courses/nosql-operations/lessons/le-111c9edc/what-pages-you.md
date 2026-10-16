---
title: What wakes somebody, and what waits for the morning
version: 1
---

The last three sections showed some thirty numbers. **The mistake is to alert on all of them**, and
it is made with good intentions. Every number that ever preceded an incident gets a threshold. Six
months later the phone rings twice a night for things that fixed themselves, and the person holding
it has learnt to swipe the alert away. Lesson 16 of `observability` calls this alert fatigue
and gives the rule this section applies: **page on a symptom that needs a person now; put the cause
on a dashboard, where the person looks once paged.**

## The two questions

A signal earns a page when the answer to both is yes:

1. **Is somebody harmed now, or is data about to be lost?** Users waiting, writes refused, a copy of
   the data that will not exist after the next failure.
2. **Is there something a person must do, soon, that the system will not do by itself?**

A cache at 97% of its memory fails the first: that is what a cache with a limit looks like. A
secondary 18 seconds behind fails it too, on a quiet afternoon. The same secondary 18 hours behind
passes both, because the next failover loses those hours and nobody but a person will resynchronise
it. **Most database signals are on a dashboard; the few that page are the ones about losing data or
refusing work.**

Databases bend the "symptoms, not causes" rule in one place, and it is worth saying out loud.
Replication lag, a node down and a disk filling up are causes; users feel nothing yet. They page
anyway, because the symptom they lead to is data loss or an outage that cannot be undone once it
arrives.

## MongoDB

| page somebody | put on a dashboard |
|---|---|
| no member is `PRIMARY`, or fewer than a majority are healthy: writes are being refused | `opcounters` as rates, and `connections.current` against `available` |
| a secondary's lag approaching the oplog window, the hours of history the primary keeps: past it, the secondary needs a full resync | replication lag in seconds, for every secondary |
| operations queued (`qrw`, `arw`) for minutes, together with p99 latency above what the application promised | cache used and dirty percentages, and how often application threads are evicting |
| the disk of any member filling at a rate that reaches full within a day | slow queries per minute from the log, and the worst ten by shape |

## Redis

| page somebody | put on a dashboard |
|---|---|
| under `noeviction`, `used_memory` at `maxmemory`: writes are failing with `OOM` | `used_memory` against `maxmemory`, for a cache |
| a replica disconnected, or its byte gap growing for minutes | `evicted_keys` as a rate, and the hit ratio |
| `rejected_connections` rising: clients are being turned away | `connected_clients`, `instantaneous_ops_per_sec` |
| the server not answering `PING` | slow log entries per minute, and what `LATENCY DOCTOR` says |

The cache and the database are the same server with opposite alerts. Redis as a cache **may** evict,
and the hit ratio is a performance figure. Redis as the only home of a piece of data (lesson 14)
must not, and an eviction there is data deleted by the server on purpose.

## Cassandra

| page somebody | put on a dashboard |
|---|---|
| a node `DN` for longer than `max_hint_window`, 3 hours by default: past it, the other nodes stop keeping hints and only repair restores the writes it missed | `nodetool status` load per node, for balance |
| dropped `MUTATION_REQ` or `READ_REQ` at a sustained rate | `tpstats` pending per stage |
| coordinator p99 read or write latency above the agreed bound for several minutes | the full latency histograms |
| reads refused at `tombstone_failure_threshold` | tombstones per slice and the largest partition, per table |
| pending compactions growing for hours, or disk above the free space compaction needs | SSTables per read |

## Getting the numbers out: exporters

Nobody pages from `nodetool` typed by hand. A monitoring system scrapes the same numbers on a
schedule, keeps their history, and evaluates the rules. With Prometheus, which lesson 5 of
`observability` teaches, the usual route is an **exporter** for each product: a small process that
asks the database for its statistics and publishes them in Prometheus's text format.

| product | the commonly used exporter | what it reads |
|---|---|---|
| MongoDB | `mongodb_exporter`, maintained by Percona | `serverStatus`, `replSetGetStatus` and friends: the documents of this lesson |
| Redis | `redis_exporter` | the `INFO` sections, line by line |
| Cassandra | the Prometheus JMX exporter, run as a Java agent inside the node | the JMX metrics `nodetool` itself reads |

**None of the three was installed for this course**, and none is needed for it: everything they
publish is what the commands of this lesson printed, renamed. Names and defaults change between
versions, so read the one you install against the field it says it comes from, the way the
`mongostat` column was read against `rs.status()`.

The alert rules themselves belong to the people who run the service. The useful way to write them
is lesson 15 of `observability`: an SLO for the operations the shop cares about, the latency and
the errors its users see, and a page when the error budget is burning. The tables above are the
database half of that, the part that says data is at risk before any user has noticed.
