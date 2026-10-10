---
title: Two applications, one cluster
version: 1
---

**A cluster is shared, and the cluster manager decides who gets what.** Ana starts the thirty tasks
of two seconds, and a few seconds later a colleague submits a small job of six tasks. The master's
page, eight seconds after the second job was submitted, and then what each job printed when it
finished:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'
{"name":"tasks 6x2.0","cores":0,"state":"WAITING"}
{"name":"tasks 30x2.0","cores":3,"state":"RUNNING"}
ana@lab:~/big$ spark-submit tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 23.0 s
ana@lab:~/big$ spark-submit tasks.py 6 2
WARNING: Using incubator modules: jdk.incubator.vector
16:41:09 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
16:41:28 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
6 tasks of 2 s: answer 15, 26.0 s
```

**The second job is `WAITING` with zero cores.** The first took all three when it started, as an
application in standalone mode does by default, and the master hands cores out in order of
arrival. Six tasks of two seconds would have taken about six seconds on their own; the job took 26, nearly
all of them in the queue. Nothing failed, and the only signal the colleague got was the warning
lesson 1 met in its section 06, `Initial job has not accepted any resources`. The other warning
is harmless: the first driver already held port 4040 for its page, so the second took 4041.

`spark.cores.max` caps how many cores one application may take. The same pair of jobs, with the
first capped at two:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {name, cores, state}'
{"name":"tasks 6x2.0","cores":1,"state":"RUNNING"}
{"name":"tasks 30x2.0","cores":2,"state":"RUNNING"}
ana@lab:~/big$ spark-submit --conf spark.cores.max=2 tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 32.7 s
ana@lab:~/big$ spark-submit tasks.py 6 2
WARNING: Using incubator modules: jdk.incubator.vector
16:41:51 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
6 tasks of 2 s: answer 15, 14.2 s
```

**Now both run at once.** The small job got the third core and finished in 14 seconds instead of 26.
The large one paid for it: two cores instead of three, fifteen waves instead of ten, 33 seconds
instead of 23. A cap is a decision about who waits, and somebody always does.

## How the managers differ

The standalone master knows one policy, first come first served, plus the caps an application
sets on itself. That is enough for a cluster with one team and a few jobs a day, and not for a
cluster that many teams share. The other managers have more:

- **YARN** divides the cluster into *queues* with a guaranteed share each, so the analysts' queue
  keeps 30% of the cluster however much the nightly load asks for. Lesson 12 runs one.
- **Kubernetes** gives each namespace a quota and schedules the executors as pods, so Spark shares
  a cluster with everything else that runs there. Lesson 13.
- **Dynamic allocation**, a Spark setting rather than a manager's, lets an application give back
  executors it is not using and ask for more when its tasks pile up. A job that holds three cores
  through a long idle stretch is the problem it solves, and lesson 14 prices it.

Within one application there is a choice too: **jobs from the same driver run first in, first out**
unless `spark.scheduler.mode` is set to `FAIR`, which lets a short query from one thread overtake a
long one from another. It matters for a notebook or a server that runs many small queries on one
long-lived application, and it does not change how cores are split between applications.
