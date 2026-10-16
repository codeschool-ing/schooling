---
title: acks, and how many copies a "yes" is worth
version: 1
---

**`acks` is the producer's choice of when the leader may answer: before writing, after writing to
its own log, or after every in-sync replica has the record.** It is set per producer, not per
topic, and it decides what a producer's "delivered" is worth when a node dies a moment later.

| `acks` | the producer is told yes when… | lost if the leader dies just after |
|---|---|---|
| `0` | the request has left the producer; nobody answers | anything, and the producer never knows |
| `1` | the leader has written it to its own log | whatever the followers had not fetched yet |
| `all` | every replica in the ISR has it | nothing that was acknowledged |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A sequence over time, top to bottom, between a producer, the leader on node 1 and two followers. With acks=0 the producer counts the message as sent the moment it leaves. The leader writes it to its log and, with acks=1, answers straight away. The followers fetch it, and on their next fetch the leader learns both have it, moves the high watermark and only then answers a producer that asked for acks=all.\" data-fig=\"l5-acks\"><defs><marker id=\"l5-acks-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l5-acks-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l5-acks-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5-acks-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"178\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">producer</text><line x1=\"230\" y1=\"40\" x2=\"230\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"348\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">node 1 · leader</text><line x1=\"400\" y1=\"40\" x2=\"400\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"488\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">node 2</text><line x1=\"540\" y1=\"40\" x2=\"540\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"608\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">node 3</text><line x1=\"660\" y1=\"40\" x2=\"660\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"230\" y1=\"62\" x2=\"398\" y2=\"82\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-726)\"></line><text x=\"315.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">produce</text><circle cx=\"230\" cy=\"62\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acks=0: counted as sent</text><rect x=\"352\" y=\"84\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">written to its log</text><line x1=\"398\" y1=\"110\" x2=\"232\" y2=\"130\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-0)\"></line><circle cx=\"230\" cy=\"130\" r=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acks=1: answered</text><line x1=\"538\" y1=\"150\" x2=\"402\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"402\" y1=\"164\" x2=\"538\" y2=\"172\" stroke=\"var(--paper)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-726)\"></line><line x1=\"658\" y1=\"160\" x2=\"402\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"402\" y1=\"174\" x2=\"658\" y2=\"182\" stroke=\"var(--paper)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-726)\"></line><text x=\"470.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">fetch</text><text x=\"610.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the record</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copied</text><text x=\"660\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copied</text><line x1=\"538\" y1=\"236\" x2=\"402\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"658\" y1=\"244\" x2=\"402\" y2=\"244\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><text x=\"478.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">next fetch</text><rect x=\"338\" y=\"254\" width=\"124\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">high watermark moves</text><line x1=\"398\" y1=\"282\" x2=\"232\" y2=\"298\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-2105)\"></line><circle cx=\"230\" cy=\"298\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"298\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">acks=all: answered</text></svg>", "caption": "The three settings of acks are three moments in the same exchange: the later the answer, the more copies stand behind it."}
```

**`acks=all` is the producer's default**, in the Java client since Kafka 3.0 and in librdkafka for
longer, so a producer that sets nothing is already on the safe end. The other two exist for data
where speed matters more than every record, such as metrics sampled every second.

## The other half: min.insync.replicas

`acks=all` waits for the ISR, and the ISR can shrink. With a replication factor of 3 and two nodes
down, the ISR is the leader alone, and `acks=all` then means *the leader has it*, which is `acks=1`
under a better name. **`min.insync.replicas` is the floor**: the smallest ISR with which the leader
accepts an `acks=all` write. Below it, the leader refuses the write with `NotEnoughReplicas`
instead of accepting it on too few copies.

The usual production setting is the one this topic was made with: **replication factor 3 and
`min.insync.replicas=2`**. One node can be lost, for a failure or for maintenance, and writes go
on; every acknowledged record is on at least two disks.

## Measuring it

This program sends sales with a chosen `acks` and counts the answers: delivered, or the name of the
error. It gives the client all three nodes' addresses, so it can start whichever is up, and sets
`message.timeout.ms` to thirty seconds, the time the client keeps retrying a sale before it gives
up and reports it failed; the default is five minutes. Save it as `~/work/acks.py`:

```python
"""acks.py: send sales with a chosen acks, and count what the cluster answered.

    python acks.py --acks all|1|0 [--count N] [--rate R] [--topic T] [--key K]
"""
import argparse
import collections
import json
import time

from confluent_kafka import Producer

args = argparse.ArgumentParser()
args.add_argument("--acks", default="all", choices=["0", "1", "all"])
args.add_argument("--count", type=int, default=10)
args.add_argument("--rate", type=float, default=0)
args.add_argument("--topic", default="sales")
args.add_argument("--key", default="recife")
args = args.parse_args()

producer = Producer({
    "bootstrap.servers": "localhost:9092,localhost:9093,localhost:9094",
    "acks": args.acks,
    "message.timeout.ms": 30000,
})
answers = collections.Counter()
offsets = collections.defaultdict(list)

def report(err, msg):
    if err is None:
        answers["delivered"] += 1
        offsets[msg.partition()].append(msg.offset())
    else:
        answers[err.name()] += 1

for n in range(1, args.count + 1):
    sale = {"sale": f"ack-{n:06d}", "shop": args.key, "book": "bk-01", "qty": 1, "cents": 3990}
    producer.produce(args.topic, key=args.key, value=json.dumps(sale), on_delivery=report)
    producer.poll(0)
    if args.rate:
        time.sleep(1 / args.rate)
producer.flush()

print(f"acks={args.acks}:", ", ".join(f"{v} {k}" for k, v in answers.items()))
if args.acks != "0":
    for p, o in sorted(offsets.items()):
        print(f"partition {p}: offsets {min(o)} to {max(o)}")
```

All three values work while all three nodes are up. With `acks=0` there is no answer, so no offset,
and "delivered" only means "sent":

```
ubuntu@stream:~/work$ python acks.py --acks 0
acks=0: 10 delivered
ubuntu@stream:~/work$ python acks.py --acks 1
acks=1: 10 delivered
partition 1: offsets 249 to 258
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 delivered
partition 1: offsets 259 to 268
```

Every sale goes to the same partition, because they all have the key `recife`. Now stop a node.
With two replicas left in the ISR, `min.insync.replicas=2` is still met:

```
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 delivered
partition 1: offsets 269 to 278
```

The ISR of every partition is down to nodes 1 and 2, two replicas, and `min.insync.replicas` asks
for two: ten sales delivered with `acks=all`, at offsets 269 to 278 of partition 1.

## Below the floor

Losing a second node of this cluster would also take a majority of its controllers, which is a
different failure and the subject of the section after next. So to see the refusal, raise the floor
instead: with `min.insync.replicas=3`, an ISR of two is one short.

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=3
Completed updating config for topic sales.
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 _MSG_TIMED_OUT
ubuntu@stream:~/work$ grep -h -m1 NotEnoughReplicasException ~/kafka-data/node*/logs/server.log
org.apache.kafka.common.errors.NotEnoughReplicasException: The size of the current ISR : 2 is insufficient to satisfy the min.isr requirement of 3 for partition sales-1, live replica(s) broker.id are : Set(1, 2)
ubuntu@stream:~/work$ python acks.py --acks 1
%3|1791683959.237|FAIL|rdkafka#producer-1| [thrd:localhost:9094/bootstrap]: localhost:9094/bootstrap: Connect to ipv4#127.0.0.1:9094 failed: Connection refused (after 0ms in state CONNECT)
acks=1: 10 delivered
partition 1: offsets 279 to 288
```

**Ten sales, ten `_MSG_TIMED_OUT`.** The leader refused each write, the client treated the refusal
as something that might pass and retried, and after the thirty seconds of `message.timeout.ms` it
gave up and reported the sales failed. The client's name for the failure is its own timeout; the
leader's reason is in its log, and `grep` finds it: `NotEnoughReplicasException`, an ISR of 2
against a requirement of 3. **Nothing was written**: the `acks=1` run after it starts at offset
279, the one after the last sale delivered before. That is the point of the floor: a producer that
asked for every copy is told no rather than given fewer copies than it asked for.

The same partition, the same moment, with `acks=1`: delivered. The leader answered as soon as the
sales were on its own disk, and would have done so with no follower at all. The `%3|…|FAIL` line
above it is the client reporting that it tried node 3, the third address it was given, and found
nobody there; it is a log line, not a failed sale.

Put the topic back the way it was, and bring node 3 back:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=2
Completed updating config for topic sales.
ubuntu@stream:~/work$ ./cluster.sh start 3
node 3: up on localhost:9094
```
