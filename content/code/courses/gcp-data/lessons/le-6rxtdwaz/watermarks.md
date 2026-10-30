---
title: The watermark, and the orders it leaves behind
version: 1
---

**A watermark is a source's claim about event time: nothing placed before this moment is still on
its way.** It moves forward as the stream moves, and it is what closes a window. When the
watermark passes 19:05, the runner concludes that the window from 19:00 to 19:05 has everything it
will ever get, computes the group, and emits it. Without a watermark a stream window could never
close, for the reason lesson 21's `--window 0` refused to run: there would be no moment at which
waiting longer stopped being worth it.

**The claim is a guess, and that is the part people do not expect.** A source knows what it has
received, not what is still sitting in a phone in a lift. Every source in Beam estimates its
watermark somehow, from the oldest timestamp it still holds, from its backlog, or from a fixed
allowance, and an element whose event time is already behind the watermark when it arrives is
**late**. What happens to late data is a decision you make in the pipeline, and the default is the
one that surprises.

## A stream you control

The program replays the evening through `arrivals` from `evening.py`: the orders in the order
they arrived, the processing-time clock moved to each arrival, and the watermark kept **one minute
behind the latest arrival**, a source that assumes nothing is more than a minute late. That is the
dashed line in the figure two sections back, and the three orders above it are the ones this
watermark will call late. Save it as `~/gcp/late.py`:

```schooling-example
{"language": "python", "file": "late.py", "parts": [{"code": "\"\"\"late.py: the evening replayed as a stream, with a watermark and a trigger.\n\n    python3 late.py                       on time only; late orders are dropped\n    python3 late.py --lateness 300        late orders up to five minutes, each fires a pane\n    python3 late.py --lateness 300 --early --mode discarding\n\"\"\"\nimport argparse\n\nimport apache_beam as beam\nfrom apache_beam.options.pipeline_options import PipelineOptions, StandardOptions\nfrom apache_beam.transforms import trigger\nfrom apache_beam.transforms.window import FixedWindows\n\nfrom evening import arrivals, clock\n\n", "note": "**The docstring lists the three runs this lesson makes.** `trigger` is Beam's module of triggers, and `arrivals` is the TestStream from `evening.py`."}, {"code": "ap = argparse.ArgumentParser()\nap.add_argument('--lateness', type=int, default=0)\nap.add_argument('--early', action='store_true')\nap.add_argument('--mode', choices=['accumulating', 'discarding'], default='accumulating')\nargs = ap.parse_args()\n\n", "note": "Three options, each one setting of the window: seconds of **allowed lateness**, whether to fire **early**, and the **accumulation mode**. With none of them the window behaves as Beam's default."}, {"code": "early = trigger.AfterProcessingTime(60) if args.early else None\nlate = trigger.AfterCount(1) if args.lateness else None\nmode = {'accumulating': trigger.AccumulationMode.ACCUMULATING,\n        'discarding': trigger.AccumulationMode.DISCARDING}[args.mode]\nTIMING = {0: 'EARLY', 1: 'ON_TIME', 2: 'LATE', 3: 'UNKNOWN'}\n\n\n", "note": "**The trigger, built from the options.** `AfterWatermark` fires when the watermark passes the end of the window; `early` adds panes before that, a minute of processing time after the pane's first element, and `late` adds one pane for each late element that is still allowed in. `TIMING` names the codes Beam gives a pane."}, {"code": "class Show(beam.DoFn):\n    def process(self, total, window=beam.DoFn.WindowParam, pane=beam.DoFn.PaneInfoParam):\n        neighbourhood, cents = total\n        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}'\n              f'  {TIMING[pane.timing]:<8} pane {pane.index}')\n\n\n", "note": "`Show` prints one line per pane: the window, the neighbourhood, the sum, and **which pane it is**, its timing and its index. A window and key that fire three times print three lines."}, {"code": "options = PipelineOptions([], runner='BundleBasedDirectRunner')\noptions.view_as(StandardOptions).streaming = True\nwith beam.Pipeline(options=options) as p:\n    (p\n     | arrivals(lag=60)\n     | beam.WindowInto(FixedWindows(5 * 60),\n                       trigger=trigger.AfterWatermark(early=early, late=late),\n                       allowed_lateness=args.lateness,\n                       accumulation_mode=mode)\n     | beam.CombinePerKey(sum)\n     | beam.ParDo(Show()))\n", "note": "**Streaming, because a TestStream is a stream** and the runner has to treat it as one, with a watermark and a clock. Then the pipeline proper: the replay with a lag of one minute, fixed windows of five minutes with the trigger and the lateness, and a sum per neighbourhood."}]}
```

## The default: on time, and nothing else

With no options, the window has the default trigger and no allowed lateness: it fires once, when the
watermark passes its end, and anything that arrives for it afterwards is dropped.

```
ana@laptop:~/gcp$ python3 late.py
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**Six panes, all `ON_TIME`, and three orders missing.** Compare with `by_time.py placed` in the
section on the two clocks: Moema's first window says 55.80 here and 86.80 there, missing the 31.00 of `o-507`.
Pinheiros's first window says 128.00 against 151.50, missing `o-504`, and its second says 72.00
against 80.00, missing `o-510`. **Nothing reported the loss.** No error, no warning, no line in the
output, and the pipeline ran to its end with a correct-looking table. A report built on it would
show Quitanda 62.50 reais short for these fifteen minutes, and nobody would know which orders.

Follow `o-504` through the replay to see why. It was placed at 19:04:20 and arrived at 19:08:40.
The order before it, `o-506`, arrived at 19:07:46 and moved the watermark to 19:06:46, past the end
of the 19:00 window at 19:05. **So the 19:00 window had already fired, with what it had, before
`o-504` existed for the pipeline**, and with no allowed lateness its state was gone. The same
happened to `o-507`, whose window had closed more than six minutes before it arrived, and to `o-510`,
placed at 19:09:10 and arriving at 19:14:00, after the watermark had passed 19:10.

```
ana@laptop:~/gcp$ python3 late.py
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**The same output again, line for line.** That is the TestStream's point: the arrival order, the
clock and the watermark are all in the program, so a run is a fact about the pipeline and not about
the laptop. A pipeline reading Pub/Sub on the DirectRunner gives no such guarantee, as the last
section shows.

## What the lag decides

The lag of one minute is this replay's choice, and it is the dial between two failures:

- **A watermark too close to the latest arrival** closes windows quickly and calls more data late.
  With a lag of zero, the watermark sits on the latest arrival, and an order placed at 19:04:59
  that spent two seconds in transit is late if another order arrives at 19:05:00 first.
- **A watermark too far behind** keeps every window open for longer, so results arrive later and
  the runner holds more state. With a lag of ten minutes, all ten orders of this evening would be
  on time, and the 19:00 window would be published at about 19:15.

No lag makes the problem disappear, because some phone somewhere will always be in a lift for
longer than any lag. The next section is how a pipeline keeps the window open for stragglers
without making everybody wait for them.
