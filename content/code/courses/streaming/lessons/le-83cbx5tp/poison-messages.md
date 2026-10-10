---
title: A poison message, and the dead-letter topic
version: 1
---

**A consumer reads a partition in order, and it cannot step over a message it fails on.** Its
position is the offset of the next message to handle; if handling it throws, the position does not
move, and when the program restarts it reads the same message and throws again. One record that the
program cannot handle, called a **poison message**, stops its whole partition, including every key
that happens to share it, while the other partitions carry on.

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

Now a till in Recife on the old software sends a sale in its old format, a line of fields separated
by semicolons. `kafka-console-producer.sh` sends it with the key `recife`, and thirty ordinary sales
follow it:

```
ubuntu@stream:~/work$ echo 'recife|bk-03;1;2990' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property key.separator='|'
```

The topic holds the 600 sales from the earlier sections, the bad one, and thirty more. Count them:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
```

It dies on `json.loads`. Run it again, as a supervisor that restarts crashed programs would:

```
ubuntu@stream:~/work$ python sturdy_consumer.py
```

**The same message, the same error, and this time almost immediately**: everything before it was
already counted and committed. A supervisor would restart it forever. The group shows where it is
stuck:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-count
```

The bad message sits at the committed offset of one partition, and the sales behind it in that
partition wait with it. The other partition has been read to the end.

## The dead-letter topic

The way out is to decide in advance what a message the program cannot handle is worth. **A
dead-letter topic is the usual answer: copy the message there, with why it failed and where it came
from, and carry on.** Nothing is lost, the partition moves, and somebody can look at the dead letters
later, fix the program or the data, and send them back.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales.dlq --partitions 1
```

The bad message is in the dead-letter topic, with its headers:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales.dlq --from-beginning --max-messages 1 --formatter-property print.headers=true
```

Three rules keep a dead-letter topic from becoming a second problem:

- **Only for errors that will not go away by retrying.** A message that failed because a database
  was down for a second is not poison; sending it to the dead letters loses an ordinary sale. Retry
  the transient ones, a few times with a pause, and dead-letter only what fails the same way every time.
- **Somebody reads it.** A dead-letter topic nobody watches is a slower way of dropping data. Its
  size is a number to alert on, the last section of this lesson says how.
- **Order is given up.** A sale moved aside and replayed later arrives after sales that happened
  after it. For counting books that is harmless; for an account balance it is not, and the choice is
  to stop the partition on purpose.
