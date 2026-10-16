---
title: The transaction log
version: 1
---

**A Delta table is a directory of Parquet files and a `_delta_log` directory of numbered JSON
files, one per commit.** Each commit lists the files it adds to the table and the ones it removes.
Reading the table means reading the log from the start, or from the latest checkpoint of it, and
taking the files that were added and not since removed. Nothing else in the directory is part of the
table, whatever it holds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l11-log\" aria-label=\"A Delta table as a log and a directory. Commit 0 adds files 1 to 3, commit 1 adds files 4 to 6, commit 2 removes all six and adds files 7 to 9. Version 2 of the table is files 7 to 9; version 1 is files 1 to 6, which are still on disk until a vacuum deletes them.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">_delta_log</text><rect x=\"20.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00000.json</text><text x=\"226.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">January</text><text x=\"30.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 1 2 3</text><rect x=\"252.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00001.json</text><text x=\"458.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">February</text><text x=\"262.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 4 5 6</text><rect x=\"484.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"494.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00002.json</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">DELETE</text><text x=\"494.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">remove: 1 2 3 4 5 6</text><text x=\"494.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 7 8 9</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">data files on disk</text><rect x=\"20.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"52.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.parquet</text><rect x=\"96.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"128.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.parquet</text><rect x=\"172.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"204.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.parquet</text><rect x=\"248.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"280.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.parquet</text><rect x=\"324.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"356.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.parquet</text><rect x=\"400.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"432.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6.parquet</text><rect x=\"476.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"508.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7.parquet</text><rect x=\"552.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8.parquet</text><rect x=\"628.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9.parquet</text><path d=\"M20.0 222.0 L476.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"248.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">version 1</text><path d=\"M476.0 254.0 L704.0 254.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"590.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">version 2 (current)</text></svg>", "caption": "The table is whatever the log says it is: version 2 is three files, and the six it removed stay on disk for version 1."}
```

**A commit is atomic because creating a file with a given name is.** A writer writes its Parquet
files first, where no reader looks, and then creates the next file of the log, say
`00000000000000000003.json`. If two writers race for the same number, the filesystem lets exactly one
create it; the other finds the number taken, reads what changed, and retries as number 4 if the two
did not conflict. Until the log file exists, the new data files are invisible; once it does, all of
them are visible at once. This is *optimistic concurrency*: no locks, and a check at the end. HDFS and a local disk refuse to
create a file that exists; on an object store Delta relies on the store's conditional writes, or on a
coordinating service where the store has none.

Delta is not on Spark's classpath by default. Its two jars come from Maven Central, the repository
Java libraries are published to. Into a directory of their own:

```sh
mkdir -p ~/jars && cd ~/jars
curl -O https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/4.3.1/delta-spark_2.13-4.3.1.jar
curl -O https://repo1.maven.org/maven2/io/delta/delta-storage/4.3.1/delta-storage-4.3.1.jar
curl -O https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.1_2.13/1.12.0/iceberg-spark-runtime-4.1_2.13-1.12.0.jar
curl -O https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark4.1-bundle_2.13/1.2.1/hudi-spark4.1-bundle_2.13-1.2.1.jar
cd ~/big
```

The last two are for sections 06 and 07. Each version is the newest built for Spark 4.1, and each
name says which Spark and which Scala it was built for: a jar built for another Spark usually fails
with an error about a missing class or method, rather than about a version. What arrived:

```
ana@lab:~/big$ ls -l ~/jars
total 136664
-rw-r--r-- 1 ana ana  9021481 Oct 16 03:33 delta-spark_2.13-4.3.1.jar
-rw-r--r-- 1 ana ana   110970 Oct 16 03:33 delta-storage-4.3.1.jar
-rw-r--r-- 1 ana ana 82491267 Oct 16 03:33 hudi-spark4.1-bundle_2.13-1.2.1.jar
-rw-r--r-- 1 ana ana 48309426 Oct 16 03:33 iceberg-spark-runtime-4.1_2.13-1.12.0.jar
```

`spark-submit --packages io.delta:delta-spark_2.13:4.3.1` would fetch Delta and what it needs from
Maven Central by itself, and check for it again at the start of every run; the jars on disk make each run start the same way
with no network, and `--jars` hands them to the driver and to every executor.
