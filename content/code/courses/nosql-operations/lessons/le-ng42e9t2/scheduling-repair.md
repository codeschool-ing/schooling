---
title: Scheduling repair, and what happens when it stops
version: 1
---

Lesson 18 ended on a rule, and this lesson has shown the machinery behind it. **Every replica of
every table must be repaired at least once every `gc_grace_seconds`**, ten days by default, or a
delete that missed a replica can come back. Hints and read repair narrow the gaps; only repair
closes them, and only if it runs. Repair is not something Cassandra 5.0.9 runs for you:

```
ana@vm:~$ docker logs c1 2>&1 | grep -i "auto-repair"
INFO  [main] 2026-10-10T20:19:57,167 StorageService.java:1466 - Auto-repair service is disabled via JVM property, skipping setup
```

That line, from `c1`'s start-up, is the node saying that its built-in automatic repair is switched
off, and it is off unless somebody turns it on. In practice the schedule is somebody's job.

## A schedule that meets the rule

`nodetool repair` repairs the ranges the node holds a copy of, which with three copies is three times
the node's own share; run on every node, each range is repaired three times. **`nodetool repair -pr`,
primary range, repairs only the ranges the node owns as first replica**, so running it once on every
node covers every range exactly once. It was not run for this lesson, whose cluster has three
nodes and was repaired whole. It is the shape of most schedules:

- run `nodetool repair -pr` on one node at a time, never on all at once, because a repair reads a
  lot of data and streams between nodes;
- go round every node within a period comfortably shorter than `gc_grace_seconds`: seven days for
  the default ten leaves room for a failed run to be noticed and rerun;
- alert when a node's last successful repair is older than that period, not only when a repair
  fails, because a repair that never starts never fails.

With three nodes that is a cron line per node on different days. With thirty it is a job for a tool.
**Cassandra Reaper** is the open-source one most teams use: it splits each node's ranges into small
segments, repairs them a few at a time at a pace you set, retries failures, and shows each table's
last repair in a web page. It was not installed for this course; it runs beside the cluster as its
own service.

## When repair stops

The failure is quiet, which is what makes it dangerous. A repair job breaks after an upgrade, or a
node's repair keeps timing out, or the person who ran it by hand leaves. Nothing errors in the
application. Each week, though:

1. Replicas drift further apart through dropped writes and nodes that were down past the hint window.
   Reads at `QUORUM` still answer correctly, through read repair, so nobody notices.
2. Ten days pass, and tombstones older than `gc_grace_seconds` are purged by compaction on the nodes
   that had them.
3. Any delete that a stale replica missed is now unrecoverable. The next repair, or the next read at
   `ALL`, brings the deleted rows back, as lesson 18 showed on the wish list.

So the cost of a stopped repair is not paid on the day it stops. **It is paid on the day somebody
fixes it**, when the first successful repair in weeks dutifully copies every forgotten row back. If
repair has not run for longer than `gc_grace_seconds`, treat the cluster as possibly holding
resurrected data: check the tables where deletes matter, and look at lesson 18's advice for nodes
that were down that long.

## The three, side by side

| mechanism | when it runs | what it covers | what it does not |
| --- | --- | --- | --- |
| hinted handoff | when a node down less than `max_hint_window` returns | writes the coordinator saw while it was down | longer outages, lost coordinators, writes dropped by a live replica |
| read repair | during a read that asks more than one replica | the rows read | rows nobody reads, reads at `ONE` |
| repair | when somebody, or a tool, runs it | every row of every range repaired | nothing, if it runs within `gc_grace_seconds` |

The first two make the cluster mostly right most of the time. The third is what makes "mostly" a
promise. Lesson 20 is about the numbers that say a cluster needs attention before a customer does.
