---
title: Counting by arrival, and counting by event
version: 1
---

**The same sales, counted per hour, give two different tables depending on which clock decides the
hour.** Neither table is a bug in the counting. Each is the correct answer to a different question,
and the mistake is to publish one while believing it is the other.

This program reads the `late` topic from the start and counts every sale twice: once in the bucket
its record's timestamp falls in, which is when it arrived, and once in the bucket its `at` falls
in, which is when it happened. Save it as `~/work/per_minute.py`:

```schooling-example
{
  "file": "per_minute.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"per_minute.py: sales per minute, counted by two clocks.\n\n    python per_minute.py [--topic T] [--size MINUTES] [--from HH:MM] [--to HH:MM]\n\nReads the whole topic, then prints, for each bucket of --size minutes, how many\nsales ARRIVED in it (the record's timestamp) and how many HAPPENED in it (the\nsale's own \"at\").\n\"\"\"\nimport argparse\nimport json\nfrom collections import Counter\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Consumer, TopicPartition, OFFSET_BEGINNING\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--topic\", default=\"late\")\nargs.add_argument(\"--size\", type=int, default=1)\nargs.add_argument(\"--from\", dest=\"start\", default=\"00:00\")\nargs.add_argument(\"--to\", dest=\"end\", default=\"23:59\")\nargs = args.parse_args()\nLOCAL = timezone(timedelta(hours=-3))\n",
      "note": "What it does. Buckets are a minute long unless `--size` says otherwise, and `--from` and `--to` trim what is printed."
    },
    {
      "code": "def bucket(t):\n    t = t.astimezone(LOCAL)\n    minute = (t.hour * 60 + t.minute) // args.size * args.size\n    return f\"{minute // 60:02d}:{minute % 60:02d}\"\n",
      "note": "**A bucket is the start of the slice of the day a moment falls in**: 10:37 is in the 10:00 bucket of an hour, and in the 10:37 bucket of a minute."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"per-minute\",\n                     \"enable.partition.eof\": True, \"enable.auto.commit\": False})\nconsumer.assign([TopicPartition(args.topic, 0, OFFSET_BEGINNING)])",
      "note": "It reads partition 0 from the first offset and stops at the end of it: `enable.partition.eof` turns the end into a message the loop can see. Nothing is committed, so every run reads it all."
    },
    {
      "code": "arrived, happened = Counter(), Counter()\nwhile True:\n    msg = consumer.poll(5)\n    if msg is None or msg.error():\n        break\n    sale = json.loads(msg.value())\n    arrived[bucket(datetime.fromtimestamp(msg.timestamp()[1] / 1000, LOCAL))] += 1\n    happened[bucket(datetime.fromisoformat(sale[\"at\"]))] += 1\nconsumer.close()\n",
      "note": "The heart of it: **one sale, two buckets.** `msg.timestamp()` is a pair, the type and the milliseconds; the second is the arrival."
    },
    {
      "code": "print(f\"{'minute' if args.size == 1 else 'from':>6}  arrived  happened\")\nfor b in sorted(set(arrived) | set(happened)):\n    if args.start <= b <= args.end:\n        print(f\"{b:>6}  {arrived[b]:7d}  {happened[b]:8d}\")",
      "note": "One line per bucket that has anything in either column."
    }
  ]
}
```

A program that consumed the sales live would use its own clock as processing time, and that clock
would be a few milliseconds behind each record's arrival. Reading after the fact, as this one does,
its own clock would put all 360 sales into the minute you ran it, which says nothing. **So the
record's timestamp stands in for processing time**: it is the moment a reader keeping up would
have seen the sale.

Per hour first:

```
ubuntu@stream:~/work$ python per_minute.py --size 60
```

Read down the two columns. Up to ten o'clock they nearly agree; the one sale of difference is a
sale at the end of the nine o'clock hour that arrived in the ten o'clock one. From 10:00 to 13:00
the arrived column is short every hour, by 5, 11, 13 and 9, and then the 14:00 hour has 93 where
54 happened. **Both columns add up to 360.** No sale is lost and none is counted twice; the
arrival column has moved 38 of them, all from Natal, into the hour their till reconnected, and two
more across the edge of an hour by a few seconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Bars of sales per hour, two per hour. Counted by event time the hours from 10:00 to 13:00 have 62, 59, 54 and 60 sales and 14:00 has 54. Counted by arrival, those four hours have 57, 48, 41 and 51, and 14:00 has 93.\" data-fig=\"l9-per-hour\"><line x1=\"60\" y1=\"250\" x2=\"700\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sales</text><text x=\"54\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"54\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><line x1=\"60\" y1=\"150.0\" x2=\"700\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"54\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"60\" y1=\"50.0\" x2=\"700\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><rect x=\"70\" y=\"136.0\" width=\"30\" height=\"114.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"104\" y=\"138.0\" width=\"30\" height=\"112.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">57</text><text x=\"119\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">56</text><text x=\"102\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">09:00</text><rect x=\"160\" y=\"126.0\" width=\"30\" height=\"124.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"194\" y=\"136.0\" width=\"30\" height=\"114.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">62</text><text x=\"209\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">57</text><text x=\"192\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:00</text><rect x=\"250\" y=\"132.0\" width=\"30\" height=\"118.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"284\" y=\"154.0\" width=\"30\" height=\"96.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">59</text><text x=\"299\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">48</text><text x=\"282\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11:00</text><rect x=\"340\" y=\"142.0\" width=\"30\" height=\"108.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"374\" y=\"168.0\" width=\"30\" height=\"82.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">54</text><text x=\"389\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">41</text><text x=\"372\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><rect x=\"430\" y=\"130.0\" width=\"30\" height=\"120.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"464\" y=\"148.0\" width=\"30\" height=\"102.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">60</text><text x=\"479\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">51</text><text x=\"462\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13:00</text><rect x=\"520\" y=\"142.0\" width=\"30\" height=\"108.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"64.0\" width=\"30\" height=\"186.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">54</text><text x=\"569\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">93</text><text x=\"552\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14:00</text><rect x=\"610\" y=\"222.0\" width=\"30\" height=\"28.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"644\" y=\"222.0\" width=\"30\" height=\"28.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">14</text><text x=\"659\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">14</text><text x=\"642\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><rect x=\"460\" y=\"18\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"476\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">happened</text><rect x=\"570\" y=\"18\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arrived</text></svg>", "caption": "The same 360 sales per hour. By arrival, the morning loses Natal's sales and 14:00 gains them all."}
```

The minute around 14:00 shows where they went:

```
ubuntu@stream:~/work$ python per_minute.py --from 13:58 --to 14:03
```

**Thirty-nine sales arrived in the minute 14:00, and none happened in it.** A dashboard of sales
per minute by arrival would show a spike there, and a quiet spell in Natal from 10:20 to 14:00. An
alert of the kind "Natal has sold nothing for an hour" would have fired before half past eleven, been true by
arrival and false by event, and been cleared at 14:00 by a burst that looks like a rush of
customers. A stock count built on it would be wrong all morning in a way nobody could see.

## The price of the right column

The happened column is what the manager means by "sales between ten and eleven", and it is the one
to publish. But look at what it cost: at 11:00, the 10:00 hour by event time was not 62. It was 62
minus every Natal sale still in the till. **An event-time result is correct only once every event
that belongs to it has arrived, and the processor cannot know when that is.** It either waits,
publishes and corrects later, or decides that some events are too late to count. Lesson 10 gives
those buckets their proper name, windows, and lesson 11 is entirely about that decision.
