---
title: The history of every job
version: 1
---

**The driver's page and its REST interface die with the application.** Everything this lesson
measured was asked of a running driver, from inside the program. A job that finished last night, or
failed, cannot be asked anything that way.

Lesson 1's `spark-defaults.conf` has been keeping a record of every application since then, in
`~/spark-events`: `spark.eventLog.enabled` writes every event of a job, each stage and task with its
metrics, to a file. Spark's *history server* reads those files and serves the same pages and the same
REST interface for applications that are over. It needs to be told where they are, once, and
started:

```sh
echo "spark.history.fs.logDirectory file://$HOME/spark-events" >> ~/spark/conf/spark-defaults.conf
start-history-server.sh
```

It answers on port 18080, under the same `/api/v1/` paths as a driver:

```
ana@lab:~/big$ curl -s 'localhost:18080/api/v1/applications?limit=6' | jq -c '.[] | {id, name, duration: .attempts[0].duration}'
{"id":"app-20261016011258-0023","name":"collect all","duration":28581}
{"id":"app-20261016011048-0022","name":"spill","duration":125690}
{"id":"app-20261016011028-0021","name":"memory","duration":16282}
{"id":"app-20261016010937-0020","name":"shuffle files","duration":47188}
{"id":"app-20261016010816-0019","name":"jobs and stages","duration":77115}
{"id":"app-20261016010559-0018","name":"memory","duration":16396}
```

**The applications run most recently, newest first, with their duration in milliseconds.** Any of them
can be asked for its stages, its tasks and its SQL plans, exactly as a running driver was. The
browser pages at `http://localhost:18080` are the Spark UI of each, with every tab.

**On a real cluster the event logs go to shared storage**, HDFS or an object store, so that any
machine can read them and a driver that dies on a lost machine has already written what it did up to
the moment it died. A cluster without a history server is one whose failed jobs leave nothing to
read. Lesson 14 reads a finished job's stages from here.
