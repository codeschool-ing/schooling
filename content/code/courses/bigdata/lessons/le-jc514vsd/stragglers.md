---
title: The task that is slow, and the copy that never ran
version: 1
---

**A task that fails is easy. A task that is merely slow is harder**, because nothing tells the
driver anything is wrong. A machine whose disk is dying, or whose memory is full of somebody else's
process, keeps running tasks at a fraction of the speed of the others. The job waits for the
slowest task, so one sick machine sets the pace for everybody. Those slow tasks are called
*stragglers*.

This program stages one. Its twelve tasks take a second each, except the first attempt of task 5,
which takes thirty. Save it as `~/big/straggler.py`:

```schooling-example
{
  "language": "python",
  "file": "straggler.py",
  "parts": [
    {
      "code": "\"\"\"Twelve tasks of one second, and one of them stuck on a slow machine.\"\"\"\nimport time\n\nfrom pyspark import TaskContext\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"straggler\").getOrCreate()\n\n\n"
    },
    {
      "code": "def work(slice_):\n    ctx = TaskContext.get()\n    slow = ctx.partitionId() == 5 and ctx.attemptNumber() == 0\n    time.sleep(30 if slow else 1)\n    return sum(slice_)\n\n\nstart = time.time()\ntotal = spark.sparkContext.parallelize(range(12), 12).glom().map(work).sum()\nprint(f\"answer {total}, {time.time() - start:.1f} s\")\n",
      "note": "**The staging is here.** Task 5's first attempt sleeps for 30 seconds, the way a task does on a machine with a failing disk. Any later attempt of the same task, on any executor, takes the normal second."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit straggler.py
WARNING: Using incubator modules: jdk.incubator.vector
answer 66, 33.1 s
```

**Thirty-odd seconds for eleven seconds of work.** Eleven tasks finished in the first few seconds,
and two cores sat idle for the rest of the run while task 5 slept.

**Speculative execution** is Spark's answer: when most of a stage's tasks have finished and one has
run far longer than the median, launch a second copy of it elsewhere and keep whichever finishes
first. It is off by default, `spark.speculation`, because a copy costs a core. The same program
with it on, and with Spark's informational messages let through so that its reasoning is visible:

```
ana@lab:~/big$ spark-submit --conf spark.speculation=true --conf spark.log.level=INFO straggler.py 2>&1 | grep -E 'speculat|answer'
16:44:51 INFO TaskSchedulerImpl: Starting speculative execution thread
16:45:04 INFO TaskSetManager: Marking task 5 in stage 0.0 (on 127.0.0.1) as speculatable because it ran more than 3084.0 ms(1speculatable tasks in this taskset now)
16:45:30 INFO DAGScheduler: Job 0 is finished. Cancelling potential speculative or zombie tasks for this job
answer 66, 33.0 s
```

**Spark noticed the straggler, marked it speculatable, and never ran the copy.** The answer took
just as long. This is the one place in the course where the single machine changes the outcome
rather than just the numbers, and the reason is a deliberate rule: **a speculative copy is never
launched on the same host as the original**, because the commonest cause of a straggler is the
machine, and a copy on the same machine would be just as slow. Every executor in this lab is on
`127.0.0.1`, so there is nowhere else to go.

On a real cluster the copy runs on another machine, takes a second, and the job finishes about
twenty-five seconds sooner. Keep the shape of this result in mind for lesson 8, where a slow task is
slow because of its data and not its machine. **Speculation cannot help there**: a copy of a task
with too much data has exactly as much data to get through.
