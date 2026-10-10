---
title: Installing Flink
version: 1
---

Draft.

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz.sha512
```

```sh
tar -xzf flink-2.2.1-bin-scala_2.12.tgz
mv flink-2.2.1 ~/flink
curl -fsSL -o ~/flink/lib/flink-sql-connector-kafka-5.0.0-2.2.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.2/flink-sql-connector-kafka-5.0.0-2.2.jar
```
