---
title: The task index, and cutting the work
version: 1
---

When an execution starts several tasks, every one of them runs the same image with the same
settings. **The only thing that differs is three environment variables, and the program has to use
them to decide which part of the work is its own.** Nothing else will divide it: Cloud Run starts
the containers and counts the exits, and has no idea what an order is.

## The three variables

| variable | what it holds |
|---|---|
| `CLOUD_RUN_TASK_INDEX` | this task's number, from 0 to the count minus one |
| `CLOUD_RUN_TASK_COUNT` | how many tasks this execution has |
| `CLOUD_RUN_TASK_ATTEMPT` | how many times this task has been retried, 0 on the first try |

At home nothing sets them, so you set them yourself and **play Cloud Run's part**: three
containers, each told its index. On Cloud Run they would run at the same time, up to the job's
parallelism; here they run one after the other, so that their logs do not interleave:

```
ana@laptop:~/gcp$ for i in 0 1 2; do docker run --rm -e CLOUD_RUN_TASK_INDEX=$i -e CLOUD_RUN_TASK_COUNT=3 invoices:1; done
{"severity": "INFO", "message": "task 0 of 3, attempt 0: orders [1001, 1004, 1007, 1010]"}
{"severity": "INFO", "message": "invoice for order 1001 written"}
{"severity": "INFO", "message": "invoice for order 1004 written"}
{"severity": "INFO", "message": "invoice for order 1007 written"}
{"severity": "INFO", "message": "invoice for order 1010 written"}
{"severity": "INFO", "message": "task 1 of 3, attempt 0: orders [1002, 1005, 1008]"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
{"severity": "INFO", "message": "task 2 of 3, attempt 0: orders [1003, 1006, 1009]"}
{"severity": "INFO", "message": "invoice for order 1003 written"}
{"severity": "INFO", "message": "invoice for order 1006 written"}
{"severity": "INFO", "message": "invoice for order 1009 written"}
```

**Every order was invoiced exactly once, and no task knew about the others.** Task 0 took orders
1001, 1004, 1007 and 1010, task 1 the next stride, task 2 the last. That is the property the cut
has to have, and `ORDERS[index::count]` gives it for free: the slices are disjoint and together
cover the list, whatever the count.

## Ways to cut, and what each costs

**By stride**, as here, spreads the work evenly when the items are alike, and needs the whole list
to be the same in every task. That holds for a list in the code; for a list read from a database it
holds only if every task reads it in the same order, so the query needs an `ORDER BY`.

**By range**, task 0 the first tenth, task 1 the next, keeps related items together, which matters
when an item's neighbours share a file or a cache. It spreads badly when the items differ in size.

**By hash**, the item's id modulo the count, is the stride without the list: each task can decide
alone whether an item is its own, which works for items arriving from a queue. Changing the count
changes every assignment, which is fine for a job whose state starts fresh each night and wrong for
one that remembers which task did what.

## How many tasks, and how many at once

Two numbers, which gcloud's help states precisely:

```
ana@laptop:~/gcp$ gcloud run jobs create --help | grep -E -A3 '^     --(tasks|parallelism|max-retries|task-timeout)='
     --max-retries=MAX_RETRIES
        Number of times a task is allowed to restart in case of failure before
        being failed permanently. This applies per-task, not per-job. If set to
        0, tasks will only run once and never be retried on failure.
--
     --parallelism=PARALLELISM
        Number of tasks that may run concurrently. Must be less than or equal
        to the number of tasks. Set to 0 to unset.

--
     --task-timeout=TASK_TIMEOUT
        Set the maximum time (deadline) a job task attempt can run for. In the
        case of retries, this deadline applies to each attempt of a task. If
        the task attempt does not complete within this time, it will be killed.
--
     --tasks=TASKS; default=1
        Number of tasks that must run to completion for the execution to be
        considered done.
```

`--tasks` is how many pieces, `--parallelism` how many run at the same time. **Three hundred tasks
with a parallelism of ten is about thirty rounds**, and the second number is usually the one that protects
something: the database the job writes to has a connection limit, and a job of three hundred tasks
all starting at once can exhaust it. The retry and timeout lines are section 04's subject.
