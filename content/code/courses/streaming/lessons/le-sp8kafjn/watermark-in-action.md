---
title: A watermark in action
version: 1
---

**This program runs lesson 10's sales through five-minute tumbling windows that close only when a
watermark passes their end.** It prints one line per sale as it arrives, with the watermark after
it, and a line for every window it emits. Two sales are added to lesson 10's ten: one from
09:04:30 that arrives eleventh, much too late, and one from 09:23:10 that moves time on.

Save it as `~/work/watermark.py`:

```schooling-example
{
  "file": "watermark.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"watermark.py: five-minute windows that close when a watermark says so.\n\n    python watermark.py [--bound MIN] [--lateness MIN] [--partitions N] [--idle K]\n                        [--late-topic TOPIC]\n\nThe watermark is the latest event time seen, minus --bound minutes. A window\nis emitted when the watermark passes its end, kept --lateness minutes more for\nlate sales, and then forgotten. With --partitions, each shop's sales come from\none of N partitions and the watermark is the lowest of theirs; --idle K leaves\nout a partition that has had nothing for the last K sales. --late-topic sends\nsales too late to count to that Kafka topic instead of dropping them.\n\"\"\"\nimport argparse\nimport json\n\nSALES = [  # (when it happened, shop, cents), in the order they arrived\n    (\"09:00:40\", \"recife\", 3990), (\"09:02:10\", \"natal\", 5490),\n    (\"09:03:55\", \"olinda\", 2990), (\"09:05:00\", \"recife\", 7900),\n    (\"09:06:20\", \"natal\", 4490), (\"09:12:30\", \"caruaru\", 6200),\n    (\"09:13:05\", \"recife\", 3500), (\"09:08:50\", \"natal\", 8990),\n    (\"09:14:10\", \"olinda\", 2990), (\"09:21:00\", \"recife\", 5490),\n    (\"09:04:30\", \"natal\", 4490), (\"09:23:10\", \"olinda\", 3990),\n]",
      "note": "The usage, and twelve sales in the order they arrived: lesson 10's ten, then **a sale from 09:04:30 that arrives eleventh**, and one more at 09:23:10."
    },
    {
      "code": "PARTITION = {\"recife\": 0, \"olinda\": 0, \"natal\": 1, \"caruaru\": 1, \"joao-pessoa\": 2}\nSIZE = 300\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--bound\", type=float, default=2)\nargs.add_argument(\"--lateness\", type=float, default=0)\nargs.add_argument(\"--partitions\", type=int, default=1)\nargs.add_argument(\"--idle\", type=int, default=0)\nargs.add_argument(\"--late-topic\")\nargs = args.parse_args()\nbound, lateness = int(args.bound * 60), int(args.lateness * 60)\n\n",
      "note": "Which partition each shop's sales come from when `--partitions` asks for more than one, the window size in seconds, and the options in minutes."
    },
    {
      "code": "def secs(when):\n    h, m, s = map(int, when.split(\":\"))\n    return h * 3600 + m * 60 + s\n\n\ndef clock(t):\n    return \"--:--:--\" if t is None else f\"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}\"\n\n",
      "note": "The same two helpers as `windows.py`; a time that does not exist yet prints as dashes."
    },
    {
      "code": "latest = {p: None for p in range(args.partitions)}   # latest event time per partition\nquiet = {p: 0 for p in range(args.partitions)}       # sales since each partition's last\nwindows, emitted, watermark = {}, set(), None\nproducer = None\nif args.late_topic:\n    from confluent_kafka import Producer\n    producer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\n\n",
      "note": "The state: the latest event time per partition, how many sales each partition has gone without, the open windows, the ones already emitted, and the watermark. A producer only if `--late-topic` was given."
    },
    {
      "code": "def advance():\n    live = [p for p in latest if not (args.idle and quiet[p] >= args.idle)]\n    seen = [latest[p] for p in live]\n    if not seen or None in seen:\n        return None\n    return min(seen) - bound\n\n",
      "note": "**The watermark: the lowest of the partitions' latest event times, minus the bound.** A partition with nothing yet holds it back entirely, unless `--idle` has left it out."
    },
    {
      "code": "def say(n, t, shop, what):\n    print(f\"{n:2d}  {clock(t)}  {shop:8}  {clock(watermark)}  {what}\")\n\n",
      "note": "One line per sale: its number, when it happened, the shop, the watermark after it arrived, and what happened to it."
    },
    {
      "code": "print(\" #  happened  shop      watermark  what happened\")\nfor n, (when, shop, cents) in enumerate(SALES, 1):\n    t, p = secs(when), PARTITION[shop] % args.partitions\n    for q in quiet:\n        quiet[q] = 0 if q == p else quiet[q] + 1\n    start = t // SIZE * SIZE",
      "note": "The loop. Each sale is activity for its own partition and one more sale of silence for every other, and it belongs to the five-minute window its time falls in."
    },
    {
      "code": "    window = f\"{clock(start)}-{clock(start + SIZE)}\"\n    if watermark is not None and start + SIZE + lateness <= watermark:\n        if producer:\n            producer.produce(args.late_topic, key=shop, value=json.dumps(\n                {\"at\": when, \"shop\": shop, \"cents\": cents, \"watermark\": clock(watermark)}))\n            say(n, t, shop, f\"too late for {window}: sent to {args.late_topic}\")\n        else:\n            say(n, t, shop, f\"too late for {window}: dropped\")\n        continue",
      "note": "**If the watermark has already passed the window's end plus the lateness, the window is gone**: the sale is dropped, or sent to the late topic."
    },
    {
      "code": "    count, total = windows.get(start, (0, 0))\n    windows[start] = (count + 1, total + cents)\n    if latest[p] is None or t > latest[p]:\n        latest[p] = t\n    new = advance()\n    if new is not None and (watermark is None or new > watermark):\n        watermark = new\n    if start in emitted:\n        say(n, t, shop, f\"late, {window} now {count + 1} sales, {total + cents}\")\n    else:\n        say(n, t, shop, \"\")",
      "note": "Otherwise it is counted, its partition's latest time moves, and **the watermark moves forward, never back**. A sale for a window already emitted is reported as a late update."
    },
    {
      "code": "    for s in sorted(windows):\n        if s not in emitted and s + SIZE <= (watermark or 0):\n            emitted.add(s)\n            print(f\"{'':30}emit {clock(s)}-{clock(s + SIZE)}: {windows[s][0]} sales, {windows[s][1]}\")\n    for s in [s for s in windows if s + SIZE + lateness <= (watermark or 0)]:\n        del windows[s]\n",
      "note": "Every window whose end the watermark has passed is emitted once; every window whose end plus lateness it has passed is forgotten."
    },
    {
      "code": "if producer:\n    producer.flush()\nprint(\"still open: \" + (\", \".join(f\"{clock(s)} ({windows[s][0]})\" for s in sorted(windows)\n                                  if s not in emitted) or \"nothing\"))",
      "note": "At the end, what is still open. An engine reading a stream never gets here; one reading a finished input would emit these too."
    }
  ]
}
```

With the default bound of two minutes and no lateness allowed:

```
ubuntu@stream:~/work$ python watermark.py
```

Read it a line at a time, because each line is a decision.

**Sales 1 to 5** move the watermark along two minutes behind them: 08:58:40, 09:00:10, up to
09:04:20 after sale 5. No window ends before 09:05, so nothing is emitted, although sales 1 to 3
are all in the 09:00 window and the clock of the events has passed 09:05.

**Sale 6, from 09:12:30**, moves the watermark to 09:10:30, which is past the end of two windows.
Both are emitted at once: 09:00 to 09:05 with three sales and 12,470 cents, and 09:05 to 09:10
with two sales and 12,390. **That is the moment the processor commits to an answer**, and it
commits to two at once because one sale moved time on by six minutes.

**Sale 8, from 09:08:50**, arrives with the watermark at 09:11:05. Its window ended at 09:10,
before the watermark, and with no lateness allowed the window is already gone: the sale is
dropped. The 09:05 window stays reported as two sales, where lesson 10, which saw everything,
counted three. **The watermark lost its bet on sale 8 by 1 minute and 5 seconds**, the distance
between its window's end and the watermark when it arrived.

**Sale 10, from 09:21:00**, moves the watermark to 09:19:00 and closes 09:10 to 09:15. **Sale 11,
from 09:04:30**, is dropped too; the watermark was already fourteen minutes past its window's end.
Sale 12 moves the watermark to 09:21:10, which does not reach 09:25, so the last window is still
open when the list ends.

## What it got right and wrong

Three windows were emitted, each once, and each at a moment set by event times alone: run it again
and they come out at the same lines. Two of the twelve sales were lost, 13,480 cents that never
reached any total. Whether that is acceptable is not a property of the program. It depends on what
the totals are for and what else catches the two sales, which is what the next three sections are
about: keeping windows open a little longer, sending late sales somewhere instead of nowhere, and
choosing the bound from measurement instead of habit.
