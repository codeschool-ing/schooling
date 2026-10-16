---
title: A cluster of three workers, on one machine
version: 1
---

**A Spark cluster is a set of processes, and nothing says they have to be on different
computers.** A *master* keeps the list of workers and hands their cores to whoever asks. Each
*worker* offers some cores and some memory, and starts the processes that do the actual work when a
job is given those resources. Lesson 2 takes those roles apart; this section starts them.

On a real cluster each worker is a machine of its own. Here all three share yours, and that is the
one thing in this lab that is not what it pretends to be. The processes are real and separate: a
worker that dies takes its data with it, and data moving from one worker to another is serialised,
written and read back exactly as it would be across a network. What is missing is the network's
slowness, and lesson 7 puts numbers on what that hides.

## Three configuration files

Spark reads its settings from `~/spark/conf`. In the machine's shell:

```sh
cd ~/spark/conf
cat > spark-env.sh <<'END'
SPARK_LOCAL_IP=127.0.0.1
SPARK_MASTER_HOST=localhost
SPARK_WORKER_INSTANCES=3
SPARK_WORKER_CORES=1
SPARK_WORKER_MEMORY=1g
END
cat > spark-defaults.conf <<END
spark.master            spark://localhost:7077
spark.executor.memory   768m
spark.eventLog.enabled  true
spark.eventLog.dir      file://$HOME/spark-events
END
cat > log4j2.properties <<'END'
rootLogger.level = warn
rootLogger.appenderRef.stderr.ref = console
appender.console.type = Console
appender.console.name = console
appender.console.target = SYSTEM_ERR
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{HH:mm:ss} %p %c{1}: %m%n
logger.native.name = org.apache.hadoop.util.NativeCodeLoader
logger.native.level = error
END
mkdir -p ~/spark-events
cd ~/big
```

**`spark-env.sh`** is read by the scripts that start the master and the workers. The first two lines
keep every process on the machine's own loopback address, so nothing listens on the network and no
other computer can reach your cluster. The last three ask for three workers of one core and 1 GB
each.

**`spark-defaults.conf`** is read by every program you submit. `spark.master` says where the master
is, so you never have to type it. `spark.executor.memory` is how much of a worker's gigabyte each
job's process may use, and lesson 7 explains why it is less than the whole. The last two lines keep
a record of every job in `~/spark-events`, which lesson 7 reads back. That heredoc is not quoted, so
`$HOME` becomes your home directory as the file is written; a path in this file has to be absolute.

**`log4j2.properties`** sets how much Spark says while it runs. Spark's own default prints a line
for nearly everything it does, which buries what you came to read. This file keeps warnings and
errors, sends them to the error stream, and silences one warning about a native library that Spark
does not need.

## Starting it

```sh
start-master.sh
start-worker.sh spark://localhost:7077
```

```
ana@lab:~/big$ start-master.sh
starting org.apache.spark.deploy.master.Master, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.master.Master-1-lab.out
ana@lab:~/big$ start-worker.sh spark://localhost:7077
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-1-lab.out
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-2-lab.out
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-3-lab.out
```

Four Java processes are now running: one master and three workers. Each script printed where its
process writes its log, which is the first place to look when one of them does not come up.

The master answers on port 8080 with a page for a browser and, at `/json/`, the same facts as data.
`curl` fetches it, and `jq` keeps the fields that matter:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {host, port, cores, memory, state}'
{"host":"127.0.0.1","port":45749,"cores":1,"memory":1024,"state":"ALIVE"}
{"host":"127.0.0.1","port":46219,"cores":1,"memory":1024,"state":"ALIVE"}
{"host":"127.0.0.1","port":41191,"cores":1,"memory":1024,"state":"ALIVE"}
```

Three workers, each with one core and 1024 MB, all `ALIVE`. Every port after `127.0.0.1:` is
chosen at random when a worker starts, so yours will differ.

**To see the pages in a browser**, the browser has to reach port 8080 of the machine. Installed on
Ubuntu or in WSL 2, `http://localhost:8080` works as it is. In a virtual machine, the cluster only
listens inside the machine, which is the point of `SPARK_LOCAL_IP`; an SSH tunnel brings one port
to your computer, `ssh -L 8080:localhost:8080 you@the-machine`. The course reads the same pages as
JSON with `curl` throughout, so the browser is a convenience and never a requirement.

## Stopping it, and starting it again

The cluster does not start with the machine. After a restart, or when you want the memory back:

```sh
stop-worker.sh
stop-master.sh
```

and `start-master.sh` with `start-worker.sh spark://localhost:7077` bring it back. A job submitted
while the cluster is down fails within a minute, and section 06 shows what it says.
