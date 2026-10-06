---
title: The course, looking back
version: 1
---

Twelve lessons ago, Ana's question was why the shop's reports should not run on the database that takes its orders.
Every lesson since has been one part of the answer, and together they make a warehouse that can be trusted, explained
and changed:

- **Lessons 1 and 2**: two workloads, two shapes of database; facts, dimensions, and how each measure adds up.
- **Lessons 3 and 4**: the star and the snowflake, conformed and role-playing dimensions, the grain, surrogate keys,
  unknown members and bridges.
- **Lesson 5**: history, in every type of slowly changing dimension, built from a log of changes.
- **Lesson 6**: where to stop normalising, measured in rows written and bytes stored, and the three schools.
- **Lessons 7 and 8**: why a warehouse is parallel and columnar, and what each costs.
- **Lessons 9 and 10**: the same star in three cloud warehouses and in a lakehouse of Delta tables.
- **Lessons 11 and 12**: who owns the model, how its numbers are made to agree, and how what it means is written down.

One idea ran through all twelve. **The model is a set of decisions about meaning**: what a row is, what a customer was
on the day they bought, what revenue includes. Every technology in the course, from a type 2 dimension to a Delta log, is
a way of keeping those decisions intact as data moves and grows. The products change every few years; the decisions do
not.

What comes next is keeping it loaded. `pipelines-etl` takes this model as its target: extracting incrementally rather
than whole, loading type 2 dimensions every night, scheduling, retrying, testing, and the contracts and documentation
this lesson began, built into a pipeline that runs without anybody watching.
