---
title: Retention arithmetic
version: 1
---

**The disk a topic needs is not a guess and not a default; it is a multiplication you can do
before the topic exists.** The four factors are the ones from the first section of this lesson:
messages a day, bytes per message on disk, days kept, and copies. Multiply them, then leave room,
because a disk that fills stops the broker (lesson 16).

The arithmetic is short enough to do by hand and easy enough to get wrong by a factor of a thousand,
so here it is as a program. Save it as `~/work/bill.py`:

```schooling-example
{
  "file": "bill.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"bill.py: how much disk a topic needs.\n\n    python bill.py MESSAGES_PER_DAY BYTES_PER_MESSAGE DAYS COPIES\n\"\"\"\nimport sys\n\nper_day, size, days, copies = (float(a) for a in sys.argv[1:5])\n\ndef human(n):\n    for unit in (\"B\", \"KB\", \"MB\", \"GB\", \"TB\", \"PB\"):\n        if n < 1000:\n            return f\"{n:.1f} {unit}\"\n        n /= 1000\n    return f\"{n:.1f} EB\"\n",
      "note": "Four numbers in, and the units out are decimal: a gigabyte here is a thousand million bytes, as a disk's label counts."
    },
    {
      "code": "print(\"written per day     \", human(per_day * size))\nprint(\"average write rate  \", human(per_day * size / 86400) + \"/s\")\n",
      "note": "**The average write rate** is what a day spreads over its seconds. Real traffic has peaks several times higher, and the brokers have to absorb those."
    },
    {
      "code": "print(\"kept, one copy      \", human(per_day * size * days))\nprint(\"kept, all copies    \", human(per_day * size * days * copies))",
      "note": "Retention keeps `days` of it, and every copy is a full copy."
    }
  ]
}
```

## Ponto Final's sales

Five shops, open twelve hours, together ringing up about 20 000 sales a day on a good one. The
compression section measured BYTES bytes a sale with `zstd`. A week of retention, so a replay can
reach back to last Monday, and three copies, as in lesson 5:

```
ubuntu@stream:~/work$ python bill.py 20000 17 7 3
```

**Ponto Final's sales fit on a memory card.** That is the honest result for a small business: the
storage of its stream is negligible, and the bill is the always-on compute of the first section.
Keeping them a year instead of a week changes the number, and not the conclusion:

```
ubuntu@stream:~/work$ python bill.py 20000 17 365 3
```

## A topic where storage is the bill

Now a different business: a website's clickstream, every page view, search and click. Suppose 50
million events a day, and 400 bytes each on disk after compression, since a page view carries a URL,
a referrer and a description of the device. These two numbers are an assumption for the example, not
a measurement. The same week and the same three copies:

```
ubuntu@stream:~/work$ python bill.py 50000000 400 7 3
```

**The same arithmetic, and now the disk is the decision.** Each factor is a lever, and they are not
equally easy to pull:

| lever | effect | cost of pulling it |
|---|---|---|
| days kept | linear | replays cannot reach further back |
| compression | divides by its ratio | processor time on producers and consumers |
| copies | linear | one fewer failure survived; never below 3 for data that matters |
| bytes per message | linear | a schema change (lesson 6); dropping fields somebody reads |
| messages a day | linear | it is the business; filter or sample only what nobody needs whole |

## Setting it

Retention is per topic, in milliseconds, and the broker's default is seven days. Setting it explicitly
on the topic means the number is written where somebody reading the topic will see it:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name sales-zstd --alter --add-config retention.ms=604800000
```

604 800 000 milliseconds is seven days. `retention.bytes` caps a partition by size instead, and
when both are set the first limit reached wins. Either way **deletion is per segment** (lesson 3):
a segment goes only when its newest message is past the limit, so a partition holds up to one
segment more than the arithmetic says, and with the default segment of a gigabyte that is a real
margin on a quiet topic.
