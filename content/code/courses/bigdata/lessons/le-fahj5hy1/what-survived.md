---
title: What survived
version: 1
---

**MapReduce as a way of writing programs is mostly gone. Its ideas are in every engine that replaced
it**, and recognising them is what makes the rest of this course easier to read.

- **The shuffle.** Partition by key, sort or hash, fetch from every producer. Spark's `groupBy`, its
  joins and its `repartition` all end in one, and lesson 7 reads its size in Spark's own counters.
  Nothing about distributing a grouping has found a way around moving every key to one place.
- **Moving the computation to the data.** Map tasks ran where their block was. Spark's locality
  levels, which lesson 3 read, are the same preference.
- **Recovery by rerunning.** A failed task is rerun from its input, which still exists, because tasks
  are deterministic functions of their input. Lesson 2 watched Spark do exactly that, and lesson 5
  names the record Spark keeps to make it possible.
- **The combiner.** Every engine aggregates partially before a shuffle when the aggregation allows
  it.
- **Counters as the first diagnosis.** Records in and out, bytes shuffled, records spilled: Spark's
  interface reports the same quantities per stage, and lessons 7 and 14 read them the way the last
  section read Hadoop's.

**And one constraint survived as a design rule**: write the work as functions of their input, with no
hidden state and no side effects. MapReduce forced it. Spark only asks for it, and a program that
ignores the request still runs, until a task is retried, as lesson 2's e-mail question showed.
