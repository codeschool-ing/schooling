---
title: A producer, and hearing back from it
version: 1
---

**Calling `produce` does not send a message. It puts the message in a buffer and returns at once**;
a thread inside the client library collects messages into batches, one per partition, and sends the
batches when they are full or have waited long enough. Whether a message reached the broker is
known only later, when the client calls a function you gave it, the **delivery report**. A program
that never looks at delivery reports does not know whether anything it produced was stored.

That is the common wrong picture: that `produce` returning means the message is in Kafka. Lesson 1's
`tills.py` got away with it because it called `flush` at the end, which waits for every message to
be acknowledged, and nothing went wrong. This producer says what happened to each message. Save it
as `~/work/producer.py`:

@@EX@@

Make a fresh `sales` topic and send the default ten sales. If you still have lesson 3's cluster,
`./cluster.sh stop`, `./cluster.sh new 1` and `./cluster.sh start` first, as lesson 3 did:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

Ten delivery reports, all without error, counted by partition. With `murmur2_random`, Olinda and
João Pessoa go to partition 0, Caruaru and Natal to 1, Recife to 2, as lesson 3 found, and the ten
sales cycle through the five shops: four, four and two.

## Batching, and what linger.ms is for

**`linger.ms` is how long the client waits for more messages before it sends a batch that is not
full.** At 0 it sends as soon as it can; at 100 it holds a batch for up to a tenth of a second, so
that more messages can join it. `batch.size` caps a batch at 16 384 bytes. Send two hundred sales
at two hundred a second, once with each setting, to two topics of one partition:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger0 --partitions 1
```

Then count the batches on disk with lesson 3's `kafka-dump-log.sh`, which prints one `baseOffset`
line per batch:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/linger0-0/00000000000000000000.log | grep -c baseOffset
```

The same two hundred messages took **197 batches** with no linger and **11** with 100 ms. A message
arrived every 5 ms, so with no waiting nearly every message travelled alone; with a tenth of a second
of waiting, about eighteen shared each trip. That is the trade: each message waits up to 100 ms
longer, and the broker handles eighteen times fewer requests, each carrying more. Under heavy load
batches fill by size before the linger runs out, so the setting matters most at moderate rates like
this one. The program's default of 5 ms is also librdkafka's.

## When the broker is not there

Stop the cluster and send five sales, giving up on each after five seconds instead of the default
five minutes (`message.timeout.ms`, 300 000):

```
ubuntu@stream:~/work$ ./cluster.sh stop
```

`produce` accepted all five without complaint, because accepting into the buffer is all it does.
Five seconds later the client gave up on each of them and **said so in the delivery report**:
`Local: Message timed out`, where `Local` means the error was raised by the client, not sent by a
broker. Without the callback those five sales would have disappeared, and the program would have
exited normally. While it waits, librdkafka also writes a line to stderr for every failed attempt to
connect; `2>/dev/null` throws those away, which is why the command has it.

The timeout is a decision. Five minutes rides out a broker restart; five seconds turns a short
outage into lost sales. Either way the delivery report is where the program finds out, and what it
does then, whether it writes the sale to a file, retries later or stops the till, is the program's
choice. Lesson 7 comes back to what happens when the message did arrive and only the answer was lost.
