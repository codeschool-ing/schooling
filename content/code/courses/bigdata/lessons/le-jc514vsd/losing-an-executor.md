---
title: Losing an executor
version: 1
---

**Start the sixty tasks of one second again**, and twelve seconds in, from the second terminal,
kill one of the executors. `pgrep -f` finds a process by its command line, and `head -n 1` keeps
the first of the three:

```
ana@lab:~/big$ pgrep -f CoarseGrainedExecutorBackend | head -n 1
13651
ana@lab:~/big$ kill -9 13651
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {port, coresused}'
{"port":42487,"coresused":1}
{"port":40871,"coresused":1}
{"port":42343,"coresused":1}
```

Four seconds after the kill, every worker again reports one core in use. The worker whose executor
died told the master, and the master asked it to start a new one for the same application. What
the job printed in the first terminal:

```
ana@lab:~/big$ spark-submit tasks.py 60 1
WARNING: Using incubator modules: jdk.incubator.vector
16:42:32 ERROR TaskSchedulerImpl: Lost executor 1 on 127.0.0.1: Command exited with code 137
16:42:32 WARN TaskSetManager: Lost task 1.0 in stage 0.0 (TID 1) (127.0.0.1 executor 1): ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason: Command exited with code 137
60 tasks of 1 s: answer 1770, 24.1 s
```

**One error, one warning, and the right answer.** Code 137 is how Linux reports a process killed by
signal 9 (128 + 9). The driver noticed the executor was gone, marked the task it was running as
lost, and sent that task to another executor. The job took 24 seconds instead of about 22: the
lost task ran twice, and the new executor needed a moment to start.

Three things made this cheap, and they are the three steps of the last section:

- **Notice**: the executor's connection to the driver closed when the process died, so there was
  no timeout to wait for. A machine that loses power gives no such signal, and then the driver
  waits for the executor's heartbeats to stop, which takes longer.
- **Know what was lost**: only the tasks running on that executor at that moment. The tasks it had
  already finished had sent their results back to the driver.
- **Redo only that**: a task is a function applied to a slice of data that still exists, so
  running it again elsewhere gives the same result.

That last condition is less obvious than it sounds, and lesson 5 gives it a name, the *lineage*:
Spark can recompute any lost piece because it remembers how each piece was made. A task that wrote
to a database as a side effect would write twice when it ran twice, and Spark could not know.
**Tasks are retried because they are assumed to be repeatable**, and keeping them so is the
programmer's half of the bargain.

Spark gives up when the same task fails four times, `spark.task.maxFailures`, on the reasoning
that a task failing everywhere is a bug in the task and not a broken machine.
