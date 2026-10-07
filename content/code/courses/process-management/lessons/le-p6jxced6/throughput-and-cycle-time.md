---
title: Throughput and cycle time, as a pair
version: 1
---

Lesson 3 computed two numbers from the Agenda team's board: **throughput**, the number of items finished per week, and **cycle time**, how long each item took from the commitment point to done. They are the foundation of flow measurement, and they are most useful read together.

## What each one says

Throughput answers **how much**. The Agenda team finished 4, 6, 5 and 5 items in the four weeks of March, about five a week. It is the number to forecast with when the question is *how many of these thirty items will be done by June?*

Cycle time answers **how long for one**. The median was 7 days and the 85th percentile 11.6. It is the number to give when the question is *when will this item be done, now that we have started it?*

## Why read them together

Either number alone can be improved in a way that hides a problem.

**Throughput can rise while things get worse.** Split every item into three and throughput triples, with the same work delivered. Count only how many items finish, and a team can look faster by cutting items smaller without finishing anything sooner.

**Cycle time can fall while things get worse.** Stop starting difficult items, and the ones that are started finish quickly; the hard work waits in Ready, outside the clock. The cycle time looks excellent while the backlog of hard items grows.

Read together, the tricks show. More items finishing with the same cycle time is more work done; the same items finishing faster is a shorter wait for each. A team that changes one without the other has usually changed how it counts.

## The scatter, and the ageing items

The most useful single picture of flow is the one lesson 3 drew: one dot per finished item, at the date it finished and the days it took, with the 85th-percentile line across it. Two habits make it a management tool:

- **Look at the dots above the line** in every review. Each is an item that waited somewhere, and asking where is cheaper than any process change.
- **Watch the items still in progress** against the same line. An item that has been in Developing for ten days, in a team whose 85th percentile is 11.6, is about to become one of the dots above the line. Kanban's measure for this, **work item age**, is the only one of the four that warns before the item is late rather than after. The `delivery-metrics` course gives it a lesson of its own, its third.
