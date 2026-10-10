---
title: When a window's result is final
version: 1
---

**`windows.py` saw all ten sales before it printed a line, and a stream processor never gets
that.** It has to decide when to tell somebody what a window holds, and every choice is either
early or wrong.

The `--updates` option makes the program behave like a processor that tells as it goes. It reads
the sales in the order they arrived and prints a window every time a sale changes it:

```
ubuntu@stream:~/work$ python windows.py tumbling 5 --updates
```

Read the 09:05 to 09:10 window down the column. After sale 5 it holds two sales and 12,390 cents.
Then sales 6 and 7 arrive, from 09:12 and 09:13, and by the clock of the events the 09:05 window
is two whole minutes in the past. A processor that closed windows as soon as a later event showed
up would have reported "two sales, 12,390" as final. **Then sale 8 arrives, and the window becomes
three sales and 21,380 cents.**

## Two ways to emit

**Emit on every update.** The output is a stream of corrections: each line replaces the last one
for that window. Nothing is ever lost, and every result is as fresh as it can be. The cost lands
on whoever reads the output: they must treat it as updates to a row keyed by window, not as new
rows, or the 09:05 window is counted three times. A table in a database, written with an upsert
as lesson 8 described, reads this kind of output correctly; a log of appends or an email does
not.

**Emit once, when the window is final.** The output is one line per window, and the reader can
treat it as an append. The cost lands on the processor: it has to know when a window is final,
and it waits until then, so results come late. Kafka Streams offers this with `suppress`, or with
an emit strategy of `onWindowClose`; Spark calls the two choices output modes, update and append,
which lesson 12 runs.

| | emit on every update | emit once, when final |
|---|---|---|
| freshness | as soon as an event lands | after the window is declared complete |
| output | corrections to a row per window | one row per window |
| a late event | another correction | dropped, or handled separately |
| the reader needs | upserts, keyed by window | nothing special |

## The question both leave open

Emit once needs a rule for "final", and so, sooner or later, does emit on every update: a
processor cannot keep every window open for ever, waiting for corrections, because each open
window is state. Both therefore need the same answer to the same question: **how does a processor
decide that no more events will arrive for a window?** It cannot know; it can only estimate, from
the event times it has seen, how far time has got, and accept that some events will arrive after
the estimate. That estimate is called a watermark, and lesson 11 builds one and runs the ten sales
of this lesson, and the late ones of lesson 9, through it.
