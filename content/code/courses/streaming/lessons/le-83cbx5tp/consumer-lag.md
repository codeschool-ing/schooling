---
title: Consumer lag, the first number to watch
version: 1
---

**A consumer that is slower than its producer does not fail. It falls behind, quietly, and keeps
falling.** Nothing in the program reports an error: every sale it handles is handled correctly, only
later and later. The stock count on Ponto Final's website is right about ten minutes ago, then
twenty, then an hour, and the first person to notice is a customer. The distance between what has
been written and what has been read is called **consumer lag**, and it is the number everybody who
runs a stream learns to watch first.

## A consumer that takes its time

To see lag you need a consumer slower than the tills. This one pretends that updating the stock for
each sale takes a tenth of a second, and every fifty sales it says how far it has got. Save it as
`~/work/slow_consumer.py`:

```schooling-example
{
  "file": "slow_consumer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"slow_consumer.py: a consumer that takes its time over every sale.\n\n    python slow_consumer.py [--group G] [--delay S] [--max-poll MS]\n\nFor each sale it pretends to update the stock by sleeping --delay seconds.\n--max-poll is how long, in milliseconds, it may go between two polls before\nthe group gives up on it.\n\"\"\"\nimport argparse\nimport json\nimport time\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--group\", default=\"stock\")\nargs.add_argument(\"--delay\", type=float, default=0.1)\nargs.add_argument(\"--max-poll\", type=int, default=300000)\nargs = args.parse_args()\n",
      "note": "What it is for, and its three knobs. `--max-poll` waits for the section on backpressure; leave it alone for now."
    },
    {
      "code": "consumer = Consumer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"auto.commit.interval.ms\": 1000,\n    \"max.poll.interval.ms\": args.max_poll,\n    \"session.timeout.ms\": min(args.max_poll, 45000),\n    \"partition.assignment.strategy\": \"roundrobin\",\n})\n",
      "note": "**The group's committed position is what the lag tools read**, so it is committed every second rather than every five, the default, to keep the numbers close to the truth. `roundrobin` deals the partitions out one at a time when a group has several members; the backpressure section needs that."
    },
    {
      "code": "def now():\n    return time.strftime(\"%H:%M:%S\")\n\ndef assigned(consumer, parts):\n    print(now(), \"assigned\", [p.partition for p in parts], flush=True)\n\ndef revoked(consumer, parts):\n    print(now(), \"revoked\", [p.partition for p in parts], flush=True)\n\nconsumer.subscribe([\"sales\"], on_assign=assigned, on_revoke=revoked)\n",
      "note": "Two callbacks that print when the group hands this consumer its partitions and when it takes them away. Lesson 4 met them; here they are the evidence of a rebalance."
    },
    {
      "code": "done = 0\ntry:\n    while True:\n        msg = consumer.poll(1.0)\n        if msg is None:\n            continue\n        if msg.error():\n            print(now(), \"error:\", msg.error().str(), flush=True)\n            continue\n        sale = json.loads(msg.value())\n        time.sleep(args.delay)\n        done += 1\n        if done % 50 == 0 or args.delay >= 1:\n            print(now(), f\"{done} done, last {sale['sale']}\",\n                  f\"from partition {msg.partition()} offset {msg.offset()}\", flush=True)\nexcept KeyboardInterrupt:\n    pass\nfinally:\n    consumer.close()",
      "note": "The loop. **The `sleep` is the slow part**: a database write, a call to another service, whatever your real consumer does with a sale."
    }
  ]
}
```

Start from an empty topic, the same `sales` with three partitions as in lesson 1. If yours already
holds sales, `./cluster.sh stop`, `new 1` and `start` give you a clean one.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

In the second shell, start the consumer. It joins the group `stock` and waits:

```
ubuntu@stream:~/work$ python slow_consumer.py --delay 0.1
```

This section needs a **third shell**, opened the same way as the second, with `multipass shell
stream`. In it, make the tills ring up 600 sales at twenty a second, twice what the consumer can
handle. It takes half a minute, and the first shell stays free for watching:

```
ubuntu@stream:~/work$ python tills.py --count 600 --rate 20
```

## Reading the lag

`kafka-consumer-groups.sh --describe` asks the cluster where a group is. Ten seconds into the run:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

One line per partition, and three numbers on each that are the whole subject of this section:

| column | what it is |
|---|---|
| `LOG-END-OFFSET` | the offset the next message written to the partition will get: how much has been written |
| `CURRENT-OFFSET` | the group's committed position: the next message it will read |
| `LAG` | the difference: messages written and not yet handled |

Partition 2 shows `-`: none of the five shops' keys lands there (lesson 3 says why keys and
partitions pair the way they do), so the group has nothing to commit in it. Ten seconds later:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

**The lag has grown, and it grows by the difference between the two rates**: twenty a second in,
ten a second out, so about ten more each second. In the third shell the tills finish on time, thirty
seconds after they started, whatever the consumer is doing:

```
ubuntu@stream:~/work$ python tills.py --count 600 --rate 20
```

From that moment the lag stops growing and starts to shrink at the consumer's full speed:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"One partition drawn as a row of numbered messages. The producer appends on the right; the log-end offset is the next free slot. The consumer group's committed offset sits further left, at the first message not yet handled. The messages between the two are the lag.\" data-fig=\"l16-lag\"><defs><marker id=\"l16-lag-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l16-lag-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"57.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"78\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"116\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"133.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"154\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"192\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"209.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"230\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"247.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"268\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"306\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"344\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"361.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"382\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"399.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"420\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"437.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"458\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"496\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"513.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"534\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"551.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"572\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"589.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"610\" y=\"90\" width=\"34\" height=\"34\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"627.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">15</text><path d=\"M 40 78 L 40 72 L 302 72 L 302 78\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"171.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">handled</text><path d=\"M 306 78 L 306 72 L 606 72 L 606 78\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">waiting: the lag</text><line x1=\"323.0\" y1=\"154\" x2=\"323.0\" y2=\"128\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l16-lag-ah-726)\"></line><text x=\"323.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CURRENT-OFFSET</text><text x=\"323.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">next to read</text><line x1=\"627.0\" y1=\"154\" x2=\"627.0\" y2=\"128\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#l16-lag-ah-2105)\"></line><text x=\"607.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">LOG-END-OFFSET</text><text x=\"607.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">next to write</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">lag = 15 − 7 = 8</text><path d=\"M 668 107.0 L 648 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-lag-ah-2105)\"></path><text x=\"656\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">producer appends</text></svg>", "caption": "Lag is counted between two positions in the same partition: where the group will read next, and where the producer will write next."}
```

Half a minute after that, the consumer has caught up and the lag is zero on every partition that has
data:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

Two things about the numbers deserve suspicion. **The lag is measured from the last commit, not from
the message being handled**, so it is up to a second stale here and up to five with the default
interval; a consumer that never commits shows a lag that never moves even while it works. And a lag
of zero says the group has read everything, not that it handled it correctly. Leave the consumer
running: the section on replay needs it.
