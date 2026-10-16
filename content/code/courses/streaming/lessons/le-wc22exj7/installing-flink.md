---
title: Installing Flink
version: 1
---

Kafka Streams needed nothing new: its jars came with Kafka in lesson 1. **Flink is a cluster of its
own**, a JobManager that plans and coordinates jobs and one or more TaskManagers that run them, and
it arrives the way Kafka did, as one archive from the Apache Software Foundation. Flink 2.2.1 runs
on the Java 21 the machine already has.

Download it and its checksum into your home directory. It is a large file, about 570 MB:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz.sha512
```

Compare the two strings, as you did for Kafka:

```
ubuntu@stream:~$ sha512sum flink-2.2.1-bin-scala_2.12.tgz | cut -d" " -f1
9beb619520a9b9a94d71e165f51c2c2bf67d180fee2a6f88a85b05f23b513efd12897669b6b8b000a7f16c8c8835c3bdb1e7b83133ef63056dc98a2a67105f60
```

```
ubuntu@stream:~$ cut -d" " -f1 flink-2.2.1-bin-scala_2.12.tgz.sha512
9beb619520a9b9a94d71e165f51c2c2bf67d180fee2a6f88a85b05f23b513efd12897669b6b8b000a7f16c8c8835c3bdb1e7b83133ef63056dc98a2a67105f60
```

The `scala_2.12` in the name is the Scala version Flink's own internals were built with, and like
Kafka's `2.13` it does not matter to you.

## The Kafka connector

Flink's archive knows files, but not Kafka. **The connector is a separate jar, versioned on its
own**: `5.0.0-2.2` is version 5.0.0 of the connector, built for Flink 2.2. A jar in Flink's `lib`
directory is loaded by every job, so unpack Flink and put the connector there:

```sh
tar -xzf flink-2.2.1-bin-scala_2.12.tgz
mv flink-2.2.1 ~/flink
curl -fsSL -o ~/flink/lib/flink-sql-connector-kafka-5.0.0-2.2.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.2/flink-sql-connector-kafka-5.0.0-2.2.jar
```

The `sql` in its name means the fat version of the connector, with Kafka's own client packed
inside it, which is the one Flink's SQL wants.

## Two changes to the configuration

Flink's settings are in `~/flink/conf/config.yaml`. Out of the box they give the JobManager 1.6 GB
of memory and the TaskManager 1.7 GB, which is most of the virtual machine before Kafka has taken
anything. **A gigabyte each is plenty for this lesson.** And the web page Flink serves on port 8081
listens on every address of the machine unless told otherwise; tell it `localhost`, as everything
else in this course does:

```sh
cd ~/flink/conf
sed -i -e 's/size: 1600m/size: 1024m/' -e 's/size: 1728m/size: 1024m/' config.yaml
sed -i 's/^rest:$/rest:\n  bind-address: localhost/' config.yaml
```

The first line changes the two memory sizes, and the second adds a line under the `rest:` heading.
Check both landed:

```
ubuntu@stream:~$ grep -n -E "size: |bind-address: localhost" ~/flink/conf/config.yaml
60:      size: 1024m
95:      size: 1024m
173:  bind-address: localhost
182:  # bind-address: localhost
```

Lines 60 and 95 are the two sizes and line 173 is the new one. The last line was already in the
file, behind a `#`: a comment, which Flink ignores.

## Starting it

```
ubuntu@stream:~$ ~/flink/bin/start-cluster.sh
Starting cluster.
Starting standalonesession daemon on host stream.
Starting taskexecutor daemon on host stream.
```

Two daemons, a "standalone session", which is the JobManager, and a "task executor", the
TaskManager. They take a few seconds to open their ports:

```
ubuntu@stream:~$ ss -ltn | grep -E ":8081|:6123"
LISTEN 0      4096       127.0.0.1:6123       0.0.0.0:*          
LISTEN 0      4096       127.0.0.1:8081       0.0.0.0:*          
```

Port 6123 is how the TaskManager talks to the JobManager, and 8081 is the web page and the REST
interface that the `flink` command uses. Both are on `127.0.0.1`. **Like the Kafka cluster, Flink
does not start by itself** when the virtual machine starts; `~/flink/bin/start-cluster.sh` brings
it back and `~/flink/bin/stop-cluster.sh` stops it.
