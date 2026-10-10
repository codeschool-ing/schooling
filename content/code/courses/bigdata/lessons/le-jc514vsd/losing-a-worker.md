---
title: Losing a worker
version: 1
---

**A worker is a machine's offer of resources, so killing one is the closest the lab comes to
pulling a machine's power cable.** The same job, and twelve seconds in, the first worker process:

```
ana@lab:~/big$ pgrep -f deploy.worker.Worker | head -n 1
9807
ana@lab:~/big$ kill -9 9807
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {port, state}'
{"port":42487,"state":"DEAD"}
{"port":40871,"state":"ALIVE"}
{"port":42343,"state":"ALIVE"}
```

**The master marked it `DEAD` within three seconds**, because the worker's connection closed. On a
real cluster, where a machine that loses power closes nothing, the master waits for its heartbeats
to stop: `spark.worker.timeout`, sixty seconds by default. The job's side:

```
ana@lab:~/big$ spark-submit tasks.py 60 1
WARNING: Using incubator modules: jdk.incubator.vector
16:43:06 ERROR TaskSchedulerImpl: Lost executor 2 on 127.0.0.1: worker lost: 127.0.0.1:42487 got disassociated
60 tasks of 1 s: answer 1770, 32.3 s
```

The executor on that worker went down with it, and the driver's message says why: `worker lost`.
Its task ran again elsewhere and the answer is right. **But nothing replaced the worker**, because
there was no other machine to replace it with. The job finished on two cores and took 32 seconds
instead of about 22, half again as long: the cluster lost a third of its capacity and the job paid
for it in full.

That is the ordinary state of a large cluster, and it is why capacity is planned with slack. A
cluster sized so that the nightly jobs finish just in time with every machine healthy is a cluster
whose jobs are late whenever one machine is not, and on a thousand machines that is every night.

To bring the lab back to three workers, stop the survivors and start all three again:

```sh
stop-worker.sh
start-worker.sh spark://localhost:7077
```

## What a lost machine takes with it

Here the lost worker took only a task in progress. Two other things can live on a machine, and
both are covered later:

- **Results of a finished stage, kept on that machine's disk for the next stage to read.** If they
  are lost, the tasks that made them have to run again too. Lesson 7 shows where these *shuffle
  files* live.
- **Data that was cached in its executor's memory.** Lost with it, and recomputed from its lineage
  the next time it is needed. Lesson 9.

**And the data itself.** Here the input is a file on the one disk every process shares. On a real
cluster the input lives on the workers' disks, and a lost machine would take its share of the data
with it unless the filesystem kept copies elsewhere. That is the whole subject of lesson 3.
