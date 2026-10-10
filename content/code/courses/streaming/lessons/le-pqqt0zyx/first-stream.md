---
title: A first stream, and a reader that does not stop
version: 1
---

Ponto Final is a chain of five bookshops in the north-east of Brazil, and the example that runs
through this course. Until now its sales reached the warehouse once a night, in a file per shop.
What the stream changes is that **each sale becomes a message the moment the till rings it up**,
and whoever wants to know about sales reads them as they happen.

A **topic** is a named stream of messages in Kafka, the thing producers write to and consumers read
from. Make one called `sales`, with three **partitions** (lesson 3 says what they are; for now, the
topic is stored in three pieces):

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
```

`--bootstrap-server` is the address a Kafka tool contacts first, to learn about the rest of the
cluster. Every Kafka command takes one, and in this lab it is `localhost:9092`.

## A reader that waits

Kafka ships with a consumer that prints whatever arrives. Start it in your **second shell**, and
leave it there:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true
```

It prints one line about KIP-848, a newer protocol for coordinating consumers that lesson 4
returns to, and then nothing, and it does not return to the prompt. **That is the first thing
that is different about a stream.** A query reads what is there and finishes; this reads what is
there and then waits for what is not there yet, for as long as you let it.

## Something to read

Nobody is going to ring up books for you, so the course brings a till. This program makes up
sales for the five shops, with a clock of its own that starts at nine o'clock on 2 March 2026, and
sends each one to Kafka. Save it as `~/work/tills.py`:

```schooling-example
{
  "file": "tills.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"tills.py: the sales of Ponto Final's shops, as events, into Kafka.\n\n    python tills.py [--count N] [--rate R] [--topic T] [--seed S]\n\nEach event is one sale at one till. The shops, the books and the clock are\nmade up and fixed by the seed, so two runs with the same seed send the same\nsales. --rate is sales per second; 0 sends them as fast as Kafka takes them.\n\"\"\"\nimport argparse\nimport json\nimport random\nimport time\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Producer\n",
      "note": "What it does and how to call it. Every run with the same `--seed` sends the same sales, which is what lets a lesson quote the numbers you will see."
    },
    {
      "code": "SHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\nBOOKS = {\"bk-01\": 3990, \"bk-02\": 5490, \"bk-03\": 2990, \"bk-04\": 7900,\n         \"bk-05\": 4490, \"bk-06\": 6200, \"bk-07\": 3500, \"bk-08\": 8990}\nOPEN = datetime(2026, 3, 2, 9, 0, tzinfo=timezone(timedelta(hours=-3)))\n",
      "note": "Five shops and eight books, each with a price **in cents**, because money is never a float."
    },
    {
      "code": "args = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=20)\nargs.add_argument(\"--rate\", type=float, default=5)\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--seed\", type=int, default=1)\nargs = args.parse_args()\n",
      "note": "The arguments, with defaults that suit the lessons."
    },
    {
      "code": "rng = random.Random(args.seed)\nproducer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\nclock = OPEN",
      "note": "**A producer is the client that writes.** It needs one address to start from, and it learns the rest of the cluster from that node."
    },
    {
      "code": "for n in range(1, args.count + 1):\n    clock += timedelta(seconds=rng.randint(1, 20))\n    shop, book = rng.choice(SHOPS), rng.choice(list(BOOKS))\n    qty = rng.choice([1, 1, 1, 2, 3])\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": book,\n            \"qty\": qty, \"cents\": BOOKS[book] * qty, \"at\": clock.isoformat()}",
      "note": "One sale per turn of the loop. The clock moves on by up to twenty seconds of shop time, whatever the real time is, and **the moment of the sale travels inside the event**, as `at`."
    },
    {
      "code": "    producer.produce(args.topic, key=shop, value=json.dumps(sale))\n    producer.poll(0)\n    if args.rate:\n        time.sleep(1 / args.rate)",
      "note": "`produce` hands the message to the client, which sends it in the background. **The shop is the message's key**, which lesson 3 shows decides where it is stored. `poll(0)` lets the client report on what it has sent so far."
    },
    {
      "code": "producer.flush()\nprint(f\"sent {args.count} sales to {args.topic}, the last one at {clock:%H:%M:%S}\")",
      "note": "`flush` waits until every message has been acknowledged by the broker. Without it the program could end with sales still in its memory, and they would be lost."
    }
  ]
}
```

Now, in the **first shell**, send five sales at two a second:

```
ubuntu@stream:~/work$ python tills.py --count 5 --rate 2
sent 5 sales to sales, the last one at 09:00:24
```

It takes two and a half seconds. In the second shell, the sales arrived while they were being
sent, a line at a time, and the consumer is still waiting for the sixth. Stop it with Ctrl+C, and
it says how many it saw:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
joao-pessoa	{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
natal	{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
olinda	{"sale": "oli-000003", "shop": "olinda", "book": "bk-02", "qty": 2, "cents": 10980, "at": "2026-03-02T09:00:22-03:00"}
natal	{"sale": "nat-000004", "shop": "natal", "book": "bk-07", "qty": 3, "cents": 10500, "at": "2026-03-02T09:00:23-03:00"}
natal	{"sale": "nat-000005", "shop": "natal", "book": "bk-05", "qty": 1, "cents": 4490, "at": "2026-03-02T09:00:24-03:00"}
Processed a total of 5 messages
```

Each line is the key, a tab, and the message: the shop, then the sale. They came out in the order
they went in, which with three partitions is something Kafka promises less often than it looks;
lesson 3 says exactly when it holds.

## Reading it again

Run the same consumer again and it prints nothing: it started at the end, where new messages will
arrive, so the five old ones are behind it. Add `--from-beginning`:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --from-beginning --max-messages 5
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
{"sale": "oli-000003", "shop": "olinda", "book": "bk-02", "qty": 2, "cents": 10980, "at": "2026-03-02T09:00:22-03:00"}
{"sale": "nat-000004", "shop": "natal", "book": "bk-07", "qty": 3, "cents": 10500, "at": "2026-03-02T09:00:23-03:00"}
{"sale": "nat-000005", "shop": "natal", "book": "bk-05", "qty": 1, "cents": 4490, "at": "2026-03-02T09:00:24-03:00"}
Processed a total of 5 messages
```

**The five sales are still there.** Reading them did not remove them, and a second reader, or the
same one an hour later, gets them all again. That is the second thing that is different, and it is
what lesson 2 builds on: Kafka is not a queue that hands each message to one taker and forgets it,
but a log that keeps what was written for as long as it is told to.
