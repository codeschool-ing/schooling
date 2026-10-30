---
title: The pipeline, and a night run over a file
version: 1
---

**The pipeline is one program with two ends and one middle.** The middle reads lines of JSON,
keeps the orders that were placed, and adds them up per neighbourhood. One end reads a file and
writes files; the other reads a Pub/Sub subscription and publishes to a topic. This section runs
the file end, which is the nightly job, and the next section runs the stream end over the same
events.

## The evening's events

Quitanda's export is one event per line, each about an order: when it was placed, packed,
delivered or cancelled. This program writes an evening of them, from 19:00 to 20:00 on 15 October,
always the same 2,000 because the random generator is seeded, and then one more line cut off in the
middle, the way an export interrupted by a full disk ends. Save it as `~/gcp/events.py`:

`events.py`:

```python
"""events.py: one evening of Quitanda's order events, one JSON object a line.

    python3 events.py           writes events.jsonl
"""
import json
import random
from datetime import datetime, timedelta, timezone

random.seed(21)
SP = timezone(timedelta(hours=-3))
START = datetime(2026, 10, 15, 19, 0, tzinfo=SP)
NEIGHBOURHOODS = ['Butantã', 'Moema', 'Pinheiros', 'Santana', 'Tatuapé']
KINDS, WEIGHTS = ['placed', 'packed', 'delivered', 'cancelled'], [5, 4, 4, 1]

with open('events.jsonl', 'w', encoding='utf-8') as f:
    for i in range(2000):
        event = {'order_id': f'o-{10000 + i}',
                 'event': random.choices(KINDS, WEIGHTS)[0],
                 'neighbourhood': random.choice(NEIGHBOURHOODS),
                 'total_cents': random.randrange(1500, 30000),
                 'at': (START + timedelta(seconds=random.randrange(3600))).isoformat()}
        f.write(json.dumps(event, ensure_ascii=False) + '\n')
    f.write('{"order_id": "o-12000", "event": "placed", "total_cents": \n')
print('2,001 lines written to events.jsonl, the last one cut short')
```

```
ana@laptop:~/gcp$ python3 events.py
2,001 lines written to events.jsonl, the last one cut short
ana@laptop:~/gcp$ head -2 events.jsonl
{"order_id": "o-10000", "event": "placed", "neighbourhood": "Santana", "total_cents": 22307, "at": "2026-10-15T19:19:12-03:00"}
{"order_id": "o-10001", "event": "packed", "neighbourhood": "Moema", "total_cents": 27473, "at": "2026-10-15T19:32:24-03:00"}
```

**The field `at` is when the event happened**, and this lesson does not use it yet: a file is
totalled as one global window, and the stream of the next section is windowed by the time Pub/Sub
received each message. Lesson 22 puts `at` to work.

## The program

Save it as `~/gcp/orders_beam.py`:

```schooling-example
{"language": "python", "file": "orders_beam.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"orders_beam.py: the placed orders of Quitanda's events, totalled per neighbourhood.\n\n    python3 orders_beam.py --input events.jsonl --output out/\n    python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming\n\nTHE SAME TRANSFORMS RUN IN BOTH. Only the ends differ: where the lines come\nfrom, and where the totals and the unreadable lines go. A stream is cut into\nwindows of --window seconds, by the time Pub/Sub received each message.\n\"\"\"\nimport argparse\nimport json\nfrom datetime import datetime, timedelta, timezone\n\nimport apache_beam as beam\nfrom apache_beam.options.pipeline_options import PipelineOptions\nfrom apache_beam.transforms.window import FixedWindows, GlobalWindow\n\nPROJECT = 'planner-dev'\nSP = timezone(timedelta(hours=-3))\n\n\n", "note": "**The docstring says the one thing to remember: the same transforms run in both.** The two ways to run it are its first lines. Beam itself is three imports: the library, its options, and two kinds of window, one of which is the window a batch lives in without asking."}, {"code": "def parse(line):\n    try:\n        e = json.loads(line)\n        yield {'event': e['event'], 'neighbourhood': e['neighbourhood'],\n               'cents': int(e['total_cents'])}\n    except (ValueError, KeyError, TypeError):\n        yield beam.pvalue.TaggedOutput('unreadable', line)\n\n\n", "note": "`parse` is a `FlatMap` function: it yields a cleaned event for a good line and **a tagged output** for a bad one. A line that is not JSON, or lacks a field, goes to `unreadable` instead of stopping the pipeline, which at two in the morning is the difference between one bad line and no totals."}, {"code": "def add(pairs):\n    orders = cents = 0\n    for n, c in pairs:\n        orders, cents = orders + n, cents + c\n    return orders, cents\n\n\n", "note": "**The combining function.** It receives a list of `(orders, cents)` pairs, or of earlier results of itself, and adds them up. Beam may call it on parts of a key's values on different workers and then on the parts' results, so it must give the same answer in any grouping, which addition does."}, {"code": "class Format(beam.DoFn):\n    def process(self, total, window=beam.DoFn.WindowParam):\n        neighbourhood, (orders, cents) = total\n        if window == GlobalWindow():\n            when = 'all'\n        else:\n            when = datetime.fromtimestamp(float(window.start), SP).strftime('%H:%M:%S')\n        yield json.dumps({'window': when, 'neighbourhood': neighbourhood, 'orders': orders,\n                          'reais': f'{cents / 100:.2f}'}, ensure_ascii=False)\n\n\n", "note": "`Format` turns a total into one line of JSON. It asks Beam for the **window** the total belongs to: in batch that is the global window, written `all`, and in stream the start of the minute, in São Paulo time."}, {"code": "class PlacedTotals(beam.PTransform):\n    def expand(self, lines):\n        parsed = lines | 'Parse' >> beam.FlatMap(parse).with_outputs('unreadable', main='events')\n        totals = (parsed.events\n                  | 'Placed' >> beam.Filter(lambda e: e['event'] == 'placed')\n                  | 'Key' >> beam.Map(lambda e: (e['neighbourhood'], (1, e['cents'])))\n                  | 'Add' >> beam.CombinePerKey(add)\n                  | 'Format' >> beam.ParDo(Format()))\n        return totals, parsed.unreadable\n\n\n", "note": "**The pipeline proper, as one composite transform.** `expand` receives a collection of lines and returns two: the totals and the unreadable lines. It knows nothing about files or Pub/Sub, and that is what lets the same five steps run over either."}, {"code": "def main():\n    ap = argparse.ArgumentParser()\n    ap.add_argument('--input')\n    ap.add_argument('--output')\n    ap.add_argument('--subscription')\n    ap.add_argument('--topic')\n    ap.add_argument('--window', type=int, default=60)\n    ap.add_argument('--runner', default='BundleBasedDirectRunner')\n    args, beam_args = ap.parse_known_args()\n    options = PipelineOptions(beam_args, runner=args.runner)\n\n", "note": "The options. Everything the program does not know, such as `--streaming` or `--project`, is passed on to Beam. **The runner defaults to `BundleBasedDirectRunner`**, the runner inside Python, for the reason the previous section gave; `--runner=DataflowRunner` overrides it."}, {"code": "    with beam.Pipeline(options=options) as p:\n        if args.input:\n            lines = p | 'Read' >> beam.io.ReadFromText(args.input)\n        else:\n            lines = (p\n                     | 'Read' >> beam.io.ReadFromPubSub(\n                         subscription=f'projects/{PROJECT}/subscriptions/{args.subscription}')\n                     | 'Decode' >> beam.Map(lambda data: data.decode('utf-8')))\n            if args.window:\n                lines = lines | 'Window' >> beam.WindowInto(FixedWindows(args.window))\n\n", "note": "**The first end.** A file is read with `ReadFromText`, one element per line. Pub/Sub is read with `ReadFromPubSub`, one element per message, as bytes; and a stream is cut into fixed windows of `--window` seconds. `--window 0` leaves the window out, to see why it is there."}, {"code": "        totals, unreadable = lines | 'Totals' >> PlacedTotals()\n\n        if args.input:\n            totals | 'WriteTotals' >> beam.io.WriteToText(\n                args.output + 'totals', file_name_suffix='.jsonl')\n            unreadable | 'WriteUnreadable' >> beam.io.WriteToText(\n                args.output + 'unreadable', file_name_suffix='.txt')\n        else:\n            (totals | 'EncodeTotals' >> beam.Map(lambda s: s.encode('utf-8'))\n                    | 'WriteTotals' >> beam.io.WriteToPubSub(\n                        f'projects/{PROJECT}/topics/{args.topic}'))\n            (unreadable | 'EncodeUnreadable' >> beam.Map(lambda s: s.encode('utf-8'))\n                        | 'WriteUnreadable' >> beam.io.WriteToPubSub(\n                            f'projects/{PROJECT}/topics/{args.topic}-unreadable'))\n\n\nif __name__ == '__main__':\n    main()\n", "note": "**The other end.** The same two collections go to files in batch, through `WriteToText`, and to two Pub/Sub topics in stream, through `WriteToPubSub`. Leaving the `with` block runs the pipeline and waits for it to finish, which a stream never does."}]}
```

**Five steps, and only one of them brings elements together.** `Parse`, `Placed`, `Key` and
`Format` each look at one element and know nothing of the others, so a runner can give each worker
any slice of the input. `Add` is the one that needs every placed order of Moema in one place, and in
Beam that is a `CombinePerKey`: a `GroupByKey` that also adds as it goes. **On Dataflow that step is
the shuffle**, where elements cross between workers by key, and it is the step with a line of its
own on the bill in the last section. A combine is cheaper than a plain group for the same reason a
`GROUP BY` is cheaper than fetching every row: each worker adds up its own slice first, and only the
partial sums travel.

## The night run

```
ana@laptop:~/gcp$ time python3 orders_beam.py --input events.jsonl --output out/

real	0m5.666s
user	0m1.645s
sys	0m0.163s
ana@laptop:~/gcp$ ls out/
totals-00000-of-00001.jsonl
unreadable-00000-of-00001.txt
ana@laptop:~/gcp$ sort out/totals-*
{"window": "all", "neighbourhood": "Butantã", "orders": 150, "reais": "23835.54"}
{"window": "all", "neighbourhood": "Moema", "orders": 138, "reais": "22737.55"}
{"window": "all", "neighbourhood": "Pinheiros", "orders": 161, "reais": "24949.60"}
{"window": "all", "neighbourhood": "Santana", "orders": 140, "reais": "22367.32"}
{"window": "all", "neighbourhood": "Tatuapé", "orders": 152, "reais": "26061.58"}
ana@laptop:~/gcp$ cat out/unreadable-*
{"order_id": "o-12000", "event": "placed", "total_cents": 
```

**Five totals, one bad line kept aside, in a few seconds.** 741 of the 2,000 events
were `placed`, and the five counts add up to that number. The cut-off line did not stop the run: it
went down the second output and was written, whole, to its own file, where somebody can see what the
shop sent. A pipeline that crashed on it would have produced no totals at all, and one that skipped
it in silence would have produced totals one order short with nothing to say so.

**The file names are Beam's: `-00000-of-00001` is shard 0 of 1.** A sink in Beam writes as many
files as it has parallel writers, and names them so that a reader can tell whether it has all of
them. Here one process wrote one shard of each. Dataflow, with ten workers, would write several,
and the number after `of` would say how many to expect. For a path in Cloud Storage the program
needs no change: `--output gs://quitanda-curated-prod/orders/totals/` is a valid argument to
`WriteToText`, with the `gcp` extra installed.

**And the window is `all`.** A bounded collection that nobody windows lives in the global window,
and `Format` writes that word. The totals are for the whole file, which for a nightly export is the
whole day and is what the job is for.
