---
title: HBase
version: 1
---

**HBase answers the question everything else in this course is bad at: one row, now.** Spark and
Hive read whole files to answer questions about many rows. A lookup of one visitor's last events, by
a website while the visitor waits, needs milliseconds and a few rows. HBase is Google's Bigtable
design on Hadoop: a table of rows sorted by a *row key*, split into ranges called *regions*, each
served by a *region server*, with everything stored in HDFS files that are written once and never
changed, lesson 3's rule.

**It works around that rule by never editing a file.** A write goes to a log and to memory; when
memory fills, it is written out as a new sorted file; and files are merged in the background, a
*compaction*, which is Delta's `OPTIMIZE` of lesson 11 run continuously. A read checks memory and the
files that could hold the key, using the same kind of bloom filters as lesson 10.

HBase is a separate download from the Apache Software Foundation. In standalone mode the master, a
region server and the ZooKeeper it needs share one Java process, and here it keeps its files in
lesson 3's HDFS:

```sh
cd ~
curl -O https://downloads.apache.org/hbase/2.6.7/hbase-2.6.7-hadoop3-bin.tar.gz
curl -O https://downloads.apache.org/hbase/2.6.7/hbase-2.6.7-hadoop3-bin.tar.gz.sha512
sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
tar -xzf hbase-2.6.7-hadoop3-bin.tar.gz
ln -s hbase-2.6.7-hadoop3 hbase
cat > ~/hbase/conf/hbase-site.xml <<'END'
<configuration>
  <property><name>hbase.rootdir</name><value>hdfs://localhost:9000/hbase</value></property>
  <property><name>hbase.zookeeper.property.dataDir</name><value>${user.home}/hbase-zk</value></property>
</configuration>
END
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/hbase/conf/hbase-env.sh
echo 'export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true' >> ~/hbase/conf/hbase-env.sh
echo 'export PATH=~/hbase/bin:$PATH' >> ~/.sparkrc
. ~/.sparkrc
start-hbase.sh
cd ~/big
```

The checksum file is written in a different layout from Spark's, so the two checksum lines print the
computed and the published value one under the other, to compare. They must be the same:

```
ana@lab:~$ sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ sha512sum hbase-2.6.7-hadoop3-bin.tar.gz | cut -d' ' -f1
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
ana@lab:~$ cut -d: -f2 hbase-2.6.7-hadoop3-bin.tar.gz.sha512 | tr -d ' \n' | tr A-F a-f; echo
2e0835a3ed8e5a9114f5d878deafb2f7a6b1c8386ba422d1a307fcc5551d452dc7da468729a43acf75dcfe0b20424cb48f72ed424dfd15f81b1b3624454ed82d
```

The `HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP` line keeps HBase on its own copy of Hadoop's libraries rather
than mixing in the one installed in lesson 3.

**The row key is the design.** This program writes January's events as tab-separated lines with a key
made of the visitor, the time and the event. Save it as `~/big/to_hbase.py`:

```schooling-example
{
  "language": "python",
  "file": "to_hbase.py",
  "parts": [
    {
      "code": "\"\"\"January's events as tab-separated lines, keyed for HBase: visitor, then time.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"to hbase\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\n"
    },
    {
      "code": "key = F.concat_ws(\"|\", \"visitor_id\", F.date_format(\"ts\", \"yyyyMMddHHmmss\"),\n                  F.lpad(F.col(\"event_id\").cast(\"string\"), 8, \"0\"))\n(january.select(key.alias(\"row\"), \"kind\", F.coalesce(F.col(\"book_id\").cast(\"string\"), F.lit(\"\")),\n                \"device\")\n .write.mode(\"overwrite\").option(\"sep\", \"\\t\").csv(\"hdfs://localhost:9000/hbase-in/january\"))\n",
      "note": "**The row key is the whole design of an HBase table.** Rows are kept sorted by it, and the only fast questions are about one key or a range of keys. Starting with the visitor puts each visitor's events together, the time after it puts them in order, and the event id at the end keeps two events in the same second apart."
    }
  ]
}
```

Then create a table with one column family, `e`, and load the lines with HBase's own import job:

```
ana@lab:~/big$ spark-submit to_hbase.py 2>/dev/null
ana@lab:~/big$ echo "create 'events', 'e'" | hbase shell -n 2>/dev/null; echo
hbase:001:0> create 'events', 'e'
Created table events
Took 1.3279 seconds
=> Hbase::Table - events
hbase:002:0> 

ana@lab:~/big$ time hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=HBASE_ROW_KEY,e:kind,e:book,e:device events hdfs://localhost:9000/hbase-in/january 2> import.log

real	1m6.624s
user	0m35.508s
sys	0m2.622s
ana@lab:~/big$ grep -E 'Map input records|Bad Lines' import.log | tail -2
		Map input records=2038357
		Bad Lines=0
```

And ask it two questions, written into a file for the HBase shell to run:

```sh
cat > look.rb <<'END'
scan 'events', {ROWPREFIXFILTER => 'v0936542|', LIMIT => 3}
count 'events', INTERVAL => 1000000
exit
END
```

```
ana@lab:~/big$ hbase shell -n look.rb 2>/dev/null
hbase:001:0> scan 'events', {ROWPREFIXFILTER => 'v0936542|', LIMIT => 3}
ROW  COLUMN+CELL
 v0936542|20250118142457|01157304 column=e:book, timestamp=2026-10-16T05:16:44.224, value=21
 v0936542|20250118142457|01157304 column=e:device, timestamp=2026-10-16T05:16:44.224, value=mobile
 v0936542|20250118142457|01157304 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
 v0936542|20250118142458|01157305 column=e:book, timestamp=2026-10-16T05:16:44.224, value=285
 v0936542|20250118142458|01157305 column=e:device, timestamp=2026-10-16T05:16:44.224, value=mobile
 v0936542|20250118142458|01157305 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
 v0936542|20250118142500|01157306 column=e:book, timestamp=2026-10-16T05:16:44.224, value=2182
 v0936542|20250118142500|01157306 column=e:device, timestamp=2026-10-16T05:16:44.224, value=desktop
 v0936542|20250118142500|01157306 column=e:kind, timestamp=2026-10-16T05:16:44.224, value=view
3 row(s)
Took 0.7674 seconds
hbase:002:0> count 'events', INTERVAL => 1000000
Current count: 1000000, row: v0936542|20250128030555|01783832
Current count: 2000000, row: v1961327|20250130171110|01953935
2038357 row(s)
Took 14.6208 seconds
=> 2038357
hbase:003:0> exit
```

**One visitor's first three events came back in time order in under a second**, because they are neighbours in
the sorted table: the scan went straight to the first key beginning with `v0936542|` and stopped at
the third. Each event is three cells, one per column, each with the time it was written. **Counting
the table took seconds**, because a count is a scan of every row, the question HBase is worst at and
Spark is built for. That asymmetry is the whole of the choice: HBase for serving
known keys to an application, a columnar lake for questions about everything.

A row key that starts with the time instead would put every new event at the end of the table, in
one region on one server, the *hotspot* that is lesson 8's skew in a database. Keys that start with
something spread out, like a visitor id or a hash, are the rule.
