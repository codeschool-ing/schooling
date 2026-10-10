---
title: When is a window complete?
version: 1
---

**A window over event time is complete when every event that belongs to it has arrived, and no
program reading a stream can ever know that it has.** Lesson 10 ended on this question. This
lesson answers it the way every stream engine does: not with certainty, but with a rule that is
explicit, measurable and adjustable.

Take the window from 09:05 to 09:10 of lesson 10. By 09:10, by the shops' clocks, the window's
time is over. By 09:12, sales from 09:12 have arrived, so most of the stream has moved on. And
sale 8, from 09:08:50, has not arrived yet; it comes after a sale from 09:13. In lesson 9 a window
of 10:30 to 10:35 was missing Natal's sales until 14:00. There is no moment at which the stream
says "that was everything for 09:05", because the stream does not know either: Natal's till did
not announce that it was holding sales.

## Three rules that do not work

**Wait for the clock on the wall.** Emit the 09:05 window at 09:12 by the processor's own clock,
two minutes after it ended. It is simple and it is processing time again, with every flaw lesson 9
listed: replay the topic tomorrow and every window closes "two minutes after it ended" at a
moment that has nothing to do with the events, so a replay gives different answers. And when the
processor itself stops for an hour, every window that ends in that hour closes the instant it
starts again, before the events that were waiting for it have been read.

**Wait for ever.** Never emit, keep every window open, correct each one whenever an event turns
up. Nothing is lost, and nothing is ever finished: every window ever opened stays in memory, and
nobody downstream can act on a number that might still change.

**Count events.** Emit when a window has the number it usually has. Five shops sell at roughly
known rates, so a window should hold about so many sales. Quiet days, busy days and a shop that
closes early all break it, and it says nothing about which events are missing.

## What does work

What the processor does know is the event times it has already seen. Every sale it has read
carries its `at`, and those times move forward: slowly, unevenly, out of order, but forward. If
the latest sale it has seen happened at 09:12:30, then the stream has got to roughly 09:12:30, and
a sale from before 09:10 would have to be more than two and a half minutes late to arrive now.
Lesson 9 measured how often that happens on Ponto Final's tills, and the answer was: often by
seconds, rarely by minutes, and once a day by hours.

**So the processor makes an assertion: "I do not expect any more events older than this time."**
That assertion is a watermark. It is computed from event times, so a replay of the same topic
makes the same assertions in the same places. It moves only forward, so a window that it has
passed stays passed. And it is a bet, which the late events of lesson 9 will sometimes lose. The
rest of this lesson is about making that bet well and deciding what to do when it is lost.
