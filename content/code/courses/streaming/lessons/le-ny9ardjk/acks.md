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

@@fig:l5-acks@@

**`acks=all` is the producer's default**, in the Java client since Kafka 3.0 and in librdkafka for
longer, so a producer that sets nothing is already on the safe end. The other two exist
for data where speed matters more than every record, such as metrics sampled every second.

## The other half: min.insync.replicas

`acks=all` waits for the ISR, and the ISR can shrink. With a replication factor of 3 and two nodes
down, the ISR is the leader alone, and `acks=all` then means *the leader has it*, which is
`acks=1` under a better name. **`min.insync.replicas` is the floor**: the smallest ISR with which
the leader accepts an `acks=all` write. Below it, the leader refuses the write with
`NotEnoughReplicas` instead of accepting it on too few copies.

The usual production setting is the one this topic was made with: **replication factor 3 and
`min.insync.replicas=2`**. One node can be lost, for a failure or for maintenance, and writes go
on; every acknowledged record is on at least two disks.

## Measuring it

This program sends sales with a chosen `acks` and counts the answers: delivered, or the name of
the error. It gives the client all three nodes' addresses, so it can start whichever is up, and
sets `message.timeout.ms` to thirty seconds, the time the client keeps retrying a sale before it
gives up and reports it failed; the default is five minutes. Save it as `~/work/acks.py`:

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

All three values work while all three nodes are up. With `acks=0` there is no answer, so no
offset, and "delivered" only means "sent":

```
ubuntu@stream:~/work$ python acks.py --acks 0
```

Every sale goes to the same partition, because they all have the key `recife`. Now stop a node.
With two replicas left in the ISR, `min.insync.replicas=2` is still met:

```
ubuntu@stream:~/work$ ./cluster.sh kill 3
```

@@ONEDOWN@@

## Below the floor

Losing a second node of this cluster would also take a majority of its controllers, which is a
different failure and the subject of a later section. So to see the refusal, raise the floor
instead: with `min.insync.replicas=3`, an ISR of two is one short.

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=3
```

@@MIN3@@

Put the topic back the way it was, and bring node 3 back:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=2
```
