---
title: The idempotent producer
version: 1
---

**An idempotent producer numbers its messages, and the broker refuses a number it has already
written, so a retry after a lost acknowledgement cannot write a sale twice.** It closes the first
of the two gaps, the one between a write and its acknowledgement, and it costs almost nothing:
two numbers in each batch, which the broker keeps per partition.

The mechanism has two parts:

- **a producer id**: when an idempotent producer starts, the cluster gives it a number of its own,
  the PID, with an **epoch** beside it;
- **a sequence number** for each batch, per partition, starting at 0 and growing by the number of
  messages in the batch.

The leader remembers the last few sequence numbers it accepted from each PID on each partition. A
retried batch arrives with a sequence it has already written: the leader answers *success*,
because the data is there, and does not write it again. A batch that arrives with a sequence
**ahead** of what it expects means one went missing in between, and it is refused, so the order
inside a partition is kept even with several batches in flight.

## Is it on?

In the Java client, idempotence has been on by default since Kafka 3.0. The Python client is a
wrapper around librdkafka, which keeps its own defaults, and **in librdkafka `enable.idempotence`
is `false` unless you set it**. The broker's log shows which kind of producer wrote a batch. Every
batch on disk carries the producer's id and the batch's first sequence, and a producer without
idempotence writes `-1` in both. `tills.py` sets nothing:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-0/00000000000000000000.log | head -4
```

@@PLAIN@@

Now five sales from a producer with one setting changed. Save it as `~/work/idempotent.py`:

```python
"""idempotent.py: five sales from a producer with idempotence switched on."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092", "enable.idempotence": True})
for n in range(1, 6):
    sale = {"sale": f"idm-{n:06d}", "shop": "recife", "book": "bk-01", "qty": 1, "cents": 3990}
    producer.produce("sales", key="recife", value=json.dumps(sale))
producer.flush()
print("sent 5 sales with enable.idempotence=true")
```

```
ubuntu@stream:~/work$ python idempotent.py
```

@@IDEM@@

## What it changes, and what it does not

Turning idempotence on also sets three other things, and librdkafka refuses a configuration that
contradicts them: **`acks=all`**, because a sequence is only worth checking on a write that is
safe; retries without limit inside `message.timeout.ms`; and at most five requests in flight per
connection, the number the broker keeps sequences for.

What it does not do is just as important:

- **It is per producer session.** A program that crashes and starts again gets a new PID, so a
  sale it sends again after the restart is a new message to the broker. Idempotence protects a
  retry inside one run, not a resend by a program that forgot what it had sent.
- **It is per partition.** Sequences are counted per partition; nothing ties a write to one
  partition to a write to another.
- **It does nothing for the consumer's gap.** A consumer that processes twice still processes
  twice.

So set it, in every producer, unless there is a reason not to: there is no cost worth weighing.
The restart and the consumer need the next two sections.
