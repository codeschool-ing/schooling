---
title: An ecosystem, not a program
version: 1
---

**"Hadoop" names a filesystem, a cluster manager, a programming model and some twenty projects
built on them**, and which of those a person means depends on when they learned it. In 2008 it meant
HDFS and MapReduce together. By 2014 MapReduce had been split from the part that hands out machines,
YARN, and around the three grew projects that each answered a complaint about MapReduce:

| project | what it answered | where it stands |
|---|---|---|
| **HDFS** | where to keep data too large for one machine | lesson 3; still common on premises, replaced by object stores in the cloud |
| **YARN** | sharing one cluster among many programs and teams | this lesson; still common on premises, Kubernetes in lesson 13 |
| **MapReduce** | how to process that data in parallel | lesson 4; replaced by Spark for new work |
| **Hive** | writing SQL instead of Java | this lesson; its metastore outlived its engine |
| **HBase** | reading and writing single rows quickly | this lesson; a database for a narrow case |
| **ZooKeeper** | agreeing on who is in charge | runs inside HBase here, and inside Kafka until recently |
| **Pig, Oozie, Sqoop, Flume** | scripting, scheduling, importing, collecting | mostly retired, replaced by Spark, Airflow and Kafka |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-stack\" aria-label=\"The Hadoop stack in three layers. At the bottom, storage: HDFS, and HBase on top of it. In the middle, YARN, which hands out the machines. At the top, the engines that run on YARN: MapReduce, Hive, Spark. Beside them, Hive's metastore, which every engine consults for table names.\"><rect x=\"120.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">MapReduce</text><rect x=\"260.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Hive</text><rect x=\"400.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"464.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Spark</text><rect x=\"120.0\" y=\"96.0\" width=\"408.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">YARN</text><text x=\"324.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">containers and queues</text><rect x=\"120.0\" y=\"172.0\" width=\"260.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">HDFS</text><text x=\"250.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">blocks, three copies</text><rect x=\"392.0\" y=\"172.0\" width=\"136.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">HBase</text><text x=\"460.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rows by key</text><text x=\"108.0\" y=\"47.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">engines</text><text x=\"108.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resources</text><text x=\"108.0\" y=\"199.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">storage</text><rect x=\"552.0\" y=\"20.0\" width=\"156.0\" height=\"206.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Hive metastore</text><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">table names, schemas, partitions</text></svg>", "caption": "Storage at the bottom, YARN handing out machines, engines on top, and a catalog beside them all."}
```

This lesson runs the three that a data engineer still meets: YARN, because a great many clusters
still are YARN clusters; Hive's metastore, because almost every table catalogue speaks its protocol;
and HBase, because the problem it solves did not go away.

The standalone cluster of lesson 1 and YARN would both hand out the same four cores, so the standalone
cluster is stopped while YARN runs, and started again afterwards:

```sh
stop-worker.sh
stop-master.sh
sh hdfs.sh start
```

The last line starts lesson 3's HDFS, which YARN's jobs read from.
