---
title: Installing Spark into the course's Python
version: 1
---

Spark is a Java program, and the usual way to install it is an archive from the Apache site, a
`SPARK_HOME` variable and a `bin` directory on the `PATH`. **For a Python program on one machine
there is a shorter way: the `pyspark` package on PyPI carries the whole of Spark inside it**, the
Java libraries included, and starts it for you when your program asks for a session. Nothing else
needs installing, because the Java 21 that Kafka runs on is the Java Spark 4.1 wants.

Install it into the course's environment, pinned like everything else:

```sh
pip install pyspark==4.1.3
```

It is a large download, and it unpacks into something larger:

```
ubuntu@stream:~/work$ pip show pyspark | head -2
```

```
ubuntu@stream:~/work$ du -sh ~/venv/lib/python3.12/site-packages/pyspark
```

Most of that is the Java libraries, in the package's `jars` directory. The package also put
Spark's own commands into `~/venv/bin`, which is already on your `PATH`, so `spark-submit` answers
from any directory:

```
ubuntu@stream:~/work$ spark-submit --version
```

The banner names three versions, and two of them are worth reading: **Spark 4.1.3**, and the Scala
version it was built with, **2.13**. The Scala version is the one that has to match when you add a
library to Spark, which is the next paragraph.

## One line for Spark to keep to itself

Spark's driver, the process your program talks to, opens a few network ports, and by default it
listens on the machine's network address and shows a web page about every running query on port
4040 of that address. In this course everything listens on `localhost` and nothing else, so tell
Spark the same:

```sh
echo 'export SPARK_LOCAL_IP=127.0.0.1' >> ~/.profile
source ~/.profile
```

Without it Spark still works, and starts each program with a warning that the machine's name
resolves to a loopback address and that it is using the network address instead.

## The Kafka connector arrives on first use

`pyspark` knows how to read files and tables. **Reading Kafka is a separate library, the connector
`spark-sql-kafka-0-10`**, and it is not in the package. Each program in this lesson asks for it by
its Maven coordinates, in one configuration line:

```python
.config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3")
```

The coordinates are the group, the artefact and the version, and two numbers in them have to agree
with what you just installed: `_2.13` is the Scala version from the banner, and `4.1.3` is Spark's.
A connector built for another Scala or another Spark fails at the first read, with a Java error
about a missing class or method that never mentions the version.

**The first program that runs with that line downloads the connector and ten libraries it depends
on from Maven Central**, about 60 MB, into `~/.ivy2.5.2`, and later runs find them there. The first
run is therefore slower than the others by however long the download takes, and it prints a long
report of what it fetched. The next section starts with that run.
