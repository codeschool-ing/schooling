---
title: A consumer, and the loop it lives in
version: 1
---

**A consumer asks for messages; Kafka never pushes them.** The program calls `poll` in a loop, and
each call returns the next message from one of the partitions it has been given, or nothing if
none arrived within the timeout. Everything else a consumer does, joining a group, being given
partitions and recording how far it has read, happens inside those calls, so a consumer that stops
calling `poll` stops being a consumer, which lesson 16 shows.

Every consumer in this course belongs to a **consumer group**, named by `group.id`. The group is
what Kafka keeps the reading position for, and what it shares partitions between, which is the next
section. Save this as `~/work/consumer.py`:

```schooling-example
{
  "file": "consumer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"consumer.py: read sales as one member of a consumer group.\n\n    python consumer.py NAME [--group G] [--topic T] [--protocol classic|consumer]\n                            [--strategy S] [--manual]\n\"\"\"\nimport argparse\nimport json\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"name\")\nargs.add_argument(\"--group\", default=\"stock\")\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--protocol\", default=\"classic\")\nargs.add_argument(\"--strategy\", default=\"range\")\nargs.add_argument(\"--manual\", action=\"store_true\")\nargs = args.parse_args()\n",
      "note": "What it does. The name is only printed, to tell copies apart; `--group`, `--protocol`, `--strategy` and `--manual` are what the later sections change."
    },
    {
      "code": "config = {\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"group.protocol\": args.protocol,\n    \"enable.auto.commit\": not args.manual,\n}\nif args.protocol == \"classic\":\n    config[\"partition.assignment.strategy\"] = args.strategy\nconsumer = Consumer(config)\n",
      "note": "The configuration. **`group.id` is the one setting a subscribing consumer cannot do without.** `auto.offset.reset` says where a group with no saved position starts; the strategy is a classic-protocol setting only."
    },
    {
      "code": "\n\ndef show(event):\n    def callback(consumer, partitions):\n        print(f\"{args.name}: {event} {[p.partition for p in partitions]}\", flush=True)\n    return callback\n\n\nconsumer.subscribe([args.topic], on_assign=show(\"assigned\"), on_revoke=show(\"revoked\"))",
      "note": "`subscribe` names the topic and lets the group decide which partitions this copy gets. The two callbacks print every change, which is how the next sections see rebalances."
    },
    {
      "code": "try:\n    while True:\n        msg = consumer.poll(1.0)\n        if msg is None:\n            continue\n        if msg.error():\n            print(f\"{args.name}: {msg.error()}\", flush=True)\n            continue\n        sale = json.loads(msg.value())\n        print(f\"{args.name}: partition {msg.partition()} offset {msg.offset()} {sale['sale']}\",\n              flush=True)\n        if args.manual:\n            consumer.commit(message=msg, asynchronous=False)",
      "note": "**The poll loop.** Each call returns one message, an error, or `None` after a second of nothing. With `--manual` the program commits each message's offset itself, and waits for the broker to confirm."
    },
    {
      "code": "except KeyboardInterrupt:\n    pass\nfinally:\n    consumer.close()",
      "note": "Ctrl+C ends the loop, and `close` leaves the group cleanly: it commits what was read, unless commits are manual, and hands the partitions back at once instead of letting the group wait for a timeout."
    }
  ]
}
```

Run it in your second shell. It reads the ten sales from the last section and waits for more; stop
it with Ctrl+C when it has:

```
ubuntu@stream:~/work$ python consumer.py c1
c1: assigned [0, 1, 2]
c1: partition 2 offset 0 rec-000005
c1: partition 2 offset 1 rec-000010
c1: partition 1 offset 0 car-000002
c1: partition 1 offset 1 nat-000003
c1: partition 1 offset 2 car-000007
c1: partition 1 offset 3 nat-000008
c1: partition 0 offset 0 oli-000001
c1: partition 0 offset 1 joa-000004
c1: partition 0 offset 2 oli-000006
c1: partition 0 offset 3 joa-000009
c1: revoked [0, 1, 2]
```

The first line is the assignment: alone in group `stock`, `c1` was given all three partitions. Then
the ten sales, in an order worth reading. **Within each partition they are in offset order**:
partition 2's two Recife sales, then partition 1's four, then partition 0's four. Across partitions
there is no order at all; the client happened to fetch partition 2 first, and Olinda's sale
`oli-000001`, the first one produced, came out seventh. Lesson 2's promise was order per key, and
that is exactly what arrived.

Ctrl+C ended the loop, and `close` handed the partitions back, which is the `revoked` line. It also
recorded how far `c1` had read. Ask Kafka what it knows about the group:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock

Consumer group 'stock' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock           sales           0          4               4               0               -               -               -
stock           sales           1          4               4               0               -               -               -
stock           sales           2          2               2               0               -               -               -
```

The group has no members now, and Kafka still remembers it. For each partition,
**`CURRENT-OFFSET` is the offset the group will read next**, `LOG-END-OFFSET` is the offset the
next message produced will get, and **`LAG`** is the difference: messages written and not yet read
by this group. All three are 0, because `c1` read everything. The group resumes at 4, 4 and 2, so
`c1` started again would have nothing to read until more sales arrive.

## Where a new group starts

A group that has never committed an offset has nowhere to resume from, and
**`auto.offset.reset`** decides: `earliest` starts at the beginning of each partition, and `latest`,
the default, starts at the end, so the group sees only messages produced after it joined. Lesson 1's
console consumer started at the end for the same reason. `consumer.py` sets `earliest`, so a new
group name reads everything there is, which is what the next sections rely on.
