---
title: Flink's state, checkpoints and savepoints
version: 1
---

The open windows of the job you just started are state, like Spark's, and they live in the
TaskManager's memory. **Flink protects them by taking a snapshot of the whole job every few
seconds, without stopping it**, and that snapshot is called a **checkpoint**. The two `SET` lines
at the top of `sales.sql` asked for one every ten seconds, written under `~/flink-checkpoints`.

The wrong picture is that each operator saves its state when it likes. If the source saved its
Kafka offsets at one moment and the window operator saved its counts a little later, a restore would
count some sales twice or not at all. **Flink makes the snapshot consistent by sending a marker,
a barrier, through the stream with the records.** When the source takes a snapshot it saves its
offsets and passes the barrier on; each operator saves its state when the barrier reaches it, so
every saved count includes exactly the sales before the barrier and none after it. A restore puts
the counts back and makes the source read again from the saved offsets.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A checkpoint barrier travelling with the records. Records flow from the Kafka source to the window operator to the sink. The source injects a barrier, marked N, between two records and saves its offsets at that point. The barrier travels downstream behind the records before it; when it reaches the window operator, the operator saves its counts. Both saves go to checkpoint N, which therefore holds the offsets and the counts as of the same point in the stream. Records after the barrier keep flowing and are not in it.\" data-fig=\"l13-barrier\"><defs><marker id=\"l13-barrier-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-barrier-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kafka source</text><rect x=\"300\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">window operator</text><rect x=\"580\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sink</text><rect x=\"160\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"180\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"250\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"270\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><line x1=\"228\" y1=\"64\" x2=\"228\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"3\"></line><text x=\"228\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">barrier N</text><rect x=\"430\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"74\" width=\"12\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 490 82 L 576 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-barrier-ah-8343)\"></path><text x=\"220\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">records flow</text><path d=\"M 230 150 L 290 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-barrier-ah-8343)\"></path><text x=\"222\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">after it: not in N</text><text x=\"234\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">before the barrier: in N</text><rect x=\"240\" y=\"180\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">checkpoint N</text><text x=\"340\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">offsets + counts</text><path d=\"M 85 106 Q 90 190 236 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-barrier-ah-83)\"></path><path d=\"M 355 106 L 345 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-barrier-ah-83)\"></path><text x=\"110\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">offsets</text><text x=\"375\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">counts</text></svg>", "caption": "Each operator saves its state when the barrier reaches it, so the snapshot is one consistent moment of the whole job."}
```

Where the snapshot goes is the **state backend**'s business. The default keeps the working state as
Java objects in the TaskManager's memory and writes the snapshot to the checkpoint directory; the
RocksDB backend keeps the working state on local disk, for state larger than memory. In a real
cluster the directory is shared storage that outlives a machine, the same rule as Spark's.

Each job gets a directory under `~/flink-checkpoints`, named after its id, holding its latest
completed checkpoint. There are two, the cancelled job's and the running one's:

```
ubuntu@stream:~/work$ ls ~/flink-checkpoints
1b14e9a9a838ec156cb32b72b8c46fd7
28d4b45557a9e6ff9b7385f48a63751f
```

## A savepoint: stopping on purpose

A checkpoint is Flink's, taken for recovery from a crash and deleted when newer ones replace it. A
**savepoint** is yours: the same kind of snapshot, taken when you ask, kept until you delete it, and
used to stop a job and start it again later, after an upgrade of Flink, a change to the job, or a
move to another cluster. `flink stop` takes one and then stops the job:

```
ubuntu@stream:~/work$ ~/flink/bin/flink stop --savepointPath file:///home/ubuntu/flink-savepoints 1b14e9a9a838ec156cb32b72b8c46fd7
Suspending job "1b14e9a9a838ec156cb32b72b8c46fd7" with a CANONICAL savepoint.
Triggering stop-with-savepoint for job 1b14e9a9a838ec156cb32b72b8c46fd7.
Waiting for response...
Savepoint completed. Path: file:/home/ubuntu/flink-savepoints/savepoint-1b14e9-c3b0e303e01b
```

While it is stopped, two more sales arrive, the Recife sale from lesson 12 at 09:38 and one from
Natal at 09:44, late enough to move the watermark past 09:40:

```
ubuntu@stream:~/work$ printf '%s\n' 'recife|{"sale": "rec-000201", "shop": "recife", "book": "bk-03", "qty": 1, "cents": 2990, "at": "2026-03-02T09:38:00-03:00"}' 'natal|{"sale": "nat-000202", "shop": "natal", "book": "bk-01", "qty": 1, "cents": 3990, "at": "2026-03-02T09:44:00-03:00"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'
```

Submit `sales.sql` again, this time telling the SQL client, with `-D`, where to restore the job from.
The path is the one `flink stop` printed:

```
ubuntu@stream:~/work$ ~/flink/bin/sql-client.sh -Dexecution.state-recovery.path=file:/home/ubuntu/flink-savepoints/savepoint-1b14e9-c3b0e303e01b -f sales.sql 2>/dev/null | grep "Job ID"
Job ID: 28f69093342b20db69c2b4a874f3c4c9
```

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null
{"window_start":"2026-03-02 09:00:00","window_end":"2026-03-02 09:05:00","sales":30,"cents":337340}
{"window_start":"2026-03-02 09:05:00","window_end":"2026-03-02 09:10:00","sales":28,"cents":241740}
{"window_start":"2026-03-02 09:10:00","window_end":"2026-03-02 09:15:00","sales":28,"cents":204680}
{"window_start":"2026-03-02 09:15:00","window_end":"2026-03-02 09:20:00","sales":29,"cents":240130}
{"window_start":"2026-03-02 09:20:00","window_end":"2026-03-02 09:25:00","sales":23,"cents":209180}
{"window_start":"2026-03-02 09:25:00","window_end":"2026-03-02 09:30:00","sales":25,"cents":237180}
{"window_start":"2026-03-02 09:30:00","window_end":"2026-03-02 09:35:00","sales":24,"cents":172230}
{"window_start":"2026-03-02 09:35:00","window_end":"2026-03-02 09:40:00","sales":14,"cents":137930}
```

The first six lines are the old job's. **The last two are the new job's, and they could only come
from the savepoint**: 24 sales in the 09:30 window, and 14 in 09:35, the 13 counted before the stop
plus the sale from Recife. The new job did not read the topic from the beginning, although the
table says `earliest-offset`: the savepoint held the source's offsets and they win, as Spark's
checkpoint won over `startingOffsets`. Started without `-D`, the same file would have read the topic from
the beginning and written every window a second time.

## What it costs, and stopping it

The cluster is three Java processes now, the Kafka node and Flink's two:

```
ubuntu@stream:~/work$ jps -l
23783 kafka.Kafka
31511 org.apache.flink.runtime.taskexecutor.TaskManagerRunner
5466 jdk.jcmd/sun.tools.jps.Jps
30894 org.apache.flink.runtime.entrypoint.StandaloneSessionClusterEntrypoint
```

```
ubuntu@stream:~/work$ ps -o pid,rss,comm -u ubuntu --sort=-rss | head -4
  PID   RSS COMMAND
23783 395568 java
27181 173508 java
27940  4332 ps
```

The TaskManager, which runs the job, holds about 480 MB, the JobManager, which coordinates it,
about 430 MB, and the Kafka node about 410 MB: **about 1.3 GB for a broker and a small Flink
cluster**,
inside the virtual machine's 4 GB with room for the operating system. Stop the job and the cluster
when you are done:

```
ubuntu@stream:~/work$ ~/flink/bin/stop-cluster.sh
Stopping taskexecutor daemon (pid: 31511) on host stream.
Stopping standalonesession daemon (pid: 30894) on host stream.
```

Stopping the cluster with the job still running cancels the job, and its next start would begin
from the table's `earliest-offset` unless it is given a savepoint or a checkpoint to restore from.
That is the operational habit to keep: **stop a Flink job with a savepoint, and start it from one.**
