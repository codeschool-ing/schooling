---
title: Losing the driver, and losing the master
version: 1
---

**The driver is the one process whose loss the job does not survive.** It holds the plan, the list
of finished tasks and the partial results, and nothing else in the cluster has a copy. The same job,
and twelve seconds in, the driver:

```
ana@lab:~/big$ pgrep -f deploy.SparkSubmit
15144
ana@lab:~/big$ kill -9 15144
```

What the first terminal printed:

```
ana@lab:~/big$ spark-submit tasks.py 60 1; echo "exit status $?"
WARNING: Using incubator modules: jdk.incubator.vector
bash: line 1: 15144 Killed                  spark-submit tasks.py 60 1
exit status 137
```

**No error from Spark, because the process that would have reported it is the one that died.** Exit
status 137 is signal 9 again, and the work done so far is gone. The executors noticed
their driver had vanished and exited. Now ask the master how the application ended:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.completedapps[] | select(.name == "tasks 60x1.0") | {name, state, duration}' | tail -n 1
{"name":"tasks 60x1.0","state":"FINISHED","duration":8515}
```

**`FINISHED`.** The master's word for an application that is no longer running, whatever the
reason. A monitoring check that trusted the master's state would report this job as a success.
Whether a job worked is answered by what it wrote and by the driver's exit code, and never by the
cluster manager's opinion.

## Protecting the driver

There are two ways, and the lab can show you why one of them is not open to you here.

**Run the driver inside the cluster.** By default the driver runs where you typed `spark-submit`,
in *client* mode: close the laptop and the job dies. In *cluster* mode the cluster manager starts
the driver on one of its workers, and the standalone master, given `--supervise`, restarts it if it
fails. Restarted means from the beginning: the work is lost either way, but nobody has to notice
and resubmit. For a Python program, the standalone master refuses:

```
ana@lab:~/big$ spark-submit --deploy-mode cluster tasks.py 3 1
WARNING: Using incubator modules: jdk.incubator.vector
Exception in thread "main" org.apache.spark.SparkException: Cluster deploy mode is currently not supported for python applications on standalone clusters.
	at org.apache.spark.deploy.SparkSubmit.error(SparkSubmit.scala:1065)
	at org.apache.spark.deploy.SparkSubmit.prepareSubmitEnvironment(SparkSubmit.scala:300)
	at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:962)
	at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:203)
	at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:226)
	at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:95)
	at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1168)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1177)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
```

YARN and Kubernetes run Python drivers in cluster mode, and lessons 12 and 13 do.

**Make the job cheap to restart.** A job that writes its output in stages, each one committed when
it is done, can be restarted from the last committed stage instead of from nothing. This is a
property of how the job is written, and the open table formats of lesson 11 exist partly to make it
easy.

## The master is a single point too

The lab has one master. Kill it, and running applications carry on with the executors they already
have, because the driver talks to its executors directly. But no new application can start and no
lost executor can be replaced until it is back. The standalone master can run with standbys that
take over through ZooKeeper, a small service for electing a leader; YARN's ResourceManager has the
same arrangement. This lab does not run one, and it was not set up for this course.
