---
title: A poison message, and the dead-letter topic
version: 1
---

**A consumer reads a partition in order, and it cannot step over a message it fails on.** Its
position is the offset of the next message to handle; if handling it throws, the position does not
move, and when the program restarts it reads the same message and throws again. One record that the
program cannot handle, called a **poison message**, stops its whole partition, including every key
that happens to share it. And when the program dies on it, every other partition it was reading
stops with it.

The usual source is not malice. It is a till that missed a software update and still sends the old
format, a field that was a number last month and is a string now (lesson 6 is about preventing that),
a message cut short, or a value no code path expected.

## One bad sale

This consumer counts the books sold, and it commits after every sale it counts, so its position is
exactly the next message it has not dealt with. Without `--dead-letter`, anything that is not a sale
stops it. Save it as `~/work/sturdy_consumer.py`:

```schooling-example
{
  "file": "sturdy_consumer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"sturdy_consumer.py: counts the books sold, and decides what a bad message costs.\n\n    python sturdy_consumer.py [--group G] [--dead-letter TOPIC]\n\nWithout --dead-letter, a message that is not a sale stops the program.\nWith it, the message is copied to TOPIC with the reason, and skipped.\nIt stops by itself after ten seconds with nothing to read.\n\"\"\"\nimport argparse\nimport json\n\nfrom confluent_kafka import Consumer, Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--group\", default=\"stock-count\")\nargs.add_argument(\"--dead-letter\")\nargs = args.parse_args()\n",
      "note": "What it does, and the one choice it offers: what a message it cannot handle costs."
    },
    {
      "code": "consumer = Consumer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"enable.auto.commit\": False,\n})\nconsumer.subscribe([\"sales\"])\ndead = Producer({\"bootstrap.servers\": \"localhost:9092\"}) if args.dead_letter else None\n",
      "note": "**Commits are by hand**, after each message, so the group's position never runs ahead of what was really counted."
    },
    {
      "code": "books = sales = letters = 0\ntry:\n    while True:\n        msg = consumer.poll(10)\n        if msg is None:\n            break\n        if msg.error():\n            raise SystemExit(msg.error().str())\n        try:\n            sale = json.loads(msg.value())\n            books += sale[\"qty\"]\n            sales += 1\n",
      "note": "The work. A message that is not JSON, or lacks a `qty`, raises here, and without a dead-letter topic nothing catches it."
    },
    {
      "code": "        except (ValueError, KeyError, TypeError) as e:\n            if dead is None:\n                raise\n            where = f\"{msg.topic()}/{msg.partition()}/{msg.offset()}\"\n            dead.produce(args.dead_letter, key=msg.key(), value=msg.value(),\n                         headers={\"error\": repr(e), \"from\": where})\n            dead.flush()\n            letters += 1\n            print(\"dead letter:\", where, repr(e))\n",
      "note": "With a dead-letter topic, the bad message is copied there whole, **with the reason and its origin in headers**, and the consumer moves on."
    },
    {
      "code": "        consumer.commit(msg, asynchronous=False)\nfinally:\n    consumer.close()\nprint(f\"{sales} sales, {books} books, {letters} dead letters\")",
      "note": "The commit comes after the message has been dealt with, either way. That order is lesson 7's at-least-once."
    }
  ]
}
```

The topic holds the 600 sales from the earlier sections. Count them once, so the group
`stock-count` has a committed position in every partition that has sales; it stops by itself ten
seconds after the last one:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
600 sales, 999 books, 0 dead letters
```

Now a till in Recife on the old software sends a sale in its old format, a line of fields separated
by semicolons, and thirty ordinary sales follow it. `kafka-console-producer.sh` sends the bad one
with the key `recife`:

```
ubuntu@stream:~/work$ echo 'recife|bk-03;1;2990' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property key.separator='|'
ubuntu@stream:~/work$ python tills.py --count 30 --rate 0 --seed 5
sent 30 sales to sales, the last one at 09:04:14
```

Count again:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
Traceback (most recent call last):
  File "/home/ubuntu/work/sturdy_consumer.py", line 37, in <module>
    sale = json.loads(msg.value())
           ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

It dies on `json.loads`. Where did it stop?

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count

Consumer group 'stock-count' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock-count     sales           0          139             139             0               -               -               -
stock-count     sales           1          491             491             0               -               -               -
```

Partitions 0 and 1 have been read to the end, the thirty new sales included, and they show a lag of
zero. **Partition 2 is not in the list at all.** The console producer is a Java program, and Java's
client hashes a key differently from the Python one (lesson 3), so this `recife` landed in partition
2, where none of the Python tills' sales go. The bad sale is the first and only message there, the
group has never committed a position in that partition, and the tool has nothing to print for it.
Run the counter again, as a supervisor that restarts crashed programs would:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
Traceback (most recent call last):
  File "/home/ubuntu/work/sturdy_consumer.py", line 37, in <module>
    sale = json.loads(msg.value())
           ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count

Consumer group 'stock-count' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock-count     sales           0          139             139             0               -               -               -
stock-count     sales           1          491             491             0               -               -               -
```

**The same message, the same error, and nothing moved.** A supervisor would restart it forever. And
look at what a lag dashboard would say: zero on every partition it knows about. **A poison message
can stop a consumer while its lag reads zero**, because lag is measured from commits and the stuck
partition has none. A consumer that restarts over and over, or a group with no members, is the
signal here, and the last section of this lesson puts both on the alert list. Had the bad message
arrived after some good ones in partition 2, the lag there would have grown with every sale behind it.

## The dead-letter topic

The way out is to decide in advance what a message the program cannot handle is worth. **A
dead-letter topic is the usual answer: copy the message there, with why it failed and where it came
from, and carry on.** Nothing is lost, the partition moves, and somebody can look at the dead letters
later, fix the program or the data, and send them back.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales.dlq --partitions 1
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic sales.dlq.
ubuntu@stream:~/work$ python sturdy_consumer.py --dead-letter sales.dlq
dead letter: sales/2/0 JSONDecodeError('Expecting value: line 1 column 1 (char 0)')
0 sales, 0 books, 1 dead letters
```

Kafka warns about the dot in the name because metric names turn dots into underscores, so `sales.dlq`
and `sales_dlq` would collide; using only one of the two characters in your topic names avoids it.
The counter, with somewhere to put what it cannot count, gets past the bad sale at once: it counted
nothing else in this run because everything else was already counted. The dead letter, with its
headers in front of the tab and its original value after it:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales.dlq --from-beginning --max-messages 1 --formatter-property print.headers=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
error:JSONDecodeError('Expecting value: line 1 column 1 (char 0)'),from:sales/2/0	bk-03;1;2990
Processed a total of 1 messages
```

Three rules keep a dead-letter topic from becoming a second problem:

- **Only for errors that will not go away by retrying.** A message that failed because a database
  was down for a second is not poison; sending it to the dead letters sets aside an ordinary sale.
  Retry the transient ones, a few times with a pause, and dead-letter only what fails the same way
  every time.
- **Somebody reads it.** A dead-letter topic nobody watches is a slower way of dropping data. Its
  size is a number to alert on, and the last section of this lesson says so.
- **Order is given up.** A sale moved aside and replayed later arrives after sales that happened
  after it. For counting books that is harmless; for an account balance it is not, and the choice
  there is to stop the partition on purpose.
