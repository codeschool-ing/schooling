---
title: SQL over the network
version: 1
---

**HiveServer2 is the other half of Hive that outlived its engine**: a server that takes SQL from any
client over JDBC or ODBC, the way a database does, and returns rows. Business intelligence tools,
notebooks and other programs connect to it without knowing anything about Spark or HDFS. Spark ships a
server that speaks the same protocol, the *Thrift server*, and `beeline`, Hive's command-line client.

The Thrift server is an ordinary Spark application that stays up and runs whatever SQL arrives. It
takes the metastore with it, so the tables of the last section are there by name:

```
ana@lab:~/big$ start-thriftserver.sh
starting org.apache.spark.sql.hive.thriftserver.HiveThriftServer2, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.sql.hive.thriftserver.HiveThriftServer2-1-lab.out
ana@lab:~/big$ beeline -u jdbc:hive2://localhost:10000 -n ana --silent=true -e 'SHOW TABLES IN shop; SELECT kind, count(*) AS events FROM shop.clicks WHERE day = "2025-03-14" GROUP BY kind ORDER BY kind;'
WARNING: Using incubator modules: jdk.incubator.vector
+------------+------------+--------------+
| namespace  | tableName  | isTemporary  |
+------------+------------+--------------+
| shop       | books      | false        |
| shop       | clicks     | false        |
+------------+------------+--------------+
+-----------+---------+
|   kind    | events  |
+-----------+---------+
| cart      | 5203    |
| purchase  | 2588    |
| search    | 5370    |
| view      | 52592   |
+-----------+---------+
```

**The same tables, queried from another process by JDBC**, and the query ran on the standalone
cluster as a job of the Thrift server's application. 52,592 views on 14 March, which is lesson 6's
65,753 events of that day split by kind.

This is how a cluster becomes a database for people who will never write a Spark program. It is also
a single driver serving every user, so one person's enormous query competes with everybody else's,
which is the problem YARN's queues solve for applications and a reason managed warehouses exist.
Stop the server when done, since it holds cores:

```sh
stop-thriftserver.sh
```
