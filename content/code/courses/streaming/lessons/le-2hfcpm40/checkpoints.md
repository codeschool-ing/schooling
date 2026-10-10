---
title: The checkpoint, and what a restart reads
version: 1
---

Your consumer in lesson 4 kept its place in Kafka, by committing offsets for its consumer group.
**Spark does not. It keeps its place in the checkpoint directory**, together with the open windows,
and a query that starts again reads that directory to know what it already did. Lose the directory
and the query starts from nothing; keep it and a crash costs one batch at most.

Look inside the one the update run wrote:

```
ubuntu@stream:~/work$ ls ~/spark/ckpt/update ~/spark/ckpt/update/state/0
```

| entry | what is in it |
|---|---|
| `metadata` | the query's id, written once, so a restart knows it is the same query |
| `offsets` | one file per batch, written **before** the batch runs: which offsets it will read |
| `commits` | one file per batch, written **after** the batch's output reached the sink |
| `sources` | what the Kafka source found when the query first started |
| `state` | the open windows, one directory per shuffle partition, two here |

The two logs are the heart of it. A batch is planned, its plan is written to `offsets`, it runs,
its rows are handed to the sink, and only then is it written to `commits`. **A batch in `offsets`
with no matching file in `commits` is a batch that did not finish**, and the first thing a restart
does is run it again, with exactly the offsets it had, not with whatever has arrived since.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The life of one micro-batch, N, against the checkpoint. First Spark writes offsets/N, the plan of which offsets the batch will read. Then the batch runs, reading those offsets and the state. Then its rows are written to the sink. Last, commits/N is written. If the process dies after offsets/N and before commits/N, a restart finds the plan without its commit and runs batch N again with the same offsets, so the sink may receive batch N twice.\" data-fig=\"l12-checkpoint\"><defs><marker id=\"l12-checkpoint-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-checkpoint-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">write offsets/N</text><text x=\"100\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the plan</text><rect x=\"205\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run batch N</text><text x=\"275\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets + state</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">write to the sink</text><text x=\"450\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rows out</text><rect x=\"555\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">write commits/N</text><text x=\"625\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">batch done</text><path d=\"M 172 75 L 202 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><path d=\"M 347 75 L 377 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><path d=\"M 522 75 L 552 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><line x1=\"530\" y1=\"112\" x2=\"544\" y2=\"126\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"544\" y1=\"112\" x2=\"530\" y2=\"126\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"537\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">crash here</text><path d=\"M 537 150 Q 537 185 406.0 185 Q 275 185 275 106\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-checkpoint-ah-83)\"></path><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">restart: offsets/N has no commit, so batch N runs again, same offsets</text></svg>", "caption": "The plan is written before the batch and the commit after it; a crash in between means the same batch runs again."}
```

The plan for the last batch is a small text file. Its second line holds the watermark and the time
the batch ran, and its third line the offsets, per partition, that the batch read up to:

```
ubuntu@stream:~/work$ tail -1 ~/spark/ckpt/update/offsets/5
```

Partition 0 up to 41, partition 1 up to 159, and partition 2, which no shop's key lands in, at 0.
That is every one of the 200 sales.

## Starting it again

Run the same query, with the same checkpoint, on a topic that has not changed:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

**It printed nothing.** `startingOffsets` said `earliest`, and Spark ignored it: that option is
only read the first time a query runs, and after that the checkpoint wins. There was nothing past
offset 159 to read, so no batch ran.

Now two more sales arrive, typed into Kafka's console producer instead of coming from the till: one
from Recife at 09:38, which belongs in the 09:35 window, and one from Natal at 09:21, which is
seventeen minutes behind the latest sale Spark has seen:

```
ubuntu@stream:~/work$ printf '%s\n' 'recife|{"sale": "rec-000201", "shop": "recife", "book": "bk-03", "qty": 1, "cents": 2990, "at": "2026-03-02T09:38:00-03:00"}' 'natal|{"sale": "nat-000202", "shop": "natal", "book": "bk-01", "qty": 1, "cents": 3990, "at": "2026-03-02T09:21:00-03:00"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'
```

`parse.key=true` and the separator make the producer split each line into a key and a value, as
`tills.py` does. Run the query a third time:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

The numbering carries on from batch 6, because the checkpoint remembers batches 0 to 5. **The 09:35
window went from 13 sales to 14**, which is only possible because its count of 13 came back from
the `state` directory: the process that counted those 13 had ended minutes before.

And the sale from Natal is in no output at all. The watermark was 09:34:41 when this run started,
the 09:20 window ends at 09:25, and Spark had already forgotten it. **A sale behind the watermark
is dropped without a word**, which is exactly what lesson 11 said a watermark buys and costs.

## No consumer group

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

The list is empty. Spark read the topic three times and Kafka holds no record of where it got to,
because Spark assigns itself the partitions directly and never commits. **Tools that measure lag
from a consumer group, which lesson 16 uses, see nothing of a Spark query**; Spark reports its own
progress instead, through the query's status and the web page on port 4040.

Two consequences are worth carrying away. A checkpoint belongs to one query: pointing a changed
query at an old checkpoint is a way to restore state that no longer fits, and Spark's guide lists
which changes it accepts. And a checkpoint is the only copy of the query's position and state, so
**on a real cluster it lives on storage that outlives the machine**, such as HDFS or an object
store, never on the local disk of a node that can disappear.
