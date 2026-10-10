---
title: The processes of one running job
version: 1
---

**Every role in the last section is a process you can list.** Start a job that keeps the cluster
busy for about twenty seconds, with the program of the last section, and look at the machine while
it runs: sixty tasks of one second each.

In one terminal:

```sh
spark-submit tasks.py 60 1
```

and in a second one, opened while that runs, ask `ps` for every Java process and keep the name of
the Spark class each one runs:

```
ana@lab:~/big$ ps -eo pid=,rss=,args= | awk '/java/ {for (i = 3; i <= NF; i++) if ($i ~ /^org\.apache\.spark/) print $1, int($2/1024) " MB", $i}'
9710 239 MB org.apache.spark.deploy.master.Master
9807 219 MB org.apache.spark.deploy.worker.Worker
9898 217 MB org.apache.spark.deploy.worker.Worker
9988 220 MB org.apache.spark.deploy.worker.Worker
10094 370 MB org.apache.spark.deploy.SparkSubmit
10199 245 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
10209 241 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
10227 243 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
```

**Eight processes.** The master and the three workers were there before the job and will be there
after it. `SparkSubmit` is the driver, your program. The three `CoarseGrainedExecutorBackend` are
the executors the workers started for this application, one each; when the job ends they end with
it. Each holds about 250 MB of memory before it has done much at all, which is the cost of a Java
virtual machine and is paid once per executor, not once per task.

The master's page lists the application and what it was given:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {id, name, cores, memoryperexecutor, state}'
{"id":"app-20261010163906-0000","name":"tasks 60x1.0","cores":3,"memoryperexecutor":768,"state":"RUNNING"}
```

**All three cores, and 768 MB per executor**, the value `spark-defaults.conf` set. Nothing told the
master to give it every core: in standalone mode an application takes every core it can get unless
it says otherwise, and section 05 is about what that costs a second application.

The driver has a page of its own, on port 4040, and a REST interface beside it that answers in JSON.
It is where the course reads jobs, stages and tasks from in lessons 7 and 8. The application's id
first, then its executors:

```
ana@lab:~/big$ curl -s localhost:4040/api/v1/applications | jq -r '.[0].id'
app-20261010163906-0000
ana@lab:~/big$ curl -s localhost:4040/api/v1/applications/app-20261010163906-0000/executors | jq -c '.[] | {id, hostPort, totalCores}'
{"id":"driver","hostPort":"localhost:35571","totalCores":0}
{"id":"2","hostPort":"127.0.0.1:38055","totalCores":1}
{"id":"1","hostPort":"127.0.0.1:35331","totalCores":1}
{"id":"0","hostPort":"127.0.0.1:42703","totalCores":1}
```

Three executors with one core each, and a fourth entry, `driver`, with none: the driver runs no
tasks. Every executor's address is `127.0.0.1`, because they all live on this one machine. On a
real cluster each would name a different host, and section 10 meets the one feature of Spark that
notices the difference.
