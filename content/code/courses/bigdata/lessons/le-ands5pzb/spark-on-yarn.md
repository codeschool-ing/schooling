---
title: Spark on YARN
version: 1
---

**Spark runs on YARN without a Spark cluster at all**: the executors are YARN containers, asked for
by the driver like any other application's. A job needs only `--master yarn` and to know where the
cluster's configuration is, in `HADOOP_CONF_DIR`. The count of lesson 4, in Spark, reading the same
file from HDFS. Save this as `~/big/kinds_yarn.py`:

```schooling-example
{
  "language": "python",
  "file": "kinds_yarn.py",
  "parts": [
    {
      "code": "\"\"\"Lesson 4's count of events by kind, as a Spark job submitted to YARN.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"kinds on yarn\").getOrCreate()\n"
    },
    {
      "code": "SCHEMA = \"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, book_id INT, device STRING\"\nclicks = spark.read.schema(SCHEMA).csv(\"hdfs:///raw/clicks-2025.csv\")\n",
      "note": "**The same file the streaming job read**, from HDFS: lesson 3's single CSV of the year, with no header line. The cluster's configuration says where HDFS is, so `hdfs:///` needs no host."
    },
    {
      "code": "for row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n",
      "note": "**In cluster mode this `print` does not reach your terminal**: the driver runs in a container on the cluster, and what it prints goes to that container's log."
    }
  ]
}
```

Submitted to the analysts' queue in *cluster mode*:

```
ana@lab:~/big$ time HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop spark-submit --master yarn --deploy-mode cluster --queue analysts --driver-memory 512m --executor-memory 512m --num-executors 1 --conf spark.driver.memoryOverhead=256m --conf spark.executor.memoryOverhead=256m kinds_yarn.py
WARNING: Using incubator modules: jdk.incubator.vector
05:07:54 WARN Client: Neither spark.yarn.jars nor spark.yarn.archive is set, falling back to uploading libraries under SPARK_HOME.

real	1m34.003s
user	0m14.427s
sys	0m3.351s
ana@lab:~/big$ yarn application -list -appStates FINISHED 2>/dev/null
Total number of applications (application-types: [], states: [FINISHED] and tags: []):2
                Application-Id	    Application-Name	    Application-Type	      User	     Queue	             State	       Final-State	       Progress	                       Tracking-URL
application_1792137929690_0002	       kinds_yarn.py	               SPARK	       ana	root.analysts	          FINISHED	         SUCCEEDED	           100%	                                N/A
application_1792137929690_0001	streamjob9869232074237175939.jar	           MAPREDUCE	       ana	root.nightly	          FINISHED	         SUCCEEDED	           100%	http://lab:19888/jobhistory/job/job_1792137929690_0001
ana@lab:~/big$ yarn logs -applicationId application_1792137929690_0002 -log_files stdout 2>/dev/null | grep -v '^$'
Container: container_1792137929690_0002_01_000001 on lab_38703
LogAggregationType: AGGREGATED
==============================================================
LogType:stdout
LogLastModifiedTime:Fri Oct 16 05:09:23 -0300 2026
LogLength:58
LogContents:
cart 1920654
purchase 959814
search 1920318
view 19199214
End of LogType:stdout
***********************************************************************
Container: container_1792137929690_0002_01_000002 on lab_38703
LogAggregationType: AGGREGATED
==============================================================
LogType:stdout
LogLastModifiedTime:Fri Oct 16 05:09:23 -0300 2026
LogLength:0
LogContents:
End of LogType:stdout
***********************************************************************
```

**In cluster mode the driver runs on the cluster, inside the ApplicationMaster's container**, and the
machine that submitted the job can disconnect once it is accepted. That is how a scheduled job should
run: a laptop closing its lid does not kill the nightly load. It is also why the counts did not
appear: `print` wrote to the driver's standard output, which is a file in the container's log, and
`yarn logs` fetches it from HDFS once the application has finished. In *client mode*, the default,
the driver runs where `spark-submit` was typed and prints there, which suits a notebook and nothing
that has to outlive a terminal. **The standalone cluster of lesson 1 cannot run a Python driver in
cluster mode at all**; YARN and Kubernetes can.

The memory flags are there because of the queue. The analysts' 30% is about 1.8 GB, and a container
is the memory asked for plus an overhead for everything outside the Java heap, 384 MB at least by
default. A driver and one executor of 512 MB each, with 256 MB of overhead, fit in two containers of
768 MB; with the defaults they would not have fitted at all, and the application would have waited for
room that never came.

**The warning about `spark.yarn.jars` is Spark uploading its own jars, about 460 MB, to HDFS for every
application**, so that the containers can start Spark. Packing them once into an archive in HDFS and
naming it in `spark.yarn.archive` saves that on every submission, and is the first thing done on a
cluster where Spark runs on YARN.
